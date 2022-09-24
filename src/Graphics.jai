draw_texture_centered_with_rotation :: (frame: Animation_Frame, pos: Vector2, rotation: float, is_screen_space: bool = false)
{
    scale := frame.size.x / frame.texture.width;
    pos_to_center := frame.size/2;
    // if !is_screen_space {
    //     pos_to_center *= game.camera.zoom;
    //     scale *= game.camera.zoom;
    // }
    rotated_pos_to_center := rotate_vector(pos_to_center, -rotation);
    drawpos := pos - rotated_pos_to_center;
    DrawTextureEx(frame.texture, drawpos, -rotation, scale, frame.tint);
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