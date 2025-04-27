package sirenuse

import ma "vendor:miniaudio"
import    "core:sync"
import    "core:fmt"
import    "core:mem"

AUDIO_DEVICE_CHANNELS    : u32       : 2
AUDIO_DEVICE_SAMPLE_RATE : u32       : 44100
AUDIO_DEVICE_FORMAT      : ma.format : .f32


//Audio_Buffer :: struct {
//    decoder: ma.decoder,
//    paused: bool,
//    looping: bool,
//}
//
//AudioData :: struct {
//    device: ma.device,
//    buffer: Audio_Buffer,
//    is_ready: bool,
//    lock: sync.Mutex
//}
//
//@(private) AUDIO: AudioData
//
//data_callback :: proc(device: ^ma.device, output, input: rawptr, frame_count: u64) {
//    sync.mutex_lock(&AUDIO.lock)
//    {
//        if (AUDIO.buffer.paused) do return
//
//        frames_read: u64
//
//        ma.decoder_read_pcm_frames(&AUDIO.buffer.decoder, output, frame_count, &frames_read)
//
//        // check if need to be looped
//        if frames_read < frame_count && AUDIO.buffer.looping {
//            ma.decoder_seek_to_pcm_frame(&AUDIO.buffer.decoder, 0)
//        }
//    }
//    sync.mutex_unlock(&AUDIO.lock)
//}
//
//init :: proc(file_path: cstring) {
//    // decoder part
//    if ma.decoder_init_file(file_path, nil, &AUDIO.buffer.decoder) != .SUCCESS {
//        panic("Could not load file")
//    }
//
//    // device part
//    config := ma.device_config_init(.playback)
//    config.playback.format = AUDIO_DEVICE_FORMAT
//    config.playback.channels = AUDIO_DEVICE_CHANNELS
//    config.sampleRate = AUDIO_DEVICE_SAMPLE_RATE
//    config.dataCallback = ma.device_data_proc(data_callback)
//
//    if ma.device_init(nil, &config, &AUDIO.device) != .SUCCESS {
//        panic("AUDIO: Failed to initialize playback device")
//    }
//
//    if ma.device_start(&AUDIO.device) != .SUCCESS {
//        panic("AUDIO: Failed to start playback device")
//    }
//
//    AUDIO.is_ready = true
//    AUDIO.buffer.looping = true
//}
//
//close :: proc() {
//    if AUDIO.is_ready {
//        AUDIO.is_ready = false
//        ma.device_uninit(&AUDIO.device)
//        ma.decoder_uninit(&AUDIO.buffer.decoder)
//    } else {
//        panic("AUDIO: Device could not be closed, not currently initialized")
//    }
//}
//
//set_master_volume :: proc(volume: f32) {
//    ma.device_set_master_volume(&AUDIO.device, volume)
//}
//
////toggle_pause :: proc() {
////    AUDIO.paused = !AUDIO.paused
////}
//lock :: proc() {
//    sync.mutex_lock(&AUDIO.lock)
//}
//
//unlock :: proc() {
//    sync.mutex_unlock(&AUDIO.lock)
//}
//
//stop_music_stream :: proc() {
//    AUDIO.buffer.paused = true
//    ma.decoder_seek_to_pcm_frame(&AUDIO.buffer.decoder, 0)
//}
//
//play_music_stream :: proc() {
//    AUDIO.buffer.paused = false
//}

Audio_Id :: distinct int

Audio_Buffer :: struct {
    type: union {
        ma.decoder,
        ma.audio_buffer_ref,
    },
    sound_data: []f32,
    sound_frame_count: u32,
    sound_cursor: u32,
    loop: bool,
    is_playing: bool,
    paused: bool,
}

Audio_Data :: struct {
    device: ma.device,
    buffers: [dynamic]Audio_Buffer,
    mutex: sync.Mutex,
    is_ready: bool
}

AUDIO: Audio_Data

init :: proc(format := AUDIO_DEVICE_FORMAT, channels := AUDIO_DEVICE_CHANNELS, sample_rate := AUDIO_DEVICE_SAMPLE_RATE) {
    config := ma.device_config_init(.playback)
    config.playback.format = format
    config.playback.channels = channels
    config.sampleRate = sample_rate
    config.dataCallback = ma.device_data_proc(data_callback)

    if ma.device_init(nil, &config, &AUDIO.device) != .SUCCESS {
        panic("AUDIO: Failed to initialize playback device")
    }

    if ma.device_start(&AUDIO.device) != .SUCCESS {
        panic("AUDIO: Failed to start playback device")
    }

    AUDIO.buffers = make([dynamic]Audio_Buffer)
    AUDIO.is_ready = true
}

