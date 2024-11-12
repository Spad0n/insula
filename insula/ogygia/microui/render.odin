package microui

import mu "vendor:microui"
import og ".."
import    "core:image"
import sa "core:container/small_array"

State :: struct {
    ctx:             mu.Context,
    log_buf:         sa.Small_Array(1 << 16, byte),
    log_buf_updated: bool,
    bg:              mu.Color,
    pixels_data:     [mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT][4]u8,
    atlas_texture:   og.Texture
}

@(require_results)
init :: proc() -> (state: State, ok := true) {
    for alpha, i in mu.default_atlas_alpha {
        state.pixels_data[i].rgb = 0xFF
        state.pixels_data[i].a   = alpha
    }
    img := image.pixels_to_image(state.pixels_data[:], mu.DEFAULT_ATLAS_WIDTH, mu.DEFAULT_ATLAS_HEIGHT) or_return

    state.atlas_texture = og.texture_load_from_image(&img) or_return

    state.bg = {90, 95, 100, 255}

    mu_ctx := &state.ctx
    mu.init(mu_ctx)
    mu_ctx.text_width  = mu.default_atlas_text_width
    mu_ctx.text_height = mu.default_atlas_text_height
}

render :: proc(ctx: ^State) {
    render_texture :: proc(dst: ^tu.Rect, src: mu.Rect, color: mu.Color) {
        dst.w = f32(src.w)
        dst.h = f32(src.h)
        
        color := og.Color{
            color.r,
            color.g,
            color.b,
            color.a
        }

        og.draw_rect(
            {f32(dst.x), f32(dst.y)},
            {f32(dst.w), f32(dst.h)},
            uv0 = {f32(src.x), f32(src.y)},
            uv1 = {f32(src.w + src.x), f32(src.h + src.y)},
            color = color,
            texture = state.atlas_texture
        )
    }

    ctx := &state.ctx

    command_backing: ^mu.Command
    for variant in mu.next_command_iterator(ctx, &command_backing) {
        switch cmd in variant {
        case ^mu.Command_Text:
            dst := tu.create_rect(f32(cmd.pos.x), f32(cmd.pos.y), 0, 0)
            for ch in cmd.str do if ch & 0xc0 != 0x80 {
                r := min(int(ch), 127)
                src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
                render_texture(&dst, src, cmd.color)
                dst.x += dst.w
            }
        case ^mu.Command_Rect:
            og.draw_rect({f32(cmd.rect.x), f32(cmd.rect.y)}, {f32(cmd.rect.w), f32(cmd.rect.h)}, color = {cmd.color.r, cmd.color.g, cmd.color.b, cmd.color.a})
        case ^mu.Command_Icon:
            src := mu.default_atlas[cmd.id]
            x := cmd.rect.x + (cmd.rect.w - src.w)/2
            y := cmd.rect.y + (cmd.rect.h - src.h)/2
            rect := tu.create_rect(f32(x), f32(y), 0, 0)
            render_texture(&rect, src, cmd.color)
        case ^mu.Command_Clip:
            og.set_clip_rect(og.Clip_Rect{{f32(cmd.rect.x), f32(cmd.rect.y)}, {f32(cmd.rect.w), f32(cmd.rect.h)}})
        case ^mu.Command_Jump: 
            unreachable()
        }
    }
}
