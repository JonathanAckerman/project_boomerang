Wall :: struct {
    using #as entity: Entity;
}

update :: (using wall: *Wall) {
    if has_collider {
        collider.position = position;
        produce_collidebox(collider, wall, null, null);
    }
}

simulate :: (using wall: *Wall) {
    if game.paused || game.is_gameplay_paused() return;
}

render :: (using wall: *Wall) {
    for * animations update_animation(it);
    add_to_draw_buffer(Current_Frame(animations[0]), position, .ENTITY, forward);
}