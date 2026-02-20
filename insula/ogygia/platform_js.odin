package ogygia

import glm "core:math/linalg/glsl"
import     "core:image"
import     "core:bytes"
import gl  "vendor:wasm/WebGL"

VertexArrayObject :: gl.VertexArrayObject
Shader            :: gl.Program
TextureID         :: gl.Texture
Buffer            :: gl.Buffer
Framebuffer       :: gl.Framebuffer
Renderbuffer      :: gl.Renderbuffer

SHADER_INVALID       :: ~gl.Program(0)
TEXTURE_INVALID      :: Texture{ handle = ~gl.Texture(0) }
BUFFER_INVALID       :: ~gl.Buffer(0)
FRAMEBUFFER_INVALID  :: ~gl.Framebuffer(0)
RENDERBUFFER_INVALID :: ~gl.Renderbuffer(0)

@(private="file", rodata)
texture_filter_map := [Texture_Filter]i32{
        .Linear = i32(gl.LINEAR),
        .Nearest = i32(gl.NEAREST),
}

@(private="file", rodata)
texture_wrap_map := [Texture_Wrap]i32{
	.Clamp_To_Edge   = i32(gl.CLAMP_TO_EDGE),
	.Repeat          = i32(gl.REPEAT),
	.Mirrored_Repeat = i32(gl.MIRRORED_REPEAT),
}

load_extensions :: proc(id := "game") {
    gl.SetCurrentContextById(id)
}

platform_init :: proc(vert_src: string, frag_src: string) -> (ok: bool) {
    //gl.GenVertexArrays(1, &OG.vao)
    OG.vao = gl.CreateVertexArray()
    gl.BindVertexArray(OG.vao)

    shader := gl.CreateProgramFromStrings({vert_src}, {frag_src}) or_return
    OG.default_shader = Shader(shader)

    //gl.GenBuffers(1, &OG.vertex_buffer)
    OG.vertex_buffer = gl.CreateBuffer()
    gl.BindBuffer(gl.ARRAY_BUFFER, OG.vertex_buffer)
    gl.BufferData(gl.ARRAY_BUFFER, len(OG.vertices) * size_of(OG.vertices[0]), nil, gl.DYNAMIC_DRAW)

    return true
}

@(require_results)
platform_texture_load_from_img :: proc(img: ^image.Image, opts: Texture_Options) -> (tex: Texture, ok: bool) {
    //gl.GenTextures(1, &tex.handle)
    tex.handle = gl.CreateTexture()

    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)

    gl.BindTexture(gl.TEXTURE_2D, tex.handle)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, texture_filter_map[opts.filter])
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, texture_filter_map[opts.filter])

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, texture_wrap_map[opts.wrap[0]])
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, texture_wrap_map[opts.wrap[1]])

    img_bytes := bytes.buffer_to_bytes(&img.pixels)

    if img.channels == 4 {
        gl.TexImage2DSlice(gl.TEXTURE_2D, 0, gl.RGBA, i32(img.width), i32(img.height), 0, gl.RGBA, gl.UNSIGNED_BYTE, img_bytes[:])
    } else {
        gl.TexImage2DSlice(gl.TEXTURE_2D, 0, gl.RGB, i32(img.width), i32(img.height), 0, gl.RGB, gl.UNSIGNED_BYTE, img_bytes[:])
    }

    gl.BindTexture(gl.TEXTURE_2D, 0)

    tex.width = i32(img.width)
    tex.height = i32(img.height)

    return tex, true
}

platform_texture_unload :: proc(tex: Texture) {
    t := tex.handle
    gl.DeleteTexture(t)
}

platform_shader_load :: proc(vert_src := shader_vert, frag_src := shader_frag) -> (Shader, bool) {
    return gl.CreateProgramFromStrings({vert_src}, {frag_src})
}

platform_shader_unload :: proc(shader: Shader) {
    gl.DeleteProgram(shader)
}

