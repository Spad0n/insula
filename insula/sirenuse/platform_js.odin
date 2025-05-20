package sirenuse

Id :: distinct int

init :: proc() {}

load_sound :: proc(file: cstring) {}

load_music :: proc(file: cstring) {}

play_sound :: proc(id: Id) {}

play_music :: proc(id: Id) {}

close :: proc() {}
