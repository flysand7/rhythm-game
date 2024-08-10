package game

import "core:mem"
import "core:slice"
import "core:time"
import "core:fmt"
import rl "vendor:raylib"

main :: proc() {
    rl.InitWindow(1280, 720, "Rhythm Game")
    rl.InitAudioDevice()
    rl.SetTargetFPS(144)
    play_state := Play_State {
        start_time = time.now(),
        next_hit_object_idx = 0,
        bm = Beatmap {
            objects = []Hit_Object {
                {0*NOTE,               .Rim, 0xffffffff},
                {1*NOTE,               .Rim, 0xffffffff},
                {2*NOTE,               .Rim, 0xffffffff},
                {3*NOTE,               .Rim, 0xffffffff},

                {4*NOTE,               .Clap, 0xffffffff},
                {5*NOTE,               .Clap, 0xffffffff},
                {6*NOTE,               .Clap, 0xffffffff},
                {7*NOTE,               .Clap, 0xffffffff},

                {8*NOTE,               .Rim, 0xffffffff},
                {9*NOTE,               .Rim, 0xffffffff},
                {9*NOTE+HALF_NOTE,     .Rim, 0xffffffff},
                {10*NOTE,              .Rim, 0xffffffff},
                {11*NOTE,              .Rim, 0xffffffff},

                {12*NOTE,              .Clap, 0xffffffff},
                {13*NOTE,              .Clap, 0xffffffff},
                {13*NOTE+HALF_NOTE,    .Clap, 0xffffffff},
                {14*NOTE,              .Clap, 0xffffffff},
                {15*NOTE,              .Clap, 0xffffffff},

                {16*NOTE,              .Rim, 0xffffffff},
                {16*NOTE+HALF_NOTE,    .Rim, 0xffffffff},
                {17*NOTE,              .Rim, 0xffffffff},
                {18*NOTE,              .Rim, 0xffffffff},
                {18*NOTE+HALF_NOTE,    .Rim, 0xffffffff},
                {19*NOTE,              .Rim, 0xffffffff},
                                                
                {20*NOTE,              .Clap, 0xffffffff},
                {20*NOTE+HALF_NOTE,    .Clap, 0xffffffff},
                {21*NOTE,              .Clap, 0xffffffff},
                {22*NOTE,              .Clap, 0xffffffff},
                {22*NOTE+HALF_NOTE,    .Clap, 0xffffffff},
                {23*NOTE,              .Clap, 0xffffffff},

                {24*NOTE,              .Rim, 0xffffffff},
                {24*NOTE+QUARTER_NOTE, .Rim, 0xffffffff},
                {25*NOTE-QUARTER_NOTE, .Rim, 0xffffffff},
                {25*NOTE,              .Rim, 0xffffffff},
                {25*NOTE+HALF_NOTE,    .Rim, 0xffffffff},
                {26*NOTE,              .Rim, 0xffffffff},
                {26*NOTE+QUARTER_NOTE, .Rim, 0xffffffff},
                {27*NOTE-QUARTER_NOTE, .Rim, 0xffffffff},
                {27*NOTE,              .Rim, 0xffffffff},
                {27*NOTE+HALF_NOTE,    .Rim, 0xffffffff},

                {28*NOTE,              .Clap, 0xffffffff},
                {28*NOTE+QUARTER_NOTE, .Clap, 0xffffffff},
                {29*NOTE-QUARTER_NOTE, .Clap, 0xffffffff},
                {29*NOTE,              .Clap, 0xffffffff},
                {29*NOTE+HALF_NOTE,    .Clap, 0xffffffff},
                {30*NOTE,              .Clap, 0xffffffff},
                {30*NOTE+QUARTER_NOTE, .Clap, 0xffffffff},
                {31*NOTE-QUARTER_NOTE, .Clap, 0xffffffff},
                {31*NOTE,              .Clap, 0xffffffff},
                {31*NOTE+HALF_NOTE,    .Clap, 0xffffffff},
            },
            offset = 30 + 5*NOTE,
            bpm = 120,
            al = 5,
        },
        hit_texts = make([dynamic]Hit_Text, allocator = context.allocator),
        hits = {},
    }
    music := rl.LoadMusicStream("./music/rhythm-hell.mp3")
    rl.SetMusicVolume(music, 1.0)
    rl.PlayMusicStream(music)
    hs_kick := rl.LoadSound("./sounds/kick.wav")
    hs_clap := rl.LoadSound("./sounds/clap.wav")
    hs_hhc := rl.LoadSound("./sounds/hi-hat-closed.wav")
    hs_hho := rl.LoadSound("./sounds/hi-hat-open.wav")
    hs_rim := rl.LoadSound("./sounds/rim.wav")
    hs_snare := rl.LoadSound("./sounds/snare.wav")
    hs_symbal := rl.LoadSound("./sounds/symbal.wav")
    hitsounds := [Hit_Sound]rl.Sound {
        .Clap = hs_clap,
        .Hi_Hat_Open = hs_hhc,
        .Hi_Hat_Closed = hs_hho,
        .Kick = hs_kick,
        .Rim = hs_rim,
        .Snare = hs_snare,
        .Symbal = hs_symbal,
    }
    for !rl.WindowShouldClose() {
        mem.free_all(context.temp_allocator)
        rl.UpdateMusicStream(music)
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.DrawFPS(10, 10)
        frame_start_time := time.now()
        if rl.IsKeyPressed(.R) {
            ps_reset(&play_state)
            rl.SeekMusicStream(music, 0.0)
        }
        game_duration := time.diff(play_state.start_time, frame_start_time)
        game_duration_in_ticks := dur_to_ticks(play_state.bm.bpm, game_duration)
        rl.DrawLine(0, TIMELINE_Y, 1280, TIMELINE_Y, rl.GetColor(0x777777ff))
        draw_timeline(play_state.bm, game_duration_in_ticks)
        for hit_object, idx in play_state.bm.objects {
            circle_color := rl.GetColor(hit_object.color)
            if idx < play_state.next_hit_object_idx {
                circle_color = rl.RED
            }
            rl.DrawCircle(
                cast(i32) ticks_to_timeline_x(play_state.bm, hit_object.tick, game_duration_in_ticks),
                TIMELINE_Y,
                10,
                circle_color,
            )
        }
        rl.DrawCircle(cast(i32) ticks_to_timeline_x(play_state.bm, -play_state.bm.offset, 0), TIMELINE_Y + 25, 5, rl.YELLOW)
        if rl.IsKeyPressed(.S) || rl.IsKeyPressed(.X) {
            ho, is_hit := check_player_hit(&play_state, game_duration)
            if is_hit {
                rl.PlaySound(hitsounds[ho.hit_sound])
            }
        }
        check_expired_hits(&play_state, game_duration)
        #reverse for &ht, i in play_state.hit_texts {
            if game_duration - ht.time > 500*time.Millisecond {
                ordered_remove(&play_state.hit_texts, i)
                continue
            }
            draw_hit_accuracy(&ht)
        }
        rl.DrawText(fmt.caprintf("Acc: %.2f%%", 100.0*current_acc(&play_state), allocator = context.temp_allocator), 20, 200, 20, rl.WHITE)
        rl.EndDrawing()
    }
    rl.CloseWindow()
}
