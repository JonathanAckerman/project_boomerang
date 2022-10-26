FONTS_PATH :: "C:/jai/sandbox/project_boomerang/assets/fonts";

Fonts: struct {
    using table: Table(string, Font);
}

load_all_fonts :: () {
    font_files: [..] string;
    visit_files(FONTS_PATH, false, *font_files, get_fonts, true, false);

    for font_files {
        value := it;
        success, path, key := split_from_left(it, tprint("%/", FONTS_PATH));
        if success {
            key.count -= 4;
            table_add(*Fonts.table, key, LoadFont(temp_c_string(value)));
        }
    }
}

get_fonts :: (info: *File_Visit_Info, data: *[..] string) {
    array_add(data, copy_string(info.full_name));
}