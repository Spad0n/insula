#+build linux, windows, darwin
package avalon

import     "vendor:sdl3"
import     "core:fmt"
import glm "core:math/linalg/glsl"
import     "core:os"
import     "base:runtime"

HIGH_DPI :: #config(HIGH_DPI, false)
GL_MAJOR_VERSION, GL_MINOR_VERSION :: 3, 3

gl_set_proc_address :: sdl3.gl_set_proc_address

Platform_Data :: struct {
    handle: ^sdl3.Window,
    title: cstring,
    screen_width: i32,
    screen_height: i32,
    ready: bool,
    resized_last_frame: bool,
    should_close: bool,
    event_waiting: bool,

    glctx: sdl3.GLContext,

    // TODO: implement char event
    //char_pressed_queue: [MAX_CHAR_PRESSED_QUEUE]rune,
    //char_pressed_queue_count: int,
}

platform_init :: proc(width, height: i32, title: cstring, location := #caller_location) {
    g_ctx.platform_data.title = title
    g_ctx.platform_data.screen_width  = width
    g_ctx.platform_data.screen_height = height

    if !sdl3.Init({.VIDEO}) {
        fmt.eprintln(location, sdl3.GetError())
        os.exit(1)
    }

    window := sdl3.CreateWindow(title, width, height, {.OPENGL})
    if window == nil {
        fmt.eprintln(location, sdl3.GetError())
        os.exit(1)
    }

    sdl3.SetWindowResizable(window, false)
    sdl3.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_MAJOR_VERSION)
    sdl3.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_MINOR_VERSION)

    g_ctx.platform_data.glctx = sdl3.GL_CreateContext(window)
    if g_ctx.platform_data.glctx == nil {
        fmt.eprintln(location, sdl3.GetError())
        os.exit(1)
    }

    sdl3.GL_MakeCurrent(window, g_ctx.platform_data.glctx)
    sdl3.GL_SetSwapInterval(1)

    g_ctx.platform_data.handle = window
    g_ctx.platform_data.ready = true
}

window_should_close :: proc() -> bool {
    if g_ctx.platform_data.ready {
        return g_ctx.platform_data.should_close
    }
    return true
}

@(private)
platform_update :: proc() {
    event: sdl3.Event
    for sdl3.PollEvent(&event) {
        #partial switch event.type {
        case .QUIT:
            g_ctx.platform_data.should_close = true
        case .KEY_UP: fallthrough
        case .KEY_DOWN:
            key_callback(event.key)
        case .MOUSE_BUTTON_UP: fallthrough
        case .MOUSE_BUTTON_DOWN:
            mouse_button_callback(event.button)
        case .MOUSE_MOTION:
            mouse_cursor_pos_callback(event.motion)
        case .MOUSE_WHEEL:
            mouse_scroll_callback(event.wheel)
        case .TEXT_INPUT:
            char_callback(event.text)
        }
    }
    sdl3.GL_SwapWindow(g_ctx.platform_data.handle)
}

@(private)
platform_fini :: proc() {
    sdl3.GL_DestroyContext(g_ctx.platform_data.glctx)
    sdl3.DestroyWindow(g_ctx.platform_data.handle)
    sdl3.Quit()
}

