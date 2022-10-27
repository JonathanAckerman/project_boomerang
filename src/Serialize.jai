SERIALIZED_VERSION :: "[0] #version number\n\n";

// #run serialize_game();
serialize_game :: () {
    make_directory_if_it_does_not_exist("assets/serialized");
    write_entire_file("assets/serialized/map.data", SERIALIZED_VERSION);

    // handler: Text_File_Handler;
    // defer deinit(*handler);
    
    // filename :: "C:/jai/sandbox/project_boomerang/assets/serialized/map.data";
    // short_name :: "map";
    // start_file(*handler, short_name, filename);
    // if handler.failed {
    //     log_error("Error: serializer failed to parse map.data\n");
    //     return;
    // }
    
}