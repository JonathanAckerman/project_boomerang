Wall :: struct {
    using #as entity: Entity;
}

simulate :: (using wall: *Wall) {
    if game.paused then return;

    if has_collider {
        collider.position = position;
        produce_collidebox(collider, wall, null, null);
    }
}

render :: (using wall: *Wall) {
    for * animations update_animation(it);
    draw_texture_centered_with_rotation(Current_Frame(animations[0]), world_to_screen(position), atan2(-forward.y, forward.x));
}