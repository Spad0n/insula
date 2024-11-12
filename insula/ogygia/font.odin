package ogygia

import stbtt "vendor:stb/truetype"
import glm   "core:math/linalg/glsl"
import       "core:image"

Font :: struct {
    info: stbtt.fontinfo,

    atlas: Texture,
    atlas_width: i32,
    atlas_height: i32,

    size: i32,
    ascent: i32,
    descent: i32,
    line_gap: i32,
    baseline: i32,

    backed_chars: [96]stbtt.bakedchar,
}

FONT_ATLAS_SIZE :: 1024

@(private="file")
temp_font_atlas_data: [FONT_ATLAS_SIZE * FONT_ATLAS_SIZE]u8

@(private="file")
temp_font_atlas_pixels: [FONT_ATLAS_SIZE * FONT_ATLAS_SIZE][4]u8

font_load_from_memory :: proc(data: []byte, size: i32) -> (f: Font, ok := true) {
    size := size
    size = max(size, 1)
    stbtt.InitFont(&f.info, raw_data(data), 0) or_return
    f.size = size

    scale := stbtt.ScaleForPixelHeight(&f.info, f32(f.size))
    stbtt.GetFontVMetrics(&f.info, &f.ascent, &f.descent, &f.line_gap)
    f.baseline = i32(f32(f.ascent) * scale)

    f.atlas_width = FONT_ATLAS_SIZE
    f.atlas_height = FONT_ATLAS_SIZE
    stbtt.BakeFontBitmap(raw_data(data), 0, f32(size), raw_data(temp_font_atlas_data[:]), FONT_ATLAS_SIZE, FONT_ATLAS_SIZE, 32, len(f.backed_chars), raw_data(f.backed_chars[:]))
    for b, i in temp_font_atlas_data {
        temp_font_atlas_pixels[i] = {255, 255, 255, b}
    }

    img := image.pixels_to_image(temp_font_atlas_pixels[:], FONT_ATLAS_SIZE, FONT_ATLAS_SIZE) or_return

    f.atlas = texture_load_from_image(&img) or_return

    return f, true
}

font_unload :: proc(f: Font) {
    texture_unload(f.atlas)
}

draw_text :: proc(f: ^Font, text: string, pos: glm.vec2, color: Color) {
    set_texture(f.atlas)

    next := glm.vec2{
        pos.x,
        pos.y + (f32(f.size) / 2),
    }

    for c in text {
        c := c
        switch c {
        case '\n':
            next.x = pos.x
            next.y += f32(f.size)
        case '\r', '\t':
            c = ' '
        }
        if 32 <= c && c < 128 {
            q: stbtt.aligned_quad
            stbtt.GetBakedQuad(&f.backed_chars[0], f.atlas_width, f.atlas.height, i32(c) - 32, &next.x, &next.y, &q, true)

            a := Vertex{pos = {q.x0, q.y0, OG.curr_z}, texcoord = {q.s0, q.t0}, color = color_to_vec4(color)}
            b := Vertex{pos = {q.x1, q.y0, OG.curr_z}, texcoord = {q.s1, q.t0}, color = color_to_vec4(color)}
            c := Vertex{pos = {q.x1, q.y1, OG.curr_z}, texcoord = {q.s1, q.t1}, color = color_to_vec4(color)}
            d := Vertex{pos = {q.x0, q.y1, OG.curr_z}, texcoord = {q.s0, q.t1}, color = color_to_vec4(color)}

            append(&OG.vertices, a, b, c)
            append(&OG.vertices, c, d, a)
        }
    }
}
