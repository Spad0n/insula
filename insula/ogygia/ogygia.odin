package ogygia

//import gl  "vendor:OpenGL"
import glm "core:math/linalg/glsl"

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

Vertex :: struct {
    pos: glm.vec3,
    color: glm.vec4,
    texcoord: glm.vec2,
}

Clip_Rect :: struct {
    pos: glm.vec2,
    size: glm.vec2,
}

Draw_Call :: struct {
    shader: Shader,
    texture: Texture,
    depth_test: bool,
    clip_rect: Maybe(Clip_Rect),
    render_texture: Maybe(Render_Texture),
    offset: int,
    length: int,
}

Camera :: struct {
    offset: glm.vec2,
    target: glm.vec2,
    rotation: f32,
    zoom: f32,
    near: f32,
    far: f32,
}

Camera_Default :: Camera{
    zoom = 1,
    near = -1024,
    far  = +1024,
}

Draw_State :: struct {
    camera:     Camera,
    vertices:   [dynamic]Vertex,
    draw_calls: [dynamic]Draw_Call,
}

Render_Data :: struct {
    using draw_state: Draw_State,
    fb_width: i32,
    fb_height: i32,
    curr_z: f32,
    clear_color: glm.vec4,

    default_shader: Shader,
    default_texture: Texture,
    vertex_buffer: Buffer,

    //projection: glm.mat4,
    //modelview: glm.mat4,

    vao: VertexArrayObject,
}

OG: Render_Data

//load_extensions :: proc(set_proc_address: proc(p: rawptr, name: cstring)) {
//    gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, set_proc_address)
//}

init :: proc(width, height: i32, vert_src := shader_vert, frag_src := shader_frag) -> bool {
    OG.fb_width = width
    OG.fb_height = height

    OG.camera = Camera_Default
    reserve(&OG.vertices, 1 << 20)
    reserve(&OG.draw_calls, 1 << 12)

    // openGL initialisation
    //gl.GenVertexArrays(1, &OG.vao)
    //gl.BindVertexArray(OG.vao)

    //shader := gl.load_shaders_source(vert_src, frag_src) or_return
    //OG.default_shader = Shader(shader)

    //gl.GenBuffers(1, &OG.vertex_buffer)
    //gl.BindBuffer(gl.ARRAY_BUFFER, OG.vertex_buffer)
    //gl.BufferData(gl.ARRAY_BUFFER, len(OG.vertices) * size_of(OG.vertices[0]), nil, gl.DYNAMIC_DRAW)

    platform_init(vert_src, frag_src)

    OG.default_texture = texture_load_default_white() or_return

    return true
}

destroy :: proc() {
    delete(OG.vertices)
    delete(OG.draw_calls)
}
