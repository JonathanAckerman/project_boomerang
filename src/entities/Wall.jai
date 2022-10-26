Wall :: struct {
    using #as entity: Entity;
}

simulate :: (using wall: *Wall) {
    if game.paused || game.is_gameplay_paused() return;

    if has_collider {
        collider.position = position;
        produce_collidebox(collider, wall, null, null);
    }
}

render :: (using wall: *Wall) {
    for * animations update_animation(it);
    add_to_draw_buffer(Current_Frame(animations[0]), position, .ENTITY, forward);
}