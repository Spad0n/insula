#+build linux, windows, darwin
package avalon

import     "vendor:glfw"
import     "core:fmt"
import glm "core:math/linalg/glsl"
import     "core:os"
import     "base:runtime"
import     "core:time"
//import     "insula:ogygia"

HIGH_DPI :: #config(HIGH_DPI, false)
GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

gl_set_proc_address :: glfw.gl_set_proc_address

Platform_Data :: struct {
    handle: glfw.WindowHandle,
    title: cstring,
    screen_width: i32,
    screen_height: i32,
    ready: bool,
    resized_last_frame: bool,
    should_close: bool,
    event_waiting: bool,

    // TODO: move to io.odin
    char_pressed_queue: [MAX_CHAR_PRESSED_QUEUE]rune,
    char_pressed_queue_count: int,
}

platform_init :: proc(width, height: i32, title: cstring, location := #caller_location) {
    g_ctx.platform_data.title = title
    g_ctx.platform_data.screen_width = width
    g_ctx.platform_data.screen_height = height

    if !glfw.Init() {
        description, code := glfw.GetError()
        fmt.eprintln(location, description, code)
        os.exit(1)
    }

    glfw.SetErrorCallback(error_callback)

    glfw.WindowHint(glfw.RESIZABLE, 1)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    when HIGH_DPI {
        glfw.WindowHint(glfw.SCALE_TO_MONITOR, 1)
    }

    g_ctx.platform_data.handle = glfw.CreateWindow(width, height, title, nil, nil)
    if g_ctx.platform_data.handle == nil {
        description, code := glfw.GetError()
        fmt.eprintln(location, description, code)
        os.exit(1)
    }

    glfw.MakeContextCurrent(g_ctx.platform_data.handle)

    // TODO: changing the way we refresh framerate
    glfw.SwapInterval(1)

    glfw.SetWindowSizeCallback(g_ctx.platform_data.handle, window_size_callback)

    glfw.SetKeyCallback(g_ctx.platform_data.handle, key_callback)
    glfw.SetCharCallback(g_ctx.platform_data.handle, char_callback);
    glfw.SetMouseButtonCallback(g_ctx.platform_data.handle, mouse_button_callback);
    glfw.SetCursorPosCallback(g_ctx.platform_data.handle, mouse_cursor_pos_callback);
    glfw.SetScrollCallback(g_ctx.platform_data.handle, mouse_scroll_callback);
    glfw.SetCursorEnterCallback(g_ctx.platform_data.handle, cursor_enter_callback);

    g_ctx.platform_data.ready = true

    //g_ctx.time.previous = time.tick_now()
}

window_should_close :: proc() -> bool {
    if g_ctx.platform_data.ready {
        g_ctx.platform_data.should_close = bool(glfw.WindowShouldClose(g_ctx.platform_data.handle))
        glfw.SetWindowShouldClose(g_ctx.platform_data.handle, glfw.FALSE)
        return g_ctx.platform_data.should_close
    } else {
        return true
    }
}

set_clipboard_text :: proc(text: cstring) {
    glfw.SetClipboardString(g_ctx.handle, text)
}

get_clipboard_text :: proc() -> string {
    return glfw.GetClipboardString(g_ctx.handle)
}

@(private)
platform_update :: proc() {
    glfw.SwapBuffers(g_ctx.platform_data.handle)
    glfw.PollEvents()
    //fmt.println(glfw.GetTime())
    //poll_inputs_events()
}

@(private)
platform_fini :: proc() {
    glfw.DestroyWindow(g_ctx.platform_data.handle)
    glfw.Terminate()
}

//@(private)
//poll_inputs_events :: proc() {
//    glfw.PollEvents()
//}

//set_target_fps :: proc(fps: f32) {
//    if fps < 1 {
//        g_ctx.time.target = 0
//    } else {
//        g_ctx.time.target = time.Millisecond * time.Duration(1000)
//    }
//}
//
//get_frame_time :: proc() -> f64 {
//    return 0.16
//}

get_char_pressed :: proc() -> (value: rune) {
    if g_ctx.platform_data.char_pressed_queue_count > 0 {
        value = g_ctx.platform_data.char_pressed_queue[0]

        for i in 0..<g_ctx.platform_data.char_pressed_queue_count - 1 {
            g_ctx.platform_data.char_pressed_queue[i] = g_ctx.platform_data.char_pressed_queue[i + 1]
        }

        g_ctx.platform_data.char_pressed_queue[g_ctx.platform_data.char_pressed_queue_count - 1] = 0
        g_ctx.platform_data.char_pressed_queue_count -= 1
    }
    
    return
}