platform_render_texture_load :: proc(width, height: i32) -> (target: Render_Texture) {
    //target.id = gl.Gen
    //gl.GenFramebuffers(1, &target.id)
    target.id = gl.CreateFramebuffer()
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

    if target.id > 0 {
        gl.BindFramebuffer(gl.FRAMEBUFFER, target.id)
        defer gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

        // generate texture ID
        //gl.GenTextures(1, &target.texture_id)
        target.texture_id = gl.CreateTexture()
        gl.BindTexture(gl.TEXTURE_2D, target.texture_id)
        defer gl.BindTexture(gl.TEXTURE_2D, 0);
        //gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, 0)
        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, 0, nil)
        //gl.TexImage2D(target: Enum, level: i32, internalformat: Enum, width, height: i32, border: i32, format, type: Enum, size: int, data: rawptr)

        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, i32(gl.LINEAR))
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, i32(gl.LINEAR))

        // generate depth id
        //gl.GenRenderbuffers(1, &target.depth_id);
        target.depth_id = gl.CreateRenderbuffer()
        gl.BindRenderbuffer(gl.RENDERBUFFER, target.depth_id);
        defer gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
        gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT24, width, height);
        //gl.BindRenderBuffer(gl.RENDERBUFFER, 0)

        //gl.BindFramebuffer(gl.FRAMEBUFFER, target.id)
        //defer gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
        gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, target.texture_id, 0)

        //gl.BindFramebuffer(gl.FRAMEBUFFER, target.id)
        gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, target.depth_id)

        target.width = width
        target.height = height
    }
    return
}

@(require_results)
platform_draw :: proc() -> bool {
    enable_shader_state :: proc(shader: Shader, camera: Camera, width, height: i32) -> (mvp: glm.mat4) {
        gl.UseProgram(shader)

        gl.EnableVertexAttribArray(0)
        gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))

        gl.EnableVertexAttribArray(1)
        gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))

        gl.EnableVertexAttribArray(2)
        gl.VertexAttribPointer(2, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, texcoord))

        proj := glm.mat4Ortho3d(0, f32(width), f32(height), 0, camera.near, camera.far)
        origin := glm.mat4Translate({-camera.target.x, -camera.target.y, 0})
        rotation := glm.mat4Rotate({0, 0, 1}, camera.rotation)
        scale := glm.mat4Scale({camera.zoom, camera.zoom, 1})
        translation := glm.mat4Translate({camera.offset.x, camera.offset.y, 0})

        view := origin * scale * rotation * translation
        mvp = proj * view

        gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "camera"), mvp)
        gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "view"), view)
        gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "projection"), proj)

        gl.Uniform1i(gl.GetUniformLocation(shader, "texture0"), 0)

        return
    }

    gl.BindVertexArray(OG.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, OG.vertex_buffer)
    gl.BufferData(gl.ARRAY_BUFFER, len(OG.vertices) * size_of(OG.vertices[0]), raw_data(OG.vertices), gl.DYNAMIC_DRAW)

    width, height := i32(OG.fb_width), i32(OG.fb_height)

    gl.Viewport(0, 0, width, height)
    gl.ClearColor(OG.clear_color.r, OG.clear_color.g, OG.clear_color.b, OG.clear_color.a)
    gl.Disable(gl.DEPTH_TEST)
    gl.Enable(gl.BLEND)
    gl.Enable(gl.CULL_FACE)
    gl.CullFace(gl.BACK)
    gl.FrontFace(gl.CW)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.Clear(u32(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT))

    prev_draw_call: Draw_Call
    prev_draw_call.shader  = SHADER_INVALID
    prev_draw_call.texture = TEXTURE_INVALID
    mvp: glm.mat4

    draw_call_loop: for dc in OG.draw_calls {
        defer prev_draw_call = dc

        if prev_draw_call.depth_test != dc.depth_test {
            if dc.depth_test {
                gl.Enable(gl.DEPTH_TEST)
            } else {
                gl.Disable(gl.DEPTH_TEST)
            }
        }

        if prev_draw_call.texture != dc.texture {
            gl.ActiveTexture(gl.TEXTURE0)
            gl.BindTexture(gl.TEXTURE_2D, dc.texture.handle)
        }

        if prev_draw_call.shader != dc.shader {
            mvp = enable_shader_state(dc.shader, OG.camera, width, height)
        }

        if prev_draw_call.clip_rect != dc.clip_rect {
            if r, ok := dc.clip_rect.?; ok {
                gl.Enable(gl.SCISSOR_TEST)
                //a := r.pos
                //b := r.pos + r.size

                //a.x = clamp(a.x, 0, f32(OG.fb_width  - 1))
                //a.y = clamp(a.y, 0, f32(OG.fb_height - 1))

                //b.x = clamp(b.x, 0, f32(OG.fb_width  - 1))
                //b.y = clamp(b.y, 0, f32(OG.fb_height - 1))

                //w := i32(b.x - a.x)
                //h := i32(b.y - a.y)

                //if w <= 0 || h <= 0 {
                //    continue draw_call_loop
                //}
                x := i32(r.pos.x)
                y := i32(r.pos.y)
                w := i32(r.size.x)
                h := i32(r.size.y)

                //gl.Scissor(i32(a.x), i32(f32(OG.fb_height - 1) - a.y), w, h)
                gl.Scissor(x, OG.fb_height - (y + h), w, h)
            } else {
                gl.Disable(gl.SCISSOR_TEST)
            }
        }

        if prev_draw_call.render_texture != dc.render_texture {
            if target, ok := dc.render_texture.?; ok {
                gl.BindFramebuffer(gl.FRAMEBUFFER, target.id)
                gl.Viewport(0, 0, target.width, target.height)

                enable_shader_state(dc.shader, OG.camera, target.width, target.height)

                //if dc.length == 0 do continue draw_call_loop

            } else {
                gl.Viewport(0, 0, width, height)
                gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
            }
        }

        if dc.length == 0 do continue draw_call_loop

        gl.DrawArrays(gl.TRIANGLES, dc.offset, dc.length)
    }

    gl.UseProgram(0)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, 0)

    return true
}

