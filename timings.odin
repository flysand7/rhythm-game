package game

import "core:time"

// A tick is 1/48'th of a note. The idea is that we want potentially all
// beatmap notes to be snapped to some nice integer "values", and for most
// songs all we care about is 3/4 and 4/4 rhythms. Using a tick it's possible
// to represent a quarter note or a 1/6 note using an integer.
NOTE :: 48
HALF_NOTE    :: NOTE/2
QUARTER_NOTE :: NOTE/4
EIGTH_NOTE   :: NOTE/8
THIRD_NOTE   :: NOTE/3
SIXTHS_NOTE  :: NOTE/6

bpm_to_tps :: proc(bpm: int) -> int {
    return bpm * NOTE / 60
}

seconds_to_ticks :: proc(bpm: int, secs: int) -> int {
    return secs * bpm_to_tps(bpm)
}

dur_to_ticks :: proc(bpm: int, duration: time.Duration) -> int {
    return int(duration) * bpm_to_tps(bpm) / int(time.Second)
}

bm_ticks_to_dur :: proc(bm: ^Beatmap, ticks: int) -> time.Duration {
    ticks := ticks + bm.offset
    return (time.Second * time.Duration(ticks)) / time.Duration(bpm_to_tps(bm.bpm))
}

bm_ticks_to_ms :: proc(bm: ^Beatmap, ticks: int) -> int {
    ticks := ticks + bm.offset
    return 1000 * ticks / bpm_to_tps(bm.bpm)
}
