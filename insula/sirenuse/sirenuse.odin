#+build !js
package sirenuse

import    "base:runtime"
import ma "vendor:miniaudio"
import    "core:mem"
import    "core:fmt"
//import    "core:c/libc"

AUDIO_DEVICE_FORMAT      :: ma.format.f32
AUDIO_DEVICE_CHANNELS    :: 2
AUDIO_DEVICE_SAMPLE_RATE :: 48000

Audio_Buffer :: struct {
    //buffer: ma.audio_buffer,
    buffer: ma.decoder,
    volume: f32,
    pan: f32,
    pitch: f32,
    playing: bool,
    paused: bool,
    frame_cursor_pos: uint,
    next: ^Audio_Buffer,
    prev: ^Audio_Buffer
}

Audio_Data :: struct {
    system: struct {
        device: ma.device,
        lock: ma.mutex,
        is_ready: bool,
    },
    buffer: struct {
        first: ^Audio_Buffer,
        last: ^Audio_Buffer,
    }
}

ctx: Audio_Data

read_and_mix_pcm_frames_f32 :: proc(decoder: ^ma.decoder, output_f32: [^]f32, frame_count: u32) -> u32 {
    temp: [4096]f32
    temp_cap_in_frames : u32 = len(temp) / AUDIO_DEVICE_CHANNELS
    total_frames_read : u32 = 0

    for total_frames_read < frame_count {
        frames_read_this_iteration: u64
        total_frames_remaining := frame_count - total_frames_read
        frames_to_read_this_iteration := temp_cap_in_frames

        if frames_to_read_this_iteration > total_frames_remaining {
            frames_to_read_this_iteration = total_frames_remaining
        }

        if ma.decoder_read_pcm_frames(decoder, &temp[0], u64(frames_to_read_this_iteration), &frames_read_this_iteration) != .SUCCESS || frames_read_this_iteration == 0 {
            break
        }
        //if frames_read_this_iteration == 0 do break
        //ma.audio_buffer_read_pcm_frames(audio, &temp[0], u64(frames_to_read_this_iteration), false)

        // Mix the frames together
        for isample in 0..<frames_read_this_iteration * AUDIO_DEVICE_CHANNELS {
            output_f32[total_frames_read * AUDIO_DEVICE_CHANNELS + u32(isample)] += temp[isample]
        }

        total_frames_read += u32(frames_read_this_iteration)

        if frames_read_this_iteration < u64(frames_to_read_this_iteration) {
            break
        }
    }
    return total_frames_read
}

data_callback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, frame_count: u32) {
    context = runtime.default_context()
    output_f32 := cast([^]f32)(output)

    ma.mutex_lock(&ctx.system.lock)
    defer ma.mutex_unlock(&ctx.system.lock)

    for audio_buffer := ctx.buffer.first; audio_buffer != nil; audio_buffer = audio_buffer.next {
        if (!audio_buffer.playing || audio_buffer.paused) do continue
        
        frames_read := read_and_mix_pcm_frames_f32(&audio_buffer.buffer, output_f32, frame_count)
        if frames_read < frame_count {
            audio_buffer.paused = true
        }
    }
}

init :: proc() {
    config := ma.device_config_init(.playback)
    config.playback.format = AUDIO_DEVICE_FORMAT
    config.playback.channels = AUDIO_DEVICE_CHANNELS
    config.sampleRate = AUDIO_DEVICE_SAMPLE_RATE
    config.dataCallback = data_callback
    config.pUserData = nil

    if ma.device_init(nil, &config, &ctx.system.device) != .SUCCESS {
        panic("Failed to initialize playback device")
    }

    if ma.device_start(&ctx.system.device) != .SUCCESS {
        panic("Failed to start playback device")
    }

    if ma.mutex_init(&ctx.system.lock) != .SUCCESS {
        panic("Failed to create mutex for mixing")
    }
}

destroy :: proc() {
    if ctx.system.is_ready {
        ma.mutex_uninit(&ctx.system.lock)
        ma.device_uninit(&ctx.system.device)

        ctx.system.is_ready = false
    }
    for ctx.buffer.first != nil {
        tmp := ctx.buffer.first
        ctx.buffer.first = ctx.buffer.first.next
        ma.decoder_uninit(&tmp.buffer)
        free(tmp)
    }
}

load_sound :: proc(filename: cstring) -> ^Audio_Buffer {
    decoder_config := ma.decoder_config_init(AUDIO_DEVICE_FORMAT, AUDIO_DEVICE_CHANNELS, AUDIO_DEVICE_SAMPLE_RATE)

    audio_node := new(Audio_Buffer)
    if ma.decoder_init_file(filename, &decoder_config, &audio_node.buffer) != .SUCCESS {
        fmt.panicf("Failed to load: %s\n", filename)
    }

    audio_node.volume = 1
    audio_node.pitch = 1
    audio_node.pan = 0.5

    if ctx.buffer.first == nil {
        ctx.buffer.first = audio_node
        ctx.buffer.last = audio_node
    } else {
        ctx.buffer.last.next = audio_node
        audio_node.prev = ctx.buffer.last
        ctx.buffer.last = audio_node
    }

    return audio_node
}

play_sound :: proc(audio_buffer: ^Audio_Buffer) {
    audio_buffer.playing = true
    audio_buffer.paused = false
    audio_buffer.frame_cursor_pos = 0
    ma.decoder_seek_to_pcm_frame(&audio_buffer.buffer, 0)
}

