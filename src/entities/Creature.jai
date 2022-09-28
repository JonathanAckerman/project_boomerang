Creature :: struct {
    using #as entity: Entity;
    type: Creature_Type;
    health: Stat_Range;
    ai: *AI_Data;
}

Creature_Type :: enum {
    PLAYER;
    SMALL_FRY;
    MEDIUM_FRY;
    BIG_FRY;
}

simulate :: (using creature: *Creature) {
    if game.paused then return;

    if creature.ai then update_ai(creature);

    forward = lerp(forward, forward_intended, rotation_speed.cur * game.dt);
    if dot(forward, forward_intended) > 0.7
        then position += velocity * game.dt;
}

render :: (using creature: *Creature) {
    update_animation(*creature.animation);
    draw_texture_centered_with_rotation(Current_Frame(creature.animation), world_to_screen(creature.position), atan2(-creature.forward.y, creature.forward.x));
}

Creatures: struct {
    PLAYER :: Creature.{
        // for some reason you have to name your arguments here, sadge
        rotation_speed = .{min=0.1, max=10.0, cur=10.0},
        move_speed = .{min=100.0, max=550.0, cur=200.0},
        health = .{min=0, max=3, cur=3},
        type = .PLAYER,
    };
    // Enemies -------------------------------------------------------------------------------
    SMALL_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=1.0, cur=1.0},
        move_speed = .{min=100.0, max=550.0, cur=200.0},
        health = .{min=0, max=1, cur=1},
        type = .SMALL_FRY,
    };
    MEDIUM_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=1.0, cur=1.0},
        move_speed = .{min=100.0, max=550.0, cur=150.0},
        health = .{min=0, max=2, cur=2},
        type = .MEDIUM_FRY,
    };
    BIG_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=1.0, cur=1.0},
        move_speed = .{min=100.0, max=550.0, cur=100.0},
        health = .{min=0, max=3, cur=3},
        type = .BIG_FRY,
    };
}
