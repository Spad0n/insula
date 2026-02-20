#+build linux, windows, darwin
package avalon

import     "vendor:sdl3"
import     "core:fmt"
import glm "core:math/linalg/glsl"
import     "core:os"

HIGH_DPI :: #config(HIGH_DPI, false)
GL_MAJOR_VERSION, GL_MINOR_VERSION :: 3, 0

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

    sdl3.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl3.GL_CONTEXT_PROFILE_ES))
    sdl3.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_MAJOR_VERSION)
    sdl3.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_MINOR_VERSION)

    window := sdl3.CreateWindow(title, width, height, {.OPENGL})
    if window == nil {
        fmt.eprintln(location, sdl3.GetError())
        os.exit(1)
    }

    sdl3.SetWindowResizable(window, false)

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
code_to_key :: proc (code: sdl3.Scancode) -> Key {
    #partial switch code {
    case .A: return .A
    case .B: return .B
    case .C: return .C
    case .D: return .D
    case .E: return .E
    case .F: return .F
    case .G: return .G
    case .H: return .H
    case .I: return .I
    case .J: return .J
    case .K: return .K
    case .L: return .L
    case .M: return .M
    case .N: return .N
    case .O: return .O
    case .P: return .P
    case .Q: return .Q
    case .R: return .R
    case .S: return .S
    case .T: return .T
    case .U: return .U
    case .V: return .V
    case .W: return .W
    case .X: return .X
    case .Y: return .Y
    case .Z: return .Z

    case ._1: return .Key_1
    case ._2: return .Key_2
    case ._3: return .Key_3
    case ._4: return .Key_4
    case ._5: return .Key_5
    case ._6: return .Key_6
    case ._7: return .Key_7
    case ._8: return .Key_8
    case ._9: return .Key_9
    case ._0: return .Key_0

    case .KP_1: return .Numpad_1
    case .KP_2: return .Numpad_2
    case .KP_3: return .Numpad_3
    case .KP_4: return .Numpad_4
    case .KP_5: return .Numpad_5
    case .KP_6: return .Numpad_6
    case .KP_7: return .Numpad_7
    case .KP_8: return .Numpad_8
    case .KP_9: return .Numpad_9
    case .KP_0: return .Numpad_0

    case .KP_DECIMAL  : return .Numpad_Decimal
    case .KP_DIVIDE   : return .Numpad_Divide
    case .KP_MULTIPLY : return .Numpad_Multiply
    case .KP_MINUS    : return .Numpad_Subtract
    case .KP_PLUS     : return .Numpad_Add
    case .KP_ENTER    : return .Numpad_Enter
    //case .KP_EQUAL    : return .Numpad_Equal

    case .ESCAPE    : return .Escape
    case .RETURN    : return .Return
    case .TAB       : return .Tab
    case .BACKSPACE : return .Backspace
    case .SPACE     : return .Space
    case .DELETE    : return .Delete
    case .INSERT    : return .Insert

    case .APOSTROPHE   : return .Apostrophe
    case .COMMA        : return .Comma
    case .MINUS        : return .Minus
    case .PERIOD       : return .Period
    case .SLASH        : return .Slash
    case .SEMICOLON    : return .Semicolon
    case .EQUALS       : return .Equal
    case .LEFTBRACKET  : return .Bracket_Left
    case .BACKSLASH    : return .Backslash
    case .RIGHTBRACKET : return .Bracket_Right
    case .GRAVE        : return .Grave_Accent

    case .PAGEUP    : return .Page_Up
    case .PAGEDOWN  : return .Page_Down
    case .HOME      : return .Home
    case .END       : return .End

    case .LSHIFT : return .Left_Shift
    case .LCTRL  : return .Left_Ctrl
    case .LALT   : return .Left_Alt
    case .RSHIFT : return .Right_Shift
    case .RCTRL  : return .Right_Ctrl
    case .RALT   : return .Right_Alt

    case .RIGHT : return .Right
    case .LEFT  : return .Left
    case .DOWN  : return .Down
    case .UP    : return .Up
    }
    return .Invalid
}

@(private)
key_callback :: proc(key_event: sdl3.KeyboardEvent) {
    if key_event.scancode == .UNKNOWN do return

    mapped_key := code_to_key(key_event.scancode)
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