//Audio_Buffer_Usage :: enum {
//    Static,
//    Stream,
//}
//
//Audio_Buffer :: struct {
//    playing: bool,
//    paused: bool,
//    frame_cursor_pos: uint,
//    decoder: ma.decoder,
//    next: ^Audio_Buffer,
//    prev: ^Audio_Buffer,
//}
//
//Audio_Data :: struct {
//    device: ma.device,
//    lock: ma.mutex,
//    is_ready: bool,
//    first: ^Audio_Buffer,
//    last: ^Audio_Buffer,
//    default_size: int,
//}
//
//ctx: Audio_Data
//
//read_and_mix_pcm_frames_f32 :: proc(decoder: ^ma.decoder, output_f32: [^]f32, frame_count: u32) -> u32 {
//    temp: [4096]f32
//    temp_cap_in_frames : u32 = len(temp) / AUDIO_DEVICE_CHANNELS
//    total_frames_read : u32 = 0
//
//    for total_frames_read < frame_count {
//        frames_read_this_iteration: u64
//        total_frames_remaining := frame_count - total_frames_read
//        frames_to_read_this_iteration := temp_cap_in_frames
//
//        if frames_to_read_this_iteration > total_frames_remaining {
//            frames_to_read_this_iteration = total_frames_remaining
//        }
//
//        if ma.decoder_read_pcm_frames(decoder, &temp[0], u64(frames_to_read_this_iteration), &frames_read_this_iteration) != .SUCCESS || frames_read_this_iteration == 0 {
//            break
//        }
//
//        // Mix the frames together
//        for isample in 0..<frames_read_this_iteration * AUDIO_DEVICE_CHANNELS {
//            output_f32[total_frames_read * AUDIO_DEVICE_CHANNELS + u32(isample)] += temp[isample]
//        }
//
//        total_frames_read += u32(frames_read_this_iteration)
//
//        if frames_read_this_iteration < u64(frames_to_read_this_iteration) {
//            break
//        }
//    }
//    return total_frames_read
//}
//
//data_callback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, frame_count: u32) {
//    context = runtime.default_context()
//
//    //mem.set(output, 0, frame_count * device.playback.channels * ma.get_bytes_per_sample(device.playback.format))
//    output_f32 := ([^]f32)(output)
//
//    ma.mutex_lock(&ctx.lock)
//    defer ma.mutex_unlock(&ctx.lock)
//
//    for audio_buffer := ctx.first; audio_buffer != nil; audio_buffer = audio_buffer.next {
//        if (!audio_buffer.playing || audio_buffer.paused) do continue
//        frames_read := read_and_mix_pcm_frames_f32(&audio_buffer.decoder, output_f32, frame_count)
//        if frames_read < frame_count {
//            audio_buffer.paused = true
//        }
//    }
//}
//
//init :: proc() {
//    config := ma.device_config_init(.playback)
//    config.playback.format = AUDIO_DEVICE_FORMAT
//    config.playback.channels = AUDIO_DEVICE_CHANNELS
//    config.capture.channels = 1
//    config.sampleRate = AUDIO_DEVICE_SAMPLE_RATE
//    config.dataCallback = data_callback
//    config.pUserData = nil
//
//    if ma.device_init(nil, &config, &ctx.device) != .SUCCESS {
//        panic("Failed to initialize playback device")
//    }
//
//    if ma.device_start(&ctx.device) != .SUCCESS {
//        panic("Failed to start playback device")
//    }
//
//    if ma.mutex_init(&ctx.lock) != .SUCCESS {
//        panic("Failed to create mutex for mixing")
//    }
//
//    ctx.first = new(Audio_Buffer)
//    ctx.first.next = new(Audio_Buffer)
//    ctx.last = ctx.first.next
//
//    decoder_config := ma.decoder_config_init(AUDIO_DEVICE_FORMAT, AUDIO_DEVICE_CHANNELS, AUDIO_DEVICE_SAMPLE_RATE)
//    if ma.decoder_init_file("Laser1.wav", &decoder_config, &ctx.first.decoder) != .SUCCESS {
//        panic("Failed to load Laser1.wav")
//    }
//
//    if ma.decoder_init_file("OrbitalColossus.mp3", &decoder_config, &ctx.last.decoder) != .SUCCESS {
//        panic("Failed to load OrbitalColossus.mp3")
//    }
//
//    ctx.last.playing = true
//    ctx.last.paused = false
//    ctx.last.frame_cursor_pos = 0
//
//    ctx.is_ready = true
//}
//
//destroy :: proc() {
//    if ctx.is_ready {
//        ma.mutex_uninit(&ctx.lock)
//        ma.device_uninit(&ctx.device)
//
//        ctx.is_ready = false
//    }
//    for audio_buffer := ctx.first; audio_buffer != nil; audio_buffer = audio_buffer.next {
//        free(audio_buffer)
//    }
//}
//
//is_audio_device_ready :: proc() -> bool {
//    return ctx.is_ready
//}
//
//set_master_volume :: proc(volume: f32) {
//    ma.device_set_master_volume(&ctx.device, volume)
//}
//
//play_sound :: proc() {
//    ctx.first.playing = true
//    ctx.first.paused = false
//    ctx.first.frame_cursor_pos = 0
//    ma.decoder_seek_to_pcm_frame(&ctx.first.decoder, 0)
//}
