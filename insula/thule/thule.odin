package thule

Vec2 :: [2]f32
Vec4 :: [4]f32

Circle :: struct {
    pos: Vec2,
    radius: f32,
}

Segment :: struct {
    at: Vec2,
    to: Vec2,
}

Rect :: struct #raw_union {
    vec: [4]f32,
    using rec: struct {
        x: f32,
        y: f32,
        w: f32,
        h: f32,   
    }
}

Line :: struct {
    a: Vec2,
    b: Vec2,
}

create_rect :: #force_inline proc(x, y, w, h: f32) -> Rect {
    return Rect{ rec = {
        x,
        y,
        w,
        h,
    }}
}

overlaps_vec2_vec2 :: proc(a, b: Vec2) -> bool {
    return a == b
}

overlaps_vec2_rect :: proc(a: Vec2, b: Rect) -> bool {
    if a.x >= b.x && a.x <= (b.x + b.w) && a.y >= b.y && a.y <= (b.y + b.h) {
        return true
    }
    return false
}

overlaps_rect_vec2 :: proc(b: Rect, a: Vec2) -> bool {
    if a.x >= b.x && a.x <= (b.x + b.w) && a.y >= b.y && a.y <= (b.y + b.h) {
        return true
    }
    return false
}

overlaps_rect_rect :: proc(a: Rect, b: Rect) -> bool {
    if ((a.x < (b.x + b.w) && (a.x + a.w) > b.x) &&
        (a.y < (b.y + b.h) && (a.y + a.h) > b.y)) {
        return true
    }
    return false
}

overlaps_vec2_vec4 :: proc(a: Vec2, b: Vec4) -> bool {
    if a.x >= b[0] && a.x <= (b[0] + b[2]) && a.y >= b[1] && a.y <= (b[1] + b[3]) {
        return true
    }
    return false
}

overlaps_vec4_vec2 :: proc(b: Vec4, a: Vec2) -> bool {
    if a.x >= b[0] && a.x <= (b[0] + b[2]) && a.y >= b[1] && a.y <= (b[1] + b[3]) {
        return true
    }
    return false
}

overlaps_vec4_vec4 :: proc(a: Vec4, b: Vec4) -> bool {
    if ((a[0] < (b[0] + b[2]) && (a[0] + a[2]) > b[0]) &&
        (a[1] < (b[1] + b[3]) && (a[1] + a[3]) > b[1])) {
        return true
    }
    return false
}

overlaps :: proc{
    overlaps_vec2_rect,
    overlaps_rect_vec2,
    overlaps_rect_rect,

    overlaps_vec2_vec4,
    overlaps_vec4_vec2,
    overlaps_vec4_vec4,
}
