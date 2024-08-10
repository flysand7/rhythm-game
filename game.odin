package game

import "core:time"

// A clickable object, i.e. a visible note in the song.
Hit_Object :: struct {
    tick: int,
    color: u32,
}

// The representation of the song in the game.
Beatmap :: struct {
    objects: []Hit_Object,
    offset: int,
    bpm: int,
}

// How well a player has hit a hit object.
Hit_Accuracy :: enum {
    Miss,
    Bad,
    Good,
    Perfect,
}

// All of the state related to the current play of a beatmap
Play_State :: struct {
    bm: Beatmap,
    start_time: time.Time,
    next_hit_object_idx: int,
    hits: [Hit_Accuracy]int,
    hit_texts: [dynamic]Hit_Text,
}

ps_reset :: proc(ps: ^Play_State) {
    ps.start_time = time.now()
    ps.next_hit_object_idx = 0
    ps.hits = {}
    clear(&ps.hit_texts)
}

submit_hit :: proc(play_state: ^Play_State, acc: Hit_Accuracy, dur: time.Duration) {
    append(&play_state.hit_texts, Hit_Text {
        acc = acc,
        y_offs = 0,
        time = dur,
    })
    play_state.hits[acc] += 1
}

check_player_hit :: proc(play_state: ^Play_State, t: time.Duration) {
    beatmap := &play_state.bm
    // TODO: Optimize to use binary searching
    min_i := -1
    min_diff_ms := max(int)
    for i in play_state.next_hit_object_idx ..< len(beatmap.objects) {
        hit_object_ms := bm_ticks_to_ms(beatmap, beatmap.objects[i].tick)
        abs_diff_ms := abs(hit_object_ms - int(t / time.Millisecond))
        if abs_diff_ms < min_diff_ms {
            min_i = i
            min_diff_ms = abs_diff_ms
        }
    }
    if min_i < 0 {
        return
    }
    h := beatmap.objects[min_i]
    // On average the timing distribution is a normal (or a binormal, depending
    // on player's set up) distribution, centered around a certain point. With
    // 15ms being a good measure of a "perfect" hit, we can spread out the rest
    // of the hits accordingly.
    // TODO: Implement hit accuracy leniency.
    acc: Hit_Accuracy
    switch {
        case min_diff_ms <= 30:  acc = .Perfect
        case min_diff_ms <= 100: acc = .Good
        case min_diff_ms <= 250: acc = .Bad  // Player has reacted, didn't feel the rhythm
        case min_diff_ms <= 500: acc = .Miss // Too far away
        case: return
    }
    play_state.next_hit_object_idx = min_i+1
    submit_hit(play_state, acc, t)
}

check_expired_hits :: proc(play_state: ^Play_State, t: time.Duration) {
    for idx in play_state.next_hit_object_idx ..< len(play_state.bm.objects[:]) {
    hit_object_dur := bm_ticks_to_dur(&play_state.bm, play_state.bm.objects[idx].tick)
    if t - hit_object_dur > 200*time.Millisecond {
        play_state.next_hit_object_idx = idx + 1
        submit_hit(play_state, .Miss, t)
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
        .Miss = 0.0,
        .Bad = 0.1,
        .Good = 0.5,
        .Perfect = 1.0,
    }
    total_sum := f32(0.0)
    for ha, acc in play_state.hits {
        total_sum += f32(ha) * scalings[acc]
    }
    return total_sum / f32(play_state.next_hit_object_idx)
}