shader_vert :: `#version 300 es
precision highp float;

layout (location = 0) in vec3 vertexPosition;
layout (location = 1) in vec4 vertexColor;
layout (location = 2) in vec2 vertexTexCoord;

out vec2 fragTexCoord;
out vec4 fragColor;

uniform mat4 camera;
uniform mat4 view;
uniform mat4 projection;

void main() {
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    gl_Position = camera*vec4(vertexPosition, 1.0);
}
`

shader_frag :: `#version 300 es
precision highp float;

in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;

uniform sampler2D texture0;

void main() {
    vec4 texelColor = texture(texture0, fragTexCoord);
    finalColor = texelColor * fragColor;
}
`

// --- gl bindings ---

UseProgram         :: gl.UseProgram
GetUniformLocation :: gl.GetUniformLocation

Uniform1f        :: gl.Uniform1f
Uniform2f        :: gl.Uniform2f
Uniform3f        :: gl.Uniform3f
Uniform4f        :: gl.Uniform4f
Uniform1i        :: gl.Uniform1i
Uniform2i        :: gl.Uniform2i
Uniform3i        :: gl.Uniform3i
Uniform4i        :: gl.Uniform4i
Uniform1fv       :: gl.Uniform1fv
Uniform2fv       :: gl.Uniform2fv
Uniform3fv       :: gl.Uniform3fv
Uniform4fv       :: gl.Uniform4fv
Uniform1iv       :: gl.Uniform1iv
Uniform2iv       :: gl.Uniform2iv
Uniform3iv       :: gl.Uniform3iv
Uniform4iv       :: gl.Uniform4iv
UniformMatrix2fv :: gl.UniformMatrix2fv
UniformMatrix3fv :: gl.UniformMatrix3fv
UniformMatrix4fv :: gl.UniformMatrix4fv