// ---------------------------------------------------------------------------
// Callbacks Functions Definitions
// ---------------------------------------------------------------------------

@(private)
code_to_key :: proc "c" (code: i32) -> Key {
    switch code {
    case glfw.KEY_A: return .A
    case glfw.KEY_B: return .B
    case glfw.KEY_C: return .C
    case glfw.KEY_D: return .D
    case glfw.KEY_E: return .E
    case glfw.KEY_F: return .F
    case glfw.KEY_G: return .G
    case glfw.KEY_H: return .H
    case glfw.KEY_I: return .I
    case glfw.KEY_J: return .J
    case glfw.KEY_K: return .K
    case glfw.KEY_L: return .L
    case glfw.KEY_M: return .M
    case glfw.KEY_N: return .N
    case glfw.KEY_O: return .O
    case glfw.KEY_P: return .P
    case glfw.KEY_Q: return .Q
    case glfw.KEY_R: return .R
    case glfw.KEY_S: return .S
    case glfw.KEY_T: return .T
    case glfw.KEY_U: return .U
    case glfw.KEY_V: return .V
    case glfw.KEY_W: return .W
    case glfw.KEY_X: return .X
    case glfw.KEY_Y: return .Y
    case glfw.KEY_Z: return .Z

    case glfw.KEY_1: return .Key_1
    case glfw.KEY_2: return .Key_2
    case glfw.KEY_3: return .Key_3
    case glfw.KEY_4: return .Key_4
    case glfw.KEY_5: return .Key_5
    case glfw.KEY_6: return .Key_6
    case glfw.KEY_7: return .Key_7
    case glfw.KEY_8: return .Key_8
    case glfw.KEY_9: return .Key_9
    case glfw.KEY_0: return .Key_0

    case glfw.KEY_KP_1: return .Numpad_1
    case glfw.KEY_KP_2: return .Numpad_2
    case glfw.KEY_KP_3: return .Numpad_3
    case glfw.KEY_KP_4: return .Numpad_4
    case glfw.KEY_KP_5: return .Numpad_5
    case glfw.KEY_KP_6: return .Numpad_6
    case glfw.KEY_KP_7: return .Numpad_7
    case glfw.KEY_KP_8: return .Numpad_8
    case glfw.KEY_KP_9: return .Numpad_9
    case glfw.KEY_KP_0: return .Numpad_0

    case glfw.KEY_KP_DECIMAL  : return .Numpad_Decimal
    case glfw.KEY_KP_DIVIDE   : return .Numpad_Divide
    case glfw.KEY_KP_MULTIPLY : return .Numpad_Multiply
    case glfw.KEY_KP_SUBTRACT : return .Numpad_Subtract
    case glfw.KEY_KP_ADD      : return .Numpad_Add
    case glfw.KEY_KP_ENTER    : return .Numpad_Enter
    //case glfw.KEY_KP_EQUAL    : return .Numpad_Equal

    case glfw.KEY_ESCAPE    : return .Escape
    case glfw.KEY_ENTER     : return .Return
    case glfw.KEY_TAB       : return .Tab
    case glfw.KEY_BACKSPACE : return .Backspace
    case glfw.KEY_SPACE     : return .Space
    case glfw.KEY_DELETE    : return .Delete
    case glfw.KEY_INSERT    : return .Insert

    case glfw.KEY_APOSTROPHE    : return .Apostrophe
    case glfw.KEY_COMMA         : return .Comma
    case glfw.KEY_MINUS         : return .Minus
    case glfw.KEY_PERIOD        : return .Period
    case glfw.KEY_SLASH         : return .Slash
    case glfw.KEY_SEMICOLON     : return .Semicolon
    case glfw.KEY_EQUAL         : return .Equal
    case glfw.KEY_LEFT_BRACKET  : return .Bracket_Left
    case glfw.KEY_BACKSLASH     : return .Backslash
    case glfw.KEY_RIGHT_BRACKET : return .Bracket_Right
    case glfw.KEY_GRAVE_ACCENT  : return .Grave_Accent

    case glfw.KEY_PAGE_UP   : return .Page_Up
    case glfw.KEY_PAGE_DOWN : return .Page_Down
    case glfw.KEY_HOME      : return .Home
    case glfw.KEY_END       : return .End

    case glfw.KEY_LEFT_SHIFT    : return .Left_Shift
    case glfw.KEY_LEFT_CONTROL  : return .Left_Ctrl
    case glfw.KEY_LEFT_ALT      : return .Left_Alt
    case glfw.KEY_RIGHT_SHIFT   : return .Right_Shift
    case glfw.KEY_RIGHT_CONTROL : return .Right_Ctrl
    case glfw.KEY_RIGHT_ALT     : return .Right_Alt

    case glfw.KEY_RIGHT : return .Right
    case glfw.KEY_LEFT  : return .Left
    case glfw.KEY_DOWN  : return .Down
    case glfw.KEY_UP    : return .Up
    }
    return .Invalid
}

