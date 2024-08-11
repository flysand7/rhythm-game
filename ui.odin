package game

import "core:time"
import rl "vendor:raylib"

TIMELINE_Y :: 50
TIMELINE_CUR_X :: 100
TIMELINE_ZOOM :: 5

TIMELINE_WHITE_TICK_SIZE :: 20
TIMELINE_RED_TICK_SIZE :: 15
TIMELINE_BLUE_TICK_SIZE :: 10

HIT_ACCURACY_TEXT_SIZE :: 20

import "core:fmt"

draw_timeline :: proc(beatmap: ^Beatmap, game_duration_ticks: int) {
    white_ticks_on_screen := 1280 / (TIMELINE_ZOOM * NOTE) + 2
    offset_ticks := game_duration_ticks % NOTE
    offset_white_ticks := game_duration_ticks / NOTE
    for wt_offs in 0 ..< white_ticks_on_screen {
        wt_tick := NOTE*(offset_white_ticks + wt_offs - 2)
        timing := bm_get_timing(beatmap, wt_tick)
        screen_off_x := timing.offset % NOTE + wt_offs*NOTE
        rl.DrawLine(
            TIMELINE_ZOOM*i32(screen_off_x - offset_ticks),
            TIMELINE_Y - TIMELINE_WHITE_TICK_SIZE,
            TIMELINE_ZOOM*i32(screen_off_x - offset_ticks),
            TIMELINE_Y + TIMELINE_WHITE_TICK_SIZE,
            rl.GetColor(0xffffffff)
        )
        if timing.signature == .Four_Quarters {
            rl.DrawLine(
                TIMELINE_ZOOM*i32(screen_off_x + HALF_NOTE - offset_ticks),
                TIMELINE_Y - TIMELINE_RED_TICK_SIZE,
                TIMELINE_ZOOM*i32(screen_off_x + HALF_NOTE - offset_ticks),
                TIMELINE_Y + TIMELINE_RED_TICK_SIZE,
                rl.GetColor(0xff3333ff)
            )
            rl.DrawLine(
                TIMELINE_ZOOM*i32(screen_off_x + QUARTER_NOTE - offset_ticks),
                TIMELINE_Y - TIMELINE_BLUE_TICK_SIZE,
                TIMELINE_ZOOM*i32(screen_off_x + QUARTER_NOTE - offset_ticks),
                TIMELINE_Y + TIMELINE_BLUE_TICK_SIZE,
                rl.GetColor(0x33ffffff)
            )
            rl.DrawLine(
                TIMELINE_ZOOM*i32(screen_off_x + HALF_NOTE + QUARTER_NOTE - offset_ticks),
                TIMELINE_Y - TIMELINE_BLUE_TICK_SIZE,
                TIMELINE_ZOOM*i32(screen_off_x + HALF_NOTE + QUARTER_NOTE - offset_ticks),
                TIMELINE_Y + TIMELINE_BLUE_TICK_SIZE,
                rl.GetColor(0x33ffffff)
            )
        } else if timing.signature == .Three_Quarters {
            rl.DrawLine(
                TIMELINE_ZOOM*i32(screen_off_x + THIRD_NOTE - offset_ticks),
                TIMELINE_Y - TIMELINE_RED_TICK_SIZE,
                TIMELINE_ZOOM*i32(screen_off_x + THIRD_NOTE - offset_ticks),
                TIMELINE_Y + TIMELINE_RED_TICK_SIZE,
                rl.GetColor(0xfcca03ff)
            )
            rl.DrawLine(
                TIMELINE_ZOOM*i32(screen_off_x + 2*THIRD_NOTE - offset_ticks),
                TIMELINE_Y - TIMELINE_RED_TICK_SIZE,
                TIMELINE_ZOOM*i32(screen_off_x + 2*THIRD_NOTE - offset_ticks),
                TIMELINE_Y + TIMELINE_RED_TICK_SIZE,
                rl.GetColor(0xfcca03ff)
            )
        } else {
            panic("Timing signature not handled in draw timeline code")
        }
    }
}

