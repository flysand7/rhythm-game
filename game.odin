package game

import "core:time"

WORST_HIT_MS :: 200

Hit_Sound :: enum {
    Clap,
    Hi_Hat_Open,
    Hi_Hat_Closed,
    Kick,
    Rim,
    Snare,
    Symbal,
}

// A clickable object, i.e. a visible note in the song.
Hit_Object :: struct {
    tick: int,
    hit_sound: Hit_Sound,
    color: u32,
}

Time_Signature :: enum {
    Three_Quarters,
    Four_Quarters,
}

Timing :: struct {
    offset: int,
    signature: Time_Signature,
}

// The representation of the song in the game.
Beatmap :: struct {
    objects: []Hit_Object,
    timings: []Timing,
    offset: time.Duration,
    bpm: int,
    al: int,
}

// How well a player has hit a hit object.
Hit_Accuracy :: enum {
    Miss,
    Bad,
    Good,
    Perfect,
}

Player_Hit :: struct {
    acc: Hit_Accuracy,
    diff_ms: int,
}

// All of the state related to the current play of a beatmap
Play_State :: struct {
    bm: Beatmap,
    start_time: time.Time,
    next_hit_object_idx: int,
    hits: [dynamic]Player_Hit,
    hit_texts: [dynamic]Hit_Text,
    key1_hit_times: int,
    key2_hit_times: int,
}

ps_reset :: proc(ps: ^Play_State) {
    ps.start_time = time.now()
    ps.next_hit_object_idx = 0
    ps.hits = {}
    ps.key1_hit_times = 0
    ps.key2_hit_times = 0
    clear(&ps.hit_texts)
}

bm_get_timing :: proc(bm: ^Beatmap, tick: int) -> Timing {
    if tick < bm.timings[0].offset {
        return bm.timings[0]
    }
    for first,i in bm.timings[:len(bm.timings)-1] {
        next := bm.timings[i+1]
        if first.offset <= tick && tick < next.offset {
            return first
        }
    }
    return bm.timings[len(bm.timings)-1]
}

submit_hit :: proc(play_state: ^Play_State, acc: Hit_Accuracy, dur: time.Duration, diff_ms: int) {
    append(&play_state.hit_texts, Hit_Text {
        acc = acc,
        y_offs = 0,
        time = dur,
    })
    append(&play_state.hits, Player_Hit {
        acc = acc,
        diff_ms = diff_ms,
    })
}

hit_window_for_acc :: proc(acc: Hit_Accuracy, al: int) -> time.Duration {
    switch acc {
    case .Miss:    return time.Millisecond * time.Duration(WORST_HIT_MS)
    case .Bad:     return time.Millisecond * time.Duration(4*(10 + 5*al))
    case .Good:    return time.Millisecond * time.Duration(2*(10 + 5*al))
    case .Perfect: return time.Millisecond * time.Duration(10 + 5*al)
    }
    unreachable()
}

check_player_hit :: proc(play_state: ^Play_State, t: time.Duration) -> (Hit_Object, bool) {
    bm := &play_state.bm
    // TODO: Optimize to use binary searching
    min_i := -1
    min_diff_t := max(time.Duration)
    diff_t := max(time.Duration)
    for i in play_state.next_hit_object_idx ..< len(bm.objects) {
        hit_object_t := bm_ticks_to_dur(&play_state.bm, bm.objects[i].tick)
        cur_diff_t := hit_object_t - t
        if abs(cur_diff_t) < min_diff_t {
            min_i = i
            min_diff_t = abs(cur_diff_t)
            diff_t = cur_diff_t
        }
    }
    if min_i < 0 {
        return {}, false
    }
    h := bm.objects[min_i]
    acc_leniency := play_state.bm.al
    acc: Hit_Accuracy
    switch {
    case min_diff_t <= hit_window_for_acc(.Perfect, bm.al): acc = .Perfect
    case min_diff_t <= hit_window_for_acc(.Good, bm.al):    acc = .Good
    case min_diff_t <= hit_window_for_acc(.Bad, bm.al):     acc = .Bad
    case min_diff_t <= hit_window_for_acc(.Miss, bm.al):    acc = .Miss
    case: return {}, false
    }
    play_state.next_hit_object_idx = min_i+1
    submit_hit(play_state, acc, t, int(diff_t / time.Millisecond))
    return bm.objects[min_i], true
}

check_expired_hits :: proc(play_state: ^Play_State, t: time.Duration) {
    for idx in play_state.next_hit_object_idx ..< len(play_state.bm.objects[:]) {
        hit_object_dur := bm_ticks_to_dur(&play_state.bm, play_state.bm.objects[idx].tick)
        if t - hit_object_dur > WORST_HIT_MS*time.Millisecond {
            play_state.next_hit_object_idx = idx + 1
            submit_hit(play_state, .Miss, t, int((t - hit_object_dur) / time.Millisecond))
        } else {
            break
        }
    }
}

current_acc :: proc(play_state: ^Play_State) -> f32 {
    if play_state.next_hit_object_idx == 0 {
        return 1.0
    }
    scalings := [Hit_Accuracy]f32 {
        .Miss    = 0.0,
        .Bad     = 0.1,
        .Good    = 0.5,
        .Perfect = 1.0,
    }
    total_sum := f32(0.0)
    for hit in play_state.hits {
        total_sum += 1.0 * scalings[hit.acc]
    }
    return total_sum / f32(play_state.next_hit_object_idx)
}
