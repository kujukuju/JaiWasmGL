
file_exists :: (file_path: string) -> bool {
    return file_exists_wasm(file_path.data, file_path.count);
}
