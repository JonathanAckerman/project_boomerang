Creature :: struct {
    using #as entity: Entity;
    ai: AI_Data;
}

simulate :: (using creature: *Creature) {
    if game.paused then return;

    if creature.ai.has_AI then update_ai(creature);

    forward = lerp(forward, forward_intended, rotation_speed.cur * game.dt);
    if dot(forward, forward_intended) > 0.7
        then position += velocity * game.dt;
}

render :: (using creature: *Creature) {
    update_animation(*creature.animation);
    draw_texture_centered_with_rotation(Current_Frame(creature.animation), creature.position, atan2(-creature.forward.y, creature.forward.x));
}

Creatures: struct {
    PLAYER :: Creature.{
        // for some reason you have to name your arguments here, sadge
        rotation_speed = .{min=0.1, max=10.0, cur=10.0},
        move_speed = .{min=100.0, max=550.0, cur=100.0},
        health = .{min=0, max=3, cur=3},
    };
    // Enemies -------------------------------------------------------------------------------
    SMALL_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=1.0, cur=1.0},
        move_speed = .{min=100.0, max=550.0, cur=100.0},
        health = .{min=0, max=1, cur=1},
    };
    MEDIUM_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=1.0, cur=1.0},
        move_speed = .{min=100.0, max=550.0, cur=100.0},
        health = .{min=0, max=2, cur=2},
    };
    BIG_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=1.0, cur=1.0},
        move_speed = .{min=100.0, max=550.0, cur=100.0},
        health = .{min=0, max=3, cur=3},
    };
}

UNIT_SCALE :: 12;
