package avalon

// package for testing
//import "core:fmt"

Mouse_Button :: enum u16 {
    Left,
    Right,
    Middle,
}

Modifier_Key :: enum u32 {
    Ctrl,
    Shift,
    Alt,
}

Key :: enum u16 {
    Invalid,

    Left_Ctrl, Left_Shift, Left_Alt,
    Right_Ctrl, Right_Shift, Right_Alt,

    A, B, C, D, E, F, G, H,
    I, J, K, L, M, N, O, P,
    Q, R, S, T, U, V, W, X,
    Y, Z,

    Key_0, Key_1, Key_2,
    Key_3, Key_4, Key_5,
    Key_6, Key_7, Key_8,
    Key_9,

    Numpad_0, Numpad_1, Numpad_2, Numpad_3, Numpad_4,
    Numpad_5, Numpad_6, Numpad_7, Numpad_8, Numpad_9,
    Numpad_Divide, Numpad_Multiply, Numpad_Subtract,
    Numpad_Add, Numpad_Enter, Numpad_Decimal,

    Escape,
    Return,
    Tab,
    Backspace,
    Space,
    Delete,
    Insert,

    Apostrophe,
    Comma,
    Minus,
    Period,
    Slash,
    Semicolon,
    Equal,
    Backslash,
    Bracket_Left,
    Bracket_Right,
    Grave_Accent,
    Home,
    End,
    Page_Up,
    Page_Down,

    Up,
    Down,
    Left,
    Right,
}

Key_Stroke :: struct {
    modifiers: Modifier_Key_Set,
    key: Key,
}

MAX_GAMEPADS :: 8

Mouse_Button_Set :: distinct bit_set[Mouse_Button; u16]
Key_Set          :: distinct bit_set[Key; u128]
Modifier_Key_Set :: distinct bit_set[Modifier_Key; u32]

MODIFIER_KEYS :: Key_Set{
        .Left_Ctrl,  .Left_Shift,  .Left_Alt,
        .Right_Ctrl, .Right_Shift, .Right_Alt,
}

IO :: struct {
    mouse_pos:         [2]i32,
    mouse_last_pos:    [2]i32,
    mouse_pressed_pos: [2]i32,
    mouse_delta:       [2]i32,

    mouse_down:     Mouse_Button_Set,
    mouse_pressed:  Mouse_Button_Set,
    mouse_released: Mouse_Button_Set,
    internal_mouse_was_down: Mouse_Button_Set,

    key_down: Key_Set,

    key_pressed: Key_Set,
    key_released: Key_Set,
    key_repeat: Key_Set,

    modifiers: Modifier_Key_Set,
    pressed_key_stroke: Key_Stroke,

    key_pressed_count_per_frame: [Key]u8,

    last_key_press_time: f64,

    scroll_delta: [2]i32,

    click_count: i32,

    full_reset: bool,
}

key_strings := [Key]string{
	.Invalid = "invalid",

	.Left_Ctrl   = "lctrl",
	.Left_Shift  = "lshift",
	.Left_Alt    = "lalt",
	.Right_Ctrl  = "rctrl",
	.Right_Shift = "rshift",
	.Right_Alt   = "ralt",

	.Escape    = "escape",
	.Return    = "return",
	.Tab       = "tab",
	.Backspace = "backspace",
	.Space     = "space",
	.Delete    = "delete",
	.Insert    = "insert",

	.Apostrophe    = "'",
	.Comma         = ",",
	.Minus         = "-",
	.Period        = ".",
	.Slash         = "/",
	.Semicolon     = ";",
	.Equal         = "=",
	.Backslash     = "\\",
	.Bracket_Left  = "[",
	.Bracket_Right = "]",
	.Grave_Accent  = "`",
	.Home          = "home",
	.End           = "end",
	.Page_Up       = "page_up",
	.Page_Down     = "page_down",


	.A = "a", .B = "b", .C = "c", .D = "d", .E = "e", .F = "f", .G = "g", .H = "h",
	.I = "i", .J = "j", .K = "k", .L = "l", .M = "m", .N = "n", .O = "o", .P = "p",
	.Q = "q", .R = "r", .S = "s", .T = "t", .U = "u", .V = "v", .W = "w", .X = "x",
	.Y = "y", .Z = "z",

	.Key_0 = "0", .Key_1 = "1", .Key_2 = "2", .Key_3 = "3", .Key_4 = "4",
	.Key_5 = "5", .Key_6 = "6", .Key_7 = "7", .Key_8 = "8", .Key_9 = "9",

	.Numpad_0 = "numpad_0", .Numpad_1 = "numpad_1", .Numpad_2 = "numpad_2", .Numpad_3 = "numpad_3", .Numpad_4 = "numpad_4",
	.Numpad_5 = "numpad_5", .Numpad_6 = "numpad_6", .Numpad_7 = "numpad_7", .Numpad_8 = "numpad_8", .Numpad_9 = "numpad_9",
	.Numpad_Divide = "numpad_divide", .Numpad_Multiply = "numpad_multiply", .Numpad_Subtract = "numpad_subtract",
	.Numpad_Add    = "numpad_add",    .Numpad_Enter    = "numpad_enter",    .Numpad_Decimal  = "numpad_decimal",

	.Up    = "up",
	.Down  = "down",
	.Left  = "left",
	.Right = "right",
}

