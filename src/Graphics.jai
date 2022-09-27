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
    DrawTextureEx(frame.texture, drawpos, -rad2deg(rotation), scale, frame.tint);
}