package sirenuse

import ma "vendor:miniaudio"
import    "core:sync"
import    "core:fmt"
import    "core:mem"

AUDIO_DEVICE_CHANNELS    :: u32(2)
AUDIO_DEVICE_SAMPLE_RATE :: u32(44100)
AUDIO_DEVICE_FORMAT      :: ma.format.f32

Id :: distinct int

Audio_Buffer :: struct {
    type: union {
        ma.decoder,
        ma.audio_buffer_ref,
    },
    loop: b32,
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

init :: proc() {
    config := ma.device_config_init(.playback)
    config.playback.format = AUDIO_DEVICE_FORMAT
    config.playback.channels = AUDIO_DEVICE_CHANNELS
    config.sampleRate = AUDIO_DEVICE_SAMPLE_RATE
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

load_sound :: proc(file: cstring) -> Id {
    config := ma.decoder_config_init(AUDIO_DEVICE_FORMAT, AUDIO_DEVICE_CHANNELS, AUDIO_DEVICE_SAMPLE_RATE)
    sound_decoder: ma.decoder
    if ma.decoder_init_file(file, &config, &sound_decoder) != .SUCCESS {
        fmt.panicf("Failed to open the file %s", file)
    }

    frame_count: u64
    ma.decoder_get_length_in_pcm_frames(&sound_decoder, &frame_count)

    audio_buffer: Audio_Buffer

    buffer_size := u32(frame_count) * sound_decoder.outputChannels
    buffer := make([]f32, buffer_size)

    ma.decoder_read_pcm_frames(&sound_decoder, raw_data(buffer), frame_count, nil)
    ma.decoder_uninit(&sound_decoder)

    audio_buffer.type = ma.audio_buffer_ref{}
    ma.audio_buffer_ref_init(.f32, 2, raw_data(buffer), frame_count, &audio_buffer.type.(ma.audio_buffer_ref))

    append(&AUDIO.buffers, audio_buffer)

    return Id(len(AUDIO.buffers) - 1)
}

load_music :: proc(file: cstring) -> Id {
    config := ma.decoder_config_init(AUDIO_DEVICE_FORMAT, AUDIO_DEVICE_CHANNELS, AUDIO_DEVICE_SAMPLE_RATE)

    audio_buffer: Audio_Buffer
    audio_buffer.type = ma.decoder{}
    if ma.decoder_init_file(file, &config, &audio_buffer.type.(ma.decoder)) != .SUCCESS {
        fmt.panicf("Failed to open the file %s", file)
    }
    append(&AUDIO.buffers, audio_buffer)

    return Id(len(AUDIO.buffers) - 1)
}

@(private)
data_callback :: proc(device: ^ma.device, output, input: rawptr, frame_count: u64) {
    sync.mutex_lock(&AUDIO.mutex)
    defer sync.mutex_unlock(&AUDIO.mutex)

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

                if frames_read < frame_count {
                    if buffer.loop {
                        ma.decoder_seek_to_pcm_frame(&data, 0)
                    } else {
                        buffer.is_playing = false
                    }
                }
            }
        case ma.audio_buffer_ref:
            if buffer.is_playing {
                frames_read: u64
                out: [1024 * AUDIO_DEVICE_CHANNELS]f32
                ma.audio_buffer_ref_read_pcm_frames(&data, raw_data(out[:]), frame_count, buffer.loop)

                output := mem.slice_ptr(cast([^]f32)(output), int(u32(frame_count) * device.playback.channels))
                for f in 0..<(u32(frame_count) * device.playback.channels) {
                    output[f] += out[f]
                }

                available_frames: u64
                ma.audio_buffer_ref_get_available_frames(&data, &available_frames)
                if available_frames < frame_count && !buffer.loop {
                    buffer.is_playing = false
                }
            }
        }
    }
}

play_sound :: proc(id: Id) {
    if audio_buffer, ok := &AUDIO.buffers[id].type.(ma.audio_buffer_ref); ok {
        sync.mutex_lock(&AUDIO.mutex)
        defer sync.mutex_unlock(&AUDIO.mutex)

        AUDIO.buffers[id].is_playing = true
        ma.audio_buffer_ref_seek_to_pcm_frame(audio_buffer, 0)
    } else {
        fmt.eprintln("it's not a sound id")
    }
}

play_music :: proc(id: Id) {
    if decoder, ok := &AUDIO.buffers[id].type.(ma.decoder); ok {
        sync.mutex_lock(&AUDIO.mutex)
        defer sync.mutex_unlock(&AUDIO.mutex)

        AUDIO.buffers[id].is_playing = true
        ma.decoder_seek_to_pcm_frame(decoder, 0)
    } else {
        fmt.eprintln("it's not a music id")
    }
}

close :: proc() {
    if AUDIO.is_ready {
        AUDIO.is_ready = false
        for &buffer in AUDIO.buffers {
            switch &data in buffer.type {
            case ma.decoder:
                ma.decoder_uninit(&data)
            case ma.audio_buffer_ref:
                free(data.pData)
                ma.audio_buffer_ref_uninit(&data)
            }
        }
        delete(AUDIO.buffers)
        ma.device_uninit(&AUDIO.device)
    } else {
        panic("AUDIO: Device could not be closed, not currently initialized")
    }
}