io_init :: proc() {
    g_ctx.io.key_pressed -= g_ctx.io.key_released
    g_ctx.io.key_down += g_ctx.io.key_pressed
    g_ctx.io.key_down -= g_ctx.io.key_released

    g_ctx.io.mouse_delta = g_ctx.io.mouse_pos - g_ctx.io.mouse_last_pos

    //when ODIN_OS != .JS {
        g_ctx.io.mouse_pressed  -= g_ctx.io.mouse_released
        g_ctx.io.mouse_down     += g_ctx.io.mouse_pressed
        g_ctx.io.mouse_down     -= g_ctx.io.mouse_released
    //} else {
    //    g_ctx.io.mouse_pressed  = g_ctx.io.mouse_down - g_ctx.io.internal_mouse_was_down
    //    g_ctx.io.mouse_released = g_ctx.io.internal_mouse_was_down - g_ctx.io.mouse_down
    //}

    g_ctx.io.modifiers = nil
    for mod in MODIFIER_KEYS {
        if mod in g_ctx.io.key_down  {
            #partial switch mod {
                case .Left_Ctrl,  .Right_Ctrl:  g_ctx.io.modifiers += {.Ctrl}
                case .Left_Shift, .Right_Shift: g_ctx.io.modifiers += {.Shift}
                case .Left_Alt,   .Right_Alt:   g_ctx.io.modifiers += {.Alt}
            }
        }
    }
}

io_fini :: proc() {
    g_ctx.io.mouse_delta    = { 0, 0 }
    g_ctx.io.scroll_delta   = { 0, 0 }
    g_ctx.io.mouse_last_pos = g_ctx.io.mouse_pos

    g_ctx.io.internal_mouse_was_down = g_ctx.io.mouse_down

    //when ODIN_OS != .JS {
        g_ctx.io.mouse_pressed  = nil
        g_ctx.io.mouse_released = nil
    //} else {
    //    g_ctx.io.mouse_down = nil
    //}

    g_ctx.io.key_pressed  = nil
    g_ctx.io.key_released = nil
    g_ctx.io.key_repeat   = nil

    g_ctx.io.pressed_key_stroke = {}

    g_ctx.io.key_pressed_count_per_frame = {}

    // TODO: check how useful this is
    //when ODIN_OS != .JS {
    //    g_ctx.platform_data.char_pressed_queue_count = 0
    //}

    if g_ctx.io.full_reset {
        g_ctx.io.key_released  = g_ctx.io.key_down
        g_ctx.io.mouse_released  = g_ctx.io.mouse_down
        g_ctx.io.key_down      = nil
        g_ctx.io.key_pressed   = nil
        g_ctx.io.key_repeat    = nil
        g_ctx.io.mouse_down    = nil
        g_ctx.io.mouse_pressed = nil
        g_ctx.io.modifiers     = nil
        
        g_ctx.io.full_reset = false
    }
}
