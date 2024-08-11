package game

import "core:time"

NOTE :: 48
HALF_NOTE    :: NOTE/2
QUARTER_NOTE :: NOTE/4
EIGTH_NOTE   :: NOTE/8
THIRD_NOTE   :: NOTE/3
SIXTHS_NOTE  :: NOTE/6

/*
Ticks in a beat (note).
*/
tpb :: proc() -> int {
    return NOTE
}

/*
Ticks per minute with a given bpm.
*/
tpm :: proc(bpm: int) -> int {
    return bpm * tpb()
}

/*
Convert duration, lying within a timing segment of `bpm` as a whole into
ticks. 
*/
dur_to_ticks :: proc(bpm: int, dur: time.Duration) -> int {
    return tpm(bpm) * int(dur) / int(time.Minute)
}

/*
Convert ticks lying within a timing segment with bpm `bpm` as a whole, into
duration.
*/
ticks_to_dur :: proc(bpm: int, ticks: int) -> time.Duration {
    return time.Duration(int(time.Minute) * ticks / tpm(bpm))
}

/*
Convert the game duration into beatmap ticks.
*/
bm_dur_to_ticks :: proc(bm: ^Beatmap, duration: time.Duration) -> int {
    duration := duration - bm.offset
    bpm := bm.bpm
    return int(duration) * tpm(bpm) / int(time.Minute)
}

/*
Convert beatmap ticks into game duration.
*/
bm_ticks_to_dur :: proc(bm: ^Beatmap, ticks: int) -> time.Duration {
    return bm.offset + time.Duration((int(time.Minute) * ticks) / tpm(bm.bpm))
}