ticks_to_timeline_x :: proc(beatmap: ^Beatmap, ticks: int, game_duration_ticks: int) -> int {
    return TIMELINE_ZOOM*(2*NOTE + beatmap.timings[0].offset + ticks - game_duration_ticks)
}

timeline_x_zero :: proc() -> int {
    return TIMELINE_ZOOM*(2*NOTE)
}

Hit_Text :: struct {
    time: time.Duration,
    acc: Hit_Accuracy,
    y_offs: int,
}

draw_hit_accuracy :: proc(ht: ^Hit_Text) {
    texts := [Hit_Accuracy]cstring {
        .Miss = "MISS",
        .Bad = "BAD",
        .Good = "GOOD",
        .Perfect = "PERFECT",
    }
    colors := [Hit_Accuracy]rl.Color {
        .Miss = rl.RED,
        .Bad = rl.BLUE,
        .Good = rl.GREEN,
        .Perfect = rl.GetColor(0x03d3fcff),
    }
    width := rl.MeasureText(texts[ht.acc], HIT_ACCURACY_TEXT_SIZE)
    rl.DrawText(
        texts[ht.acc],
        1280/2 - width/2,
        5*720/6 - i32(ht.y_offs),
        HIT_ACCURACY_TEXT_SIZE,
        colors[ht.acc],
    )
    ht.y_offs += 5
}

draw_hit_distribution :: proc(play_state: Play_State) {
    OFF_X :: 30
    OFF_Y :: 300
    MAX_Y :: 400
    GRAPH_W :: 300
    UI_SCALE :: f32(GRAPH_W) / f32(2*WORST_HIT_MS)
    center_x := i32(OFF_X+GRAPH_W/2)
    // Draw the graph
    GROUP_BY_MS :: 5
    group_by_px := f32(GROUP_BY_MS) * UI_SCALE
    buckets := make([]int, 2*WORST_HIT_MS/GROUP_BY_MS, context.temp_allocator)
    max_hits := 1
    for hit in play_state.hits {
        if abs(hit.diff_ms) >= WORST_HIT_MS {
            continue;
        }
        bucket := (WORST_HIT_MS - hit.diff_ms) / GROUP_BY_MS
        buckets[bucket] += 1
        if buckets[bucket] > max_hits {
            max_hits = buckets[bucket]
        }
    }
    for b, i in buckets {
        bucket_off_x := OFF_X + i32(f32(i*GROUP_BY_MS)*UI_SCALE)
        bucket_height_y := i32(100*b / max_hits)
        rl.DrawRectangle(bucket_off_x, OFF_Y - bucket_height_y, i32(group_by_px), bucket_height_y, rl.WHITE)
    }
    // Draw the ticks
    rl.DrawLine(OFF_X, OFF_Y, OFF_X + GRAPH_W, OFF_Y, rl.WHITE)
    rl.DrawLine(center_x, OFF_Y-10, center_x, OFF_Y+10, rl.WHITE)
    tick_offs_perfect := cast(i32) (f32(1*(10 + 5*play_state.bm.al)) * UI_SCALE)
    rl.DrawLine(center_x - tick_offs_perfect, OFF_Y-5, center_x - tick_offs_perfect, OFF_Y+5, rl.GetColor(0x03d3fcff))
    rl.DrawLine(center_x + tick_offs_perfect, OFF_Y-5, center_x + tick_offs_perfect, OFF_Y+5, rl.GetColor(0x03d3fcff))
    tick_offs_good := cast(i32) (f32(2*(10 + 5*play_state.bm.al)) * UI_SCALE)
    rl.DrawLine(center_x - tick_offs_good, OFF_Y-5, center_x - tick_offs_good, OFF_Y+5, rl.GREEN)
    rl.DrawLine(center_x + tick_offs_good, OFF_Y-5, center_x + tick_offs_good, OFF_Y+5, rl.GREEN)
}