@(private)
error_callback :: proc "c" (error: i32, description: cstring) {
    context = runtime.default_context()
    fmt.eprintf("GLFW: Error: %i Description: %s\n", error, description)
}

@(private)
window_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
    //context = runtime.default_context()
    //ogygia.setup_viewport(width, height)

    g_ctx.platform_data.screen_width = width
    g_ctx.platform_data.screen_height = height
    g_ctx.platform_data.resized_last_frame = true
}

@(private)
key_callback :: proc "c" (window: glfw.WindowHandle, keycode: i32, scancode: i32, action: i32, mods: i32) {
    if keycode < 0 do return

    if key := code_to_key(keycode); key != .Invalid {
        if action == glfw.RELEASE {
            g_ctx.io.key_released += {key}
        } else {
            g_ctx.io.key_pressed  += {key}
            g_ctx.io.key_released -= {key}
        }
    }
}

@(private)
char_callback :: proc "c" (window: glfw.WindowHandle, codepoint: rune) {
    if g_ctx.platform_data.char_pressed_queue_count < MAX_CHAR_PRESSED_QUEUE {
        g_ctx.platform_data.char_pressed_queue[g_ctx.platform_data.char_pressed_queue_count] = codepoint
        g_ctx.platform_data.char_pressed_queue_count += 1
    }
}

@(private)
mouse_button_callback :: proc "c" (window: glfw.WindowHandle, button: i32, action: i32, mods: i32) {
    if button < 0 do return

    //switch button {
    //case glfw.MOUSE_BUTTON_1: g_ctx.io.mouse_down += {.Left}
    //case glfw.MOUSE_BUTTON_2: g_ctx.io.mouse_down += {.Right}
    //case glfw.MOUSE_BUTTON_3: g_ctx.io.mouse_down += {.Middle}
    //}
    if action == glfw.RELEASE {
        switch button {
        case glfw.MOUSE_BUTTON_1: g_ctx.io.mouse_released += {.Left}
        case glfw.MOUSE_BUTTON_2: g_ctx.io.mouse_released += {.Right}
        case glfw.MOUSE_BUTTON_3: g_ctx.io.mouse_released += {.Middle}
        }
    } else {
        switch button {
        case glfw.MOUSE_BUTTON_1:
            g_ctx.io.mouse_pressed  += {.Left}
            g_ctx.io.mouse_released -= {.Left}
        case glfw.MOUSE_BUTTON_2:
            g_ctx.io.mouse_pressed  += {.Right}
            g_ctx.io.mouse_released -= {.Right}
        case glfw.MOUSE_BUTTON_3:
            g_ctx.io.mouse_pressed  += {.Middle}
            g_ctx.io.mouse_released -= {.Middle}
        }
    }
}

@(private)
mouse_cursor_pos_callback :: proc "c" (window: glfw.WindowHandle, xpos: f64, ypos: f64) {

    // TODO: new IO implementation
    g_ctx.io.mouse_pos = { i32(xpos), i32(ypos) }
}

@(private)
mouse_scroll_callback :: proc "c" (window: glfw.WindowHandle, xoffset: f64, yoffset: f64) {
    g_ctx.io.scroll_delta.x += i32(xoffset)
    g_ctx.io.scroll_delta.y += i32(yoffset)
}

@(private)
cursor_enter_callback :: proc "c" (window: glfw.WindowHandle, entered: i32) {
}
