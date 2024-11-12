package avalon

import     "core:fmt"
import glm "core:math/linalg/glsl"
import js  "core:sys/wasm/js"

foreign import setup "odin_setup"

@(default_calling_convention="contextless")
foreign setup {
    set_canvas_size :: proc(name: string, width: i32, height: i32) ---
}

Platform_Data :: struct {
    title: cstring,
    screen_width: i32,
    screen_height: i32,
    ready: bool,
}

events_to_handle :: [?]js.Event_Kind{
        .Focus,
        .Blur,
        .Mouse_Move,
        .Mouse_Up,
        .Mouse_Down,
        .Key_Down,
        .Key_Up,
        .Scroll,
}

platform_init :: proc(width, height: i32, title: cstring = " ", location := #caller_location) {
    g_ctx.platform_data.title = title
    g_ctx.platform_data.screen_width = width
    g_ctx.platform_data.screen_height = height

    set_canvas_size("game", width, height)

    g_ctx.platform_data.ready = true

    for kind in events_to_handle {
        js.add_window_event_listener(kind, {}, platform_event_callback)
    }
}

platform_fini :: proc() {
    for kind in events_to_handle {
        js.remove_window_event_listener(kind, {}, platform_event_callback)
    }
}

platform_update :: proc() -> bool {
    //client_width := i32(js.get_element_key_f64(g_ctx.canvas_id, "clientWidth"))
    //client_height := i32(js.get_element_key_f64(g_ctx.canvas_id, "clientWidth"))

    //client_width  /= max(i32(g_ctx.pixel_scale), 1)
    //client_height /= max(i32(g_ctx.pixel_scale), 1)

    //client_width  = max(client_width, 1)
    //client_height = max(client_height, 1)

    //width  := max(i32(js.get_element_key_f64(g_ctx.canvas_id, "width")), 1)
    //height := max(i32(js.get_element_key_f64(g_ctx.canvas_id, "height")), 1)
    return true
}

platform_event_callback :: proc(e: js.Event) {
    #partial switch e.kind {
    case .Focus: // Enter
        
    case .Blur:  // Exit
        
    case .Mouse_Move:
        g_ctx.io.mouse_pos = {
            i32(e.mouse.offset.x),
            i32(e.mouse.offset.y),
        }
    case .Mouse_Up:
        g_ctx.io.mouse_pos = {
            i32(e.mouse.offset.x),
            i32(e.mouse.offset.y),
        }
        //switch e.mouse.button {
        //case 0: g_ctx.io.mouse_down += {.Left}
        //case 1: g_ctx.io.mouse_down += {.Middle}
        //case 2: g_ctx.io.mouse_down += {.Right}
        //}
        switch e.mouse.button {
        case 0: g_ctx.io.mouse_released += {.Left}
        case 1: g_ctx.io.mouse_released += {.Middle}
        case 2: g_ctx.io.mouse_released += {.Right}
        }
    case .Mouse_Down:
        g_ctx.io.mouse_pos = {
            i32(e.mouse.offset.x),
            i32(e.mouse.offset.y),
        }
	g_ctx.io.mouse_pressed_pos = {
            i32(e.mouse.offset.x),
            i32(e.mouse.offset.y)
        }
        switch e.mouse.button {
        case 0: g_ctx.io.mouse_pressed += {.Left}
        case 1: g_ctx.io.mouse_pressed += {.Middle}
        case 2: g_ctx.io.mouse_pressed += {.Right}
        }
        g_ctx.io.mouse_down -= g_ctx.io.mouse_pressed
    case .Key_Down:
        if key := code_to_key(e.key.code); key != .Invalid {
            if !e.key.repeat {
                g_ctx.io.key_pressed += {key}
            } else {
                g_ctx.io.key_repeat += {key}
            }
        }
    case .Key_Up:
        if key := code_to_key(e.key.code); key != .Invalid {
            g_ctx.io.key_released += {key}
        }
    case .Scroll:
        g_ctx.io.scroll_delta.x += i32(e.scroll.delta.x)
        g_ctx.io.scroll_delta.y += i32(e.scroll.delta.y)
    }
}

@(private)
code_to_key :: proc(code: string) -> Key {
    switch code {
    case "KeyA": return .A
    case "KeyB": return .B
    case "KeyC": return .C
    case "KeyD": return .D
    case "KeyE": return .E
    case "KeyF": return .F
    case "KeyG": return .G
    case "KeyH": return .H
    case "KeyI": return .I
    case "KeyJ": return .J
    case "KeyK": return .K
    case "KeyL": return .L
    case "KeyM": return .M
    case "KeyN": return .N
    case "KeyO": return .O
    case "KeyP": return .P
    case "KeyQ": return .Q
    case "KeyR": return .R
    case "KeyS": return .S
    case "KeyT": return .T
    case "KeyU": return .U
    case "KeyV": return .V
    case "KeyW": return .W
    case "KeyX": return .X
    case "KeyY": return .Y
    case "KeyZ": return .Z

    case "Digit1": return .Key_1
    case "Digit2": return .Key_2
    case "Digit3": return .Key_3
    case "Digit4": return .Key_4
    case "Digit5": return .Key_5
    case "Digit6": return .Key_6
    case "Digit7": return .Key_7
    case "Digit8": return .Key_8
    case "Digit9": return .Key_9
    case "Digit0": return .Key_0

    case "Numpad1": return .Numpad_1
    case "Numpad2": return .Numpad_2
    case "Numpad3": return .Numpad_3
    case "Numpad4": return .Numpad_4
    case "Numpad5": return .Numpad_5
    case "Numpad6": return .Numpad_6
    case "Numpad7": return .Numpad_7
    case "Numpad8": return .Numpad_8
    case "Numpad9": return .Numpad_9
    case "Numpad0": return .Numpad_0

    case "NumpadDivide":   return .Numpad_Divide
    case "NumpadMultiply": return .Numpad_Multiply
    case "NumpadSubtract": return .Numpad_Subtract
    case "NumpadAdd":      return .Numpad_Add
    case "NumpadEnter":    return .Numpad_Enter
    case "NumpadDecimal":  return .Numpad_Decimal

    case "Escape":    return .Escape
    case "Enter":     return .Return
    case "Tab":       return .Tab
    case "Backspace": return .Backspace
    case "Space":     return .Space
    case "Delete":    return .Delete
    case "Insert":    return .Insert

    case "Quote":         return .Apostrophe
    case "Comma":         return .Comma
    case "Minus":         return .Minus
    case "Period":        return .Period
    case "Slash":         return .Slash
    case "Semicolon":     return .Semicolon
    case "Equal":         return .Equal
    case "Backslash":     return .Backslash
    case "IntlBackslash": return .Backslash
    case "BracketLeft":   return .Bracket_Left
    case "BracketRight":  return .Bracket_Right
    case "Backquote":     return .Grave_Accent

    case "Home":     return .Home
    case "End":      return .End
    case "PageUp":   return .Page_Up
    case "PageDown": return .Page_Down

    case "ControlLeft":  return .Left_Ctrl
    case "ShiftLeft":    return .Left_Shift
    case "AltLeft":      return .Left_Alt
    case "ControlRight": return .Right_Ctrl
    case "ShiftRight":   return .Right_Shift
    case "AltRight":     return .Right_Alt

    case "ArrowUp":    return .Up
    case "ArrowDown":  return .Down
    case "ArrowLeft":  return .Left
    case "ArrowRight": return .Right
    }
    return .Invalid
}
