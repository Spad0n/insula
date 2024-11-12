package ogygia

import     "core:math"
import glm "core:math/linalg/glsl"

@(require_results)
default_draw_call :: #force_inline proc() -> Draw_Call {
    return Draw_Call{
        shader = OG.default_shader,
        texture = OG.default_texture,
        depth_test = false,
        offset = len(OG.vertices),
        length = 0,
    }
}

set_background :: proc(color: Color) {
    OG.clear_color = color_to_vec4(color)
}

set_texture :: proc(texture: Texture) -> (prev: Texture) {
    texture := texture
    if texture.handle == ~TextureID(0) {
        texture = OG.default_texture
    }

    prev = OG.default_texture
    dc := default_draw_call()
    if len(OG.draw_calls) != 0 {
        last := &OG.draw_calls[len(OG.draw_calls) - 1]
        prev = last.texture
        if last.texture == texture {
            return
        }
        last.length = len(OG.vertices) - last.offset
        dc = last^
    }
    dc.texture = texture
    dc.offset = len(OG.vertices)
    append(&OG.draw_calls, dc)
    return
}

set_shader :: proc(shader: Shader = SHADER_INVALID) -> (prev: Shader) {
    shader := shader
    if shader == SHADER_INVALID {
        shader = OG.default_shader
    }

    prev = OG.default_shader
    dc := default_draw_call()

    if len(OG.draw_calls) != 0 {
        last := &OG.draw_calls[len(OG.draw_calls) - 1]
        prev = last.shader
        if last.shader == shader {
            return
        }
        last.length = len(OG.vertices) - last.offset
        dc = last^
    }
    dc.shader = shader
    dc.offset = len(OG.vertices)
    append(&OG.draw_calls, dc)
    return
}

set_depth_test :: proc(depth_test: bool) -> (prev: bool) {
    prev = false
    dc := default_draw_call()
    if len(OG.draw_calls) != 0 {
        last := &OG.draw_calls[len(OG.draw_calls) - 1]
        prev = last.depth_test
        if last.depth_test == depth_test {
            return
        }
        last.length = len(OG.vertices) - last.offset
        dc = last^
    }
    dc.depth_test = depth_test
    dc.offset = len(OG.vertices)
    append(&OG.draw_calls, dc)
    return
}

set_clip_rect :: proc(clip_rect: Maybe(Clip_Rect)) -> (prev: Maybe(Clip_Rect)) {
    prev = nil
    dc := default_draw_call()
    if len(OG.draw_calls) != 0 {
        last := &OG.draw_calls[len(OG.draw_calls) - 1]
        prev = last.clip_rect
        if last.clip_rect == clip_rect {
            return
        }
        last.length = len(OG.vertices) - last.offset
        dc = last^
    }
    dc.clip_rect = clip_rect
    dc.offset = len(OG.vertices)
    append(&OG.draw_calls, dc)
    return
}

draw_all :: proc() -> bool {
    if len(OG.draw_calls) > 0 {
        last := &OG.draw_calls[len(OG.draw_calls) - 1]
        last.length = len(OG.vertices) - last.offset
    }
    ok := platform_draw()
    clear(&OG.vertices)
    clear(&OG.draw_calls)
    return true
}

@(private)
rotate_vectors :: proc(offset: int, pos, origin: glm.vec2, rotation: f32) {
    s, c := math.sincos(rotation)
    for &v in OG.vertices[offset:] {
        p := v.pos.xy - pos - origin
        p = {c * p.x - s * p.y, s * p.x + c * p.y}
        p.xy += pos
        v.pos.xy = p
    }
}

draw_rect :: proc(
    pos, size: glm.vec2,
    origin   := glm.vec2{0, 0},
    rotation := f32(0),
    texture  := TEXTURE_INVALID,
    uv0      := glm.vec2{0, 0},
    uv1      := glm.vec2{1, 1},
    color    := WHITE,
) {
    set_texture(texture)

    uv0 := uv0
    uv1 := uv1

    if texture != TEXTURE_INVALID {
        if uv0 != 0 {
            uv0 = glm.vec2{
                uv0.x / f32(texture.width),
                uv0.y / f32(texture.height),
            }
        }
        if uv1 != 1 {
            uv1 = glm.vec2{
                uv1.x / f32(texture.width),
                uv1.y / f32(texture.height),
            }
        }
    }

    offset := len(OG.vertices)

    a := pos
    b := pos + {size.x, 0}
    c := pos + {size.x, size.y}
    d := pos + {0, size.y}

    z := OG.curr_z

    append(&OG.vertices, Vertex{pos = {a.x, a.y, z}, color = color_to_vec4(color), texcoord = {uv0.x, uv0.y}})
    append(&OG.vertices, Vertex{pos = {b.x, b.y, z}, color = color_to_vec4(color), texcoord = {uv1.x, uv0.y}})
    append(&OG.vertices, Vertex{pos = {c.x, c.y, z}, color = color_to_vec4(color), texcoord = {uv1.x, uv1.y}})

    append(&OG.vertices, Vertex{pos = {c.x, c.y, z}, color = color_to_vec4(color), texcoord = {uv1.x, uv1.y}})
    append(&OG.vertices, Vertex{pos = {d.x, d.y, z}, color = color_to_vec4(color), texcoord = {uv0.x, uv1.y}})
    append(&OG.vertices, Vertex{pos = {a.x, a.y, z}, color = color_to_vec4(color), texcoord = {uv0.x, uv0.y}})
    rotate_vectors(offset, pos, origin, rotation)
}
