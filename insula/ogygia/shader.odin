package ogygia

Render_Texture :: struct {
    id: Framebuffer,
    texture_id: TextureID,
    depth_id: Renderbuffer,
    width: i32,
    height: i32,
}

shader_load :: platform_shader_load

shader_unload :: platform_shader_unload

set_render_texture :: proc(render_texture: Maybe(Render_Texture)) -> (prev: Maybe(Render_Texture)) {
    prev = nil
    dc := default_draw_call()
    if len(OG.draw_calls) != 0 {
        last := &OG.draw_calls[len(OG.draw_calls) - 1]
        prev = last.render_texture
        if last.render_texture == render_texture {
            return
        }
        last.length = len(OG.vertices) - last.offset
        dc = last^
    }
    dc.render_texture = render_texture
    dc.offset = len(OG.vertices)
    append(&OG.draw_calls, dc)
    return
}

render_texture_load :: proc(width, height: i32) -> (target: Render_Texture) {
    return platform_render_texture_load(width, height)
}
