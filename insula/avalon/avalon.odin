package avalon

import glm "core:math/linalg/glsl"
import     "core:time"
import     "core:fmt"

MAX_KEYBOARD_KEYS      :: 512
MAX_KEY_PRESSED_QUEUE  :: 16
MAX_CHAR_PRESSED_QUEUE :: 16
MAX_MOUSE_BUTTONS      :: 8

Update_Proc :: #type proc(ctx: ^Context, dt: f32)
Init_Proc   :: #type proc(ctx: ^Context) -> bool
Fini_Proc   :: #type proc(ctx: ^Context)

Context :: struct {
        //init: Init_Proc,
    update: Update_Proc,
    fini:   Fini_Proc,
    using platform_data: Platform_Data,
    io: IO,
    user_data: rawptr,

    prev_time: f64,
    curr_time: f64,

    //input: struct {
    //    keyboard: struct {
    //        current_key_state: [MAX_KEYBOARD_KEYS]bool,
    //        previous_key_state: [MAX_KEYBOARD_KEYS]bool,

    //        key_pressed_queue: [MAX_KEY_PRESSED_QUEUE]i32,
    //        key_pressed_queue_count: int,

    //        char_pressed_queue: [MAX_CHAR_PRESSED_QUEUE]rune,
    //        char_pressed_queue_count: int,
    //    },
    //    mouse: struct {
    //        offset: glm.vec2,
    //        scale: glm.vec2,
    //        current_position: glm.vec2,
    //        previous_position: glm.vec2,

    //        cursor_hidden: bool,
    //        cursor_on_screen: bool,

    //        current_button_state: [MAX_MOUSE_BUTTONS]i32,
    //        previous_button_state: [MAX_MOUSE_BUTTONS]i32,
    //        current_wheel_move: glm.vec2,
    //        previous_wheel_move: glm.vec2,
    //    }
    //}
}

@private g_ctx: Context

init :: proc(width, height: i32, title: cstring = " ", init: Init_Proc, update: Update_Proc, fini: Fini_Proc) -> bool {
    //g_ctx.init = init
    g_ctx.update = update
    g_ctx.fini = fini
    platform_init(width, height, title)
    if !init(&g_ctx) {
        platform_fini()
        return false
    }
    return true
}

start :: proc() {
    //g_ctx.init(&g_ctx)
    tick := time.tick_now()
    when ODIN_OS != .JS {
        for !window_should_close() {
            dt := time.duration_seconds(time.tick_lap_time(&tick))
            if !step(dt) do break
        }
        g_ctx.fini(&g_ctx)
        platform_fini()
    }
}

@export
step :: proc(delta_time: f64) -> bool {
    curr_time := g_ctx.curr_time + delta_time
    dt := curr_time - g_ctx.curr_time
    g_ctx.prev_time = g_ctx.curr_time
    g_ctx.curr_time = curr_time

    platform_update()

    io_init()

    g_ctx.update(&g_ctx, f32(dt))

    io_fini()
    return true
}
