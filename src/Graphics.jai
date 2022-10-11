draw_texture_centered_with_rotation :: (frame: Animation_Frame, pos: Vector2, rotation: float, is_screen_space: bool = false)
{
    scale := frame.size.x / frame.texture.width;
    pos_to_center := frame.size/2;
    if !is_screen_space {
        pos_to_center *= game.camera.zoom;
        scale *= game.camera.zoom;
    }
    rotated_pos_to_center := rotate_vector(pos_to_center, -rotation);
    drawpos := pos - rotated_pos_to_center;
    DrawTextureEx(frame.texture, drawpos, -rad2deg(rotation), scale, frame.tint);
}

draw_texture_centered_with_rotation :: (texture: Texture, pos: Vector2, rotation: float, scale: float, color: Color)
{
    pos_to_center := scale * xy(xx texture.width, xx texture.height) / 2.0;
    rotated_pos_to_center := rotate_vector(pos_to_center, -rotation);
    drawpos := pos - rotated_pos_to_center;
    DrawTextureEx(texture, drawpos, -rad2deg(rotation), scale, color);
}

world_to_screen :: (world: Vector2) -> screen: Vector2 {
    to_ss_vector := WINDOW_CENTER - game.camera.position * game.camera.zoom;
    return world * game.camera.zoom + to_ss_vector;
}