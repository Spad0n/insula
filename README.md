# Insula
Insula is a framework written in [Odin](https://odin-lang.org) (a C-like programming language) designed for 2D game development and graphical applications. It provide
modular libraries for OpenGL/WebGL rendering, audio abstraction, window management, and 2D physics, making a powerful and flexible tool for developpers.


⚠️ Note: Insula is currently a work in progress. While some features are functional, others are still under development. See below for details.


## Feature
- **Built from scratch**: inspired by [Crow2D](https://github.com/gingerBill/crow2d/), [Raylib](https://github.com/raysan5/raylib) and [Love2D](https://www.love2d.org/)
- **Highly modular**: Insula is being designed to allow developers to replace its core libraries with alternative solutions, enabling full customization

## Default Libraries

Insula includes the following libraries by default:
- **Ogygia**: Handles 2D rendering using OpenGL/WebGL.
  - 🚧 Missing features: Certain OpenGL bindings (e.g., framebuffer support) are not yet implemented
- **Avalon**: Manage window creation and handling.
  - 🚧 Missing features: Gamepad support is not yet available.
- **Sirenuse**: Provides audio processing and playback.
  - 🚧 Status: Basic implementation.
  
## Getting Started

Here's a simple example of how to use Insula to create a window and render basic shape:
```odin
package main

import ins "insula"
import     "core:fmt"

SCREEN_WIDTH  :: 800
SCREEN_HEIGHT :: 600

fini :: proc(ctx: ^ins.Context) {
    ins.render_destroy()
}

update :: proc(ctx: ^ins.Context, dt: f32) {
    ins.draw_rect({10, 10}, {100, 100}, color = ins.RED)
    ins.draw_all()
}

init :: proc(ctx: ^ins.Context) -> bool {
    when ODIN_OS != .JS {
        ins.load_extensions(ins.gl_set_proc_address)
    } else {
        ins.load_extensions("game")
    }
	
    if !ins.render_init(ctx.screen_width, ctx.screen_height) {
        fmt.eprintln("Could not init GL context for some reason")
        return false
    }

    ins.set_background(ins.WHITE)
    return true
}

main :: proc() {
    if !ins.init(SCREEN_WIDTH, SCREEN_HEIGHT, "Hello world", init, update, fini) {
        panic("Something went wrong")
    }
    ins.start()
}
```

## Demonstrations

To see Insula in action, you can try our online game demo:
- [Spacebattle](https://spad0n.github.io/avalon-demo): A port of my game Spacebattle, originally written in C using SDL2, now powered by Insula.

## Roadmap
Here are the planned steps for the project's development:
1. Add missing OpenGL/WebGL bindings in Ogygia
2. implement gamepad support in Avalon
3. Develop and integrate the audio system for both desktop and Web (Sirenuse)
4. Expand documentation and create tutorials

