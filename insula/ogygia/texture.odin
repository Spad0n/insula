package ogygia

import glm "core:math/linalg/glsl"
import     "core:image"
import     "core:math"
import     "core:fmt"

Texture :: struct {
    handle: TextureID,
    width:  i32,
    height: i32,
}

Texture_Filter :: enum u8 {
    Linear,
    Nearest,
}

Texture_Wrap :: enum u8 {
    Clamp_To_Edge,
    Repeat,
    Mirrored_Repeat,
}

Texture_Options :: struct {
    filter: Texture_Filter,
    wrap:   [2]Texture_Wrap,
}

TEXTURE_OPTIONS_DEFAULT :: Texture_Options{}

texture_load_default_white :: proc() -> (tex: Texture, ok: bool) {
    white_pixel := [1][4]u8{0..<1 = {255, 255, 255, 255}}
    img := image.pixels_to_image(white_pixel[:], 1, 1) or_return
    tex = texture_load_from_image(&img, {
        filter = .Nearest,
        wrap = {.Clamp_To_Edge, .Clamp_To_Edge},
    }) or_return
    return tex, true
}

texture_load_from_image :: proc(img: ^image.Image, opts := TEXTURE_OPTIONS_DEFAULT) -> (tex: Texture, ok: bool) {
    return platform_texture_load_from_img(img, opts)
}

texture_unload :: proc(tex: Texture) {
    platform_texture_unload(tex)
}
