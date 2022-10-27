#insert #run _compile_fonts();

#scope_file // ---------------------------------------------------------------------------

#no_reset _fonts_path: string;
#run {
    sb: String_Builder; defer free_buffers(*sb);
    cwd := get_working_directory();
    replace_chars(cwd, "\\", #char "/");
    append(*sb, cwd);
    append(*sb, "/assets/fonts");
    _fonts_path = builder_to_string(*sb);
}

_font_table: Table(string, string);

_get_fonts :: (info: *File_Visit_Info, data: *[..] string) {
    array_add(data, copy_string(info.full_name));
}
// Fill the table in Fonts with (key=font_name, value=font_path)
_get_all_fonts :: () {
    font_files: [..] string;
    visit_files(_fonts_path, false, *font_files, _get_fonts, true, false);

    for font_files {
        value := it;
        success, path, key := split_from_left(it, tprint("%/", _fonts_path));
        if success {
            key.count -= 4;
            table_add(*_font_table, key, value);
        }
    }
}

_compile_fonts :: () -> string {
    _get_all_fonts(); // we'll do this again at runtime when we need to load the fonts
    sb: String_Builder; defer free_buffers(*sb);

    // generate the fonts struct
    print_to_builder(*sb, "fonts: struct {\n");
    for _font_table {
        print_to_builder(*sb, tprint("    %: Font;\n", it_index));
    }
    print_to_builder(*sb, "}\n\n");

    // generate the function which we call to load the fonts
    print_to_builder(*sb, "load_all_fonts :: () {\n");
    for _font_table {
        print_to_builder(*sb, tprint("    fonts.% = LoadFont(\"%\");\n", it_index, it));
    }
    print_to_builder(*sb, "}\n\n");

    return builder_to_string(*sb);
}
