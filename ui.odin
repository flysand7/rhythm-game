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

draw_timeline :: proc(beatmap: Beatmap, game_duration_ticks: int) {
    white_ticks_on_screen := 1280 / (TIMELINE_ZOOM * NOTE) + 2
    timeline_offset := game_duration_ticks % NOTE
    for i in 0 ..< white_ticks_on_screen {
        rl.DrawLine(
            TIMELINE_ZOOM*i32(beatmap.offset%NOTE + i * NOTE - timeline_offset),
            TIMELINE_Y - TIMELINE_WHITE_TICK_SIZE,
            TIMELINE_ZOOM*i32(beatmap.offset%NOTE + i * NOTE - timeline_offset),
            TIMELINE_Y + TIMELINE_WHITE_TICK_SIZE,
            rl.GetColor(0xffffffff)
        )
        rl.DrawLine(
            TIMELINE_ZOOM*i32(beatmap.offset%NOTE + i * NOTE + HALF_NOTE - timeline_offset),
            TIMELINE_Y - TIMELINE_RED_TICK_SIZE,
            TIMELINE_ZOOM*i32(beatmap.offset%NOTE + i * NOTE + HALF_NOTE - timeline_offset),
            TIMELINE_Y + TIMELINE_RED_TICK_SIZE,
            rl.GetColor(0xff3333ff)
        )
        rl.DrawLine(
            TIMELINE_ZOOM*i32(beatmap.offset%NOTE + i * NOTE + QUARTER_NOTE - timeline_offset),
            TIMELINE_Y - TIMELINE_BLUE_TICK_SIZE,
            TIMELINE_ZOOM*i32(beatmap.offset%NOTE + i * NOTE + QUARTER_NOTE - timeline_offset),
            TIMELINE_Y + TIMELINE_BLUE_TICK_SIZE,
            rl.GetColor(0x33ffffff)
        )
        rl.DrawLine(
            TIMELINE_ZOOM*i32(beatmap.offset%NOTE + i * NOTE + HALF_NOTE + QUARTER_NOTE - timeline_offset),
            TIMELINE_Y - TIMELINE_BLUE_TICK_SIZE,
            TIMELINE_ZOOM*i32(beatmap.offset%NOTE + i * NOTE + HALF_NOTE + QUARTER_NOTE - timeline_offset),
            TIMELINE_Y + TIMELINE_BLUE_TICK_SIZE,
            rl.GetColor(0x33ffffff)
        )
    }
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

ticks_to_timeline_x :: proc(beatmap: Beatmap, ticks: int, game_duration_ticks: int) -> int {
    return TIMELINE_ZOOM*(2*NOTE + beatmap.offset + ticks - game_duration_ticks)
}

