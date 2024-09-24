
stbi_load_from_memory :: (buffer: *u8, len: s32, x: *s32, y: *s32, channels_in_file: *s32, desired_channels: s32) -> *u8 #foreign;
stbi_image_free :: (retval_from_stbi_load: *void) -> void #foreign;
