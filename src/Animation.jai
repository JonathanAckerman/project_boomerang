ANIMATIONS_PATH :: "C:/jai/sandbox/project_boomerang/assets/animations";

Animations: struct {
    table: Table(string, [..] Texture);
}

// definitions -------------------------------------------------------------------------------
Animation :: struct {
    frames: [..] Animation_Frame;
    duration: float;
    frame_timer: float;

    current_frame := 0;
    should_loop := false;
    has_finished := false;
}

Animation_Frame :: struct {
    using texture: *Texture;
    tint: Color = WHITE;
    size: Vector2;
    hitboxes: [..] Hitbox;
    hurtboxes: [..] Hurtbox;
}

_file_structure_info :: struct {
    family: string;         // eg: Creature
    genus: string;          // eg: Enemy
    species: string;        // eg: small_fry
    animation_name: string; // eg: idle
}

// functions -------------------------------------------------------------------------------
NewAnimation :: (key: string) -> Animation {
    anim: Animation;
	found := table_find_pointer(*Animations.table, key);
	texture_array: [..] Texture;
    // if foundPtr == null then textureArray = ERROR_ANIMATION;
	// else textureArray = <<foundPtr;
	texture_array = <<found;
    for *texture_array {
        frame: Animation_Frame;
        frame.texture = it;
        frame.size = xy(cast(float) it.width, cast(float) it.height);
        array_add(*anim.frames, frame);
    }
    anim.duration = anim.frames.count / 60.0;
    return anim;
}

get_animations_folder_info :: (info: *File_Visit_Info, data: *[..] _file_structure_info) {
    if info.is_directory {
        folder_name_size := info.full_name.count - ANIMATIONS_PATH.count;
        folder_name := slice(info.full_name, ANIMATIONS_PATH.count + 1, folder_name_size);

        file_struct_info: _file_structure_info;
        success, left, right := split_from_left(folder_name, #char "/");
        if success {
            file_struct_info.family = copy_string(left);
            success, left, right = split_from_left(right, #char "/");
            if success {
                file_struct_info.genus = copy_string(left);
                success, left, right = split_from_left(right, #char "/");
                if success {
                    file_struct_info.species = copy_string(left);
                    file_struct_info.animation_name = copy_string(right);
                    array_add(data, file_struct_info);
                }
            }
        }
    }
}

get_frame_count :: (info: *File_Visit_Info, frame_count: *int) {
    if !info.is_directory then <<frame_count += 1;  
}

load_all_animations :: ()
{
    data: [..] _file_structure_info;
    visit_files(ANIMATIONS_PATH, true, *data, get_animations_folder_info, false, true);

    for d, d_index: data
    {
        frame_count := 0;
        path := tprint("%/%/%/%/%", ANIMATIONS_PATH, d.family, d.genus, d.species, d.animation_name);
        visit_files(path, false, *frame_count, get_frame_count, true, false); // @Jay: there's probably a better way to do this
        key := copy_string(tprint("%/%", d.species, d.animation_name));
        anim_data: [..] Texture;
        for i: 0..frame_count - 1 {
            array_add(*anim_data, LoadTexture(to_c_string(tprint("%/%.png", path, i))));
        }
        table_add(*Animations.table, key, anim_data);
        // print("%\n", key);
    }
}

update_animation :: (using anim: *Animation)
{
    if !should_loop && has_finished then return;

    if frame_timer <= 0.0 {
        frame_timer = duration/frames.count;
        current_frame += 1;
    }
    else frame_timer -= game.dt;

    if current_frame >= frames.count {
        if should_loop then current_frame = 0;
        else current_frame = frames.count - 1;
    }

    // maybe stuff about the texture size/tint?
}

Current_Frame :: (using anim: Animation) -> *Animation_Frame #expand {
    return *frames[current_frame];
}