load_sound :: proc(file: cstring) -> Audio_Id {
    config := ma.decoder_config_init(AUDIO_DEVICE_FORMAT, AUDIO_DEVICE_CHANNELS, AUDIO_DEVICE_SAMPLE_RATE)
    sound_decoder: ma.decoder
    if ma.decoder_init_file(file, &config, &sound_decoder) != .SUCCESS {
        fmt.panicf("Failed to open the file %s", file)
    }

    frame_count: u64
    ma.decoder_get_length_in_pcm_frames(&sound_decoder, &frame_count)

    audio_buffer: Audio_Buffer
    audio_buffer.sound_frame_count = u32(frame_count)

    buffer_size := audio_buffer.sound_frame_count * sound_decoder.outputChannels
    audio_buffer.sound_data = make([]f32, buffer_size)

    ma.decoder_read_pcm_frames(&sound_decoder, raw_data(audio_buffer.sound_data), u64(audio_buffer.sound_frame_count), nil)
    ma.decoder_uninit(&sound_decoder)

    audio_buffer.type = ma.audio_buffer_ref{}
    ma.audio_buffer_ref_init(.f32, 2, raw_data(audio_buffer.sound_data), u64(audio_buffer.sound_frame_count), &audio_buffer.type.(ma.audio_buffer_ref))

    append(&AUDIO.buffers, audio_buffer)

    return Audio_Id(len(AUDIO.buffers) - 1)
}

load_music :: proc(file: cstring) -> Audio_Id {
    config := ma.decoder_config_init(AUDIO_DEVICE_FORMAT, AUDIO_DEVICE_CHANNELS, AUDIO_DEVICE_SAMPLE_RATE)

    audio_buffer: Audio_Buffer
    audio_buffer.type = ma.decoder{}
    if ma.decoder_init_file(file, &config, &audio_buffer.type.(ma.decoder)) != .SUCCESS {
        fmt.panicf("Failed to open the file %s", file)
    }
    append(&AUDIO.buffers, audio_buffer)

    return Audio_Id(len(AUDIO.buffers) - 1)
}

data_callback :: proc(device: ^ma.device, output, input: rawptr, frame_count: u64) {
    sync.mutex_lock(&AUDIO.mutex)
    {
        for &buffer in AUDIO.buffers {
            switch &data in buffer.type {
            case ma.decoder:
                if buffer.is_playing {
                    frames_read: u64
                    out: [1024 * AUDIO_DEVICE_CHANNELS]f32
                    ma.decoder_read_pcm_frames(&data, raw_data(out[:]), frame_count, &frames_read)

                    output := mem.slice_ptr(cast([^]f32)(output), int(u32(frame_count) * device.playback.channels))
                    for f in 0..<(u32(frame_count) * device.playback.channels) {
                        output[f] += out[f]
                    }

                    if frames_read < frame_count && buffer.loop {
                        ma.decoder_seek_to_pcm_frame(&data, 0)
                    }
                }
            case ma.audio_buffer_ref:
                if buffer.is_playing {
                    frames_available := buffer.sound_frame_count - buffer.sound_cursor
                    frames_to_mix := u32(frame_count)
                    if frames_to_mix > frames_available {
                        frames_to_mix = frames_available
                    }

                    output := mem.slice_ptr(cast([^]f32)(output), int(frames_to_mix * device.playback.channels))
                    sound_data := buffer.sound_data[buffer.sound_cursor * device.playback.channels:]
                    for f in 0..<frames_to_mix * device.playback.channels {
                        output[f] += sound_data[f] * 0.5
                    }

                    buffer.sound_cursor += frames_to_mix
                    if buffer.sound_cursor >= buffer.sound_frame_count {
                        buffer.is_playing = false
                    }
                }
            }
        }
    }
    sync.mutex_unlock(&AUDIO.mutex)
}

play_sound :: proc(id: Audio_Id) {
    if _, ok := AUDIO.buffers[id].type.(ma.audio_buffer_ref); ok {
        sync.mutex_lock(&AUDIO.mutex)
        defer sync.mutex_unlock(&AUDIO.mutex)

        AUDIO.buffers[id].is_playing = true
        AUDIO.buffers[id].sound_cursor = 0
    } else {
        fmt.eprintln("it's not a sound id")
    }
}

play_music :: proc(id: Audio_Id) {
    if decoder, ok := AUDIO.buffers[id].type.(ma.decoder); ok {
        sync.mutex_lock(&AUDIO.mutex)
        defer sync.mutex_unlock(&AUDIO.mutex)

        AUDIO.buffers[id].is_playing = true
        ma.decoder_seek_to_pcm_frame(&decoder, 0)
    } else {
        fmt.eprintln("it's not a music id")
    }
}

close :: proc() {
    if AUDIO.is_ready {
        AUDIO.is_ready = false
        ma.device_uninit(&AUDIO.device)
        for &buffer in AUDIO.buffers {
            switch &data in buffer.type {
            case ma.decoder:
                ma.decoder_uninit(&data)
            case ma.audio_buffer_ref:
                delete(buffer.sound_data)
            }
        }
        delete(AUDIO.buffers)
    } else {
        panic("AUDIO: Device could not be closed, not currently initialized")
    }
}