@(private)
code_to_key :: proc (code: sdl3.Keycode) -> Key {
    switch code {
    case sdl3.K_A: return .A
    case sdl3.K_B: return .B
    case sdl3.K_C: return .C
    case sdl3.K_D: return .D
    case sdl3.K_E: return .E
    case sdl3.K_F: return .F
    case sdl3.K_G: return .G
    case sdl3.K_H: return .H
    case sdl3.K_I: return .I
    case sdl3.K_J: return .J
    case sdl3.K_K: return .K
    case sdl3.K_L: return .L
    case sdl3.K_M: return .M
    case sdl3.K_N: return .N
    case sdl3.K_O: return .O
    case sdl3.K_P: return .P
    case sdl3.K_Q: return .Q
    case sdl3.K_R: return .R
    case sdl3.K_S: return .S
    case sdl3.K_T: return .T
    case sdl3.K_U: return .U
    case sdl3.K_V: return .V
    case sdl3.K_W: return .W
    case sdl3.K_X: return .X
    case sdl3.K_Y: return .Y
    case sdl3.K_Z: return .Z

    case sdl3.K_1: return .Key_1
    case sdl3.K_2: return .Key_2
    case sdl3.K_3: return .Key_3
    case sdl3.K_4: return .Key_4
    case sdl3.K_5: return .Key_5
    case sdl3.K_6: return .Key_6
    case sdl3.K_7: return .Key_7
    case sdl3.K_8: return .Key_8
    case sdl3.K_9: return .Key_9
    case sdl3.K_0: return .Key_0

    case sdl3.K_KP_1: return .Numpad_1
    case sdl3.K_KP_2: return .Numpad_2
    case sdl3.K_KP_3: return .Numpad_3
    case sdl3.K_KP_4: return .Numpad_4
    case sdl3.K_KP_5: return .Numpad_5
    case sdl3.K_KP_6: return .Numpad_6
    case sdl3.K_KP_7: return .Numpad_7
    case sdl3.K_KP_8: return .Numpad_8
    case sdl3.K_KP_9: return .Numpad_9
    case sdl3.K_KP_0: return .Numpad_0

    case sdl3.K_KP_DECIMAL  : return .Numpad_Decimal
    case sdl3.K_KP_DIVIDE   : return .Numpad_Divide
    case sdl3.K_KP_MULTIPLY : return .Numpad_Multiply
    case sdl3.K_KP_MINUS    : return .Numpad_Subtract
    case sdl3.K_KP_PLUS     : return .Numpad_Add
    case sdl3.K_KP_ENTER    : return .Numpad_Enter
    //case sdl3.K_KP_EQUAL    : return .Numpad_Equal

    case sdl3.K_ESCAPE    : return .Escape
    case sdl3.K_RETURN    : return .Return
    case sdl3.K_TAB       : return .Tab
    case sdl3.K_BACKSPACE : return .Backspace
    case sdl3.K_SPACE     : return .Space
    case sdl3.K_DELETE    : return .Delete
    case sdl3.K_INSERT    : return .Insert

    case sdl3.K_APOSTROPHE   : return .Apostrophe
    case sdl3.K_COMMA        : return .Comma
    case sdl3.K_MINUS        : return .Minus
    case sdl3.K_PERIOD       : return .Period
    case sdl3.K_SLASH        : return .Slash
    case sdl3.K_SEMICOLON    : return .Semicolon
    case sdl3.K_EQUALS       : return .Equal
    case sdl3.K_LEFTBRACKET  : return .Bracket_Left
    case sdl3.K_BACKSLASH    : return .Backslash
    case sdl3.K_RIGHTBRACKET : return .Bracket_Right
    case sdl3.K_GRAVE        : return .Grave_Accent

    case sdl3.K_PAGEUP    : return .Page_Up
    case sdl3.K_PAGEDOWN  : return .Page_Down
    case sdl3.K_HOME      : return .Home
    case sdl3.K_END       : return .End

    case sdl3.K_LSHIFT : return .Left_Shift
    case sdl3.K_LCTRL  : return .Left_Ctrl
    case sdl3.K_LALT   : return .Left_Alt
    case sdl3.K_RSHIFT : return .Right_Shift
    case sdl3.K_RCTRL  : return .Right_Ctrl
    case sdl3.K_RALT   : return .Right_Alt

    case sdl3.K_RIGHT : return .Right
    case sdl3.K_LEFT  : return .Left
    case sdl3.K_DOWN  : return .Down
    case sdl3.K_UP    : return .Up
    }
    return .Invalid
}

@(private)
key_callback :: proc(key_event: sdl3.KeyboardEvent) {
    if key_event.key == sdl3.K_UNKNOWN do return

    mapped_key := code_to_key(key_event.key)
    if mapped_key != .Invalid {
        if key_event.type == .KEY_UP {
            g_ctx.io.key_released += {mapped_key}
        } else if key_event.type == .KEY_DOWN {
            g_ctx.io.key_pressed  += {mapped_key}
            g_ctx.io.key_released -= {mapped_key}
        }
    }
}

@(private)
mouse_button_callback :: proc (mouse: sdl3.MouseButtonEvent) {
    //if mouse < 0 do return

    if mouse.type == .MOUSE_BUTTON_UP {
        switch mouse.button {
        case sdl3.BUTTON_LEFT:   g_ctx.io.mouse_released += {.Left}
        case sdl3.BUTTON_RIGHT:  g_ctx.io.mouse_released += {.Right}
        case sdl3.BUTTON_MIDDLE: g_ctx.io.mouse_released += {.Middle}
        }
    } else if mouse.type == .MOUSE_BUTTON_DOWN {
        switch mouse.button {
        case sdl3.BUTTON_LEFT:
            g_ctx.io.mouse_pressed  += {.Left}
            g_ctx.io.mouse_released -= {.Left}
        case sdl3.BUTTON_RIGHT:
            g_ctx.io.mouse_pressed  += {.Right}
            g_ctx.io.mouse_released -= {.Right}
        case sdl3.BUTTON_MIDDLE:
            g_ctx.io.mouse_pressed  += {.Middle}
            g_ctx.io.mouse_released -= {.Middle}
        }
    }
}

@(private)
mouse_cursor_pos_callback :: proc(mouse: sdl3.MouseMotionEvent) {
    g_ctx.io.mouse_pos = { i32(mouse.x), i32(mouse.y) }
}

@(private)
mouse_scroll_callback :: proc(wheel: sdl3.MouseWheelEvent) {
    g_ctx.io.scroll_delta.x += i32(wheel.x)
    g_ctx.io.scroll_delta.y += i32(wheel.y)
}

// TODO: does not work yet
@(private)
char_callback :: proc(text: sdl3.TextInputEvent) {
    fmt.println(text.type)
}
