package insula

import og "ogygia"

// Types
Texture    :: og.Texture
Color      :: og.Color

LIGHTGRAY  :: og.LIGHTGRAY
GRAY       :: og.GRAY
DARKGRAY   :: og.DARKGRAY
YELLOW     :: og.YELLOW
GOLD       :: og.GOLD
ORANGE     :: og.ORANGE
PINK       :: og.PINK
RED        :: og.RED
MAROON     :: og.MAROON
GREEN      :: og.GREEN
LIME       :: og.LIME
DARKGREEN  :: og.DARKGREEN
SKYBLUE    :: og.SKYBLUE
BLUE       :: og.BLUE
DARKBLUE   :: og.DARKBLUE
PURPLE     :: og.PURPLE
VIOLET     :: og.VIOLET
DARKPURPLE :: og.DARKPURPLE
BEIGE      :: og.BEIGE
BROWN      :: og.BROWN
DARKBROWN  :: og.DARKBROWN

WHITE      :: og.WHITE
BLACK      :: og.BLACK
BLANK      :: og.BLANK
MAGENTA    :: og.MAGENTA
RAYWHITE   :: og.RAYWHITE

// platform
load_extensions     :: og.load_extensions

// texture.odin
texture_load_from_image :: og.texture_load_from_image

// render
render_init    :: og.init
render_destroy :: og.destroy
texture_unload :: og.texture_unload

// draw.odin
set_background :: og.set_background
set_texture    :: og.set_texture
set_shader     :: og.set_shader
set_depth_test :: og.set_depth_test
set_clip_rect  :: og.set_clip_rect
draw_all       :: og.draw_all
draw_rect      :: og.draw_rect

// gl bindings
UseProgram         :: og.UseProgram
GetUniformLocation :: og.GetUniformLocation

Uniform1f        :: og.Uniform1f
Uniform2f        :: og.Uniform2f
Uniform3f        :: og.Uniform3f
Uniform4f        :: og.Uniform4f
Uniform1i        :: og.Uniform1i
Uniform2i        :: og.Uniform2i
Uniform3i        :: og.Uniform3i
Uniform4i        :: og.Uniform4i
Uniform1fv       :: og.Uniform1fv
Uniform2fv       :: og.Uniform2fv
Uniform3fv       :: og.Uniform3fv
Uniform4fv       :: og.Uniform4fv
Uniform1iv       :: og.Uniform1iv
Uniform2iv       :: og.Uniform2iv
Uniform3iv       :: og.Uniform3iv
Uniform4iv       :: og.Uniform4iv
UniformMatrix2fv :: og.UniformMatrix2fv
UniformMatrix3fv :: og.UniformMatrix3fv
UniformMatrix4fv :: og.UniformMatrix4fv
