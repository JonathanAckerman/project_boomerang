Creature :: struct {
    using #as entity: Entity;
    type: Creature_Type;
    health: Stat_Range(int);
    weapon: Weapon;

    has_ai := false;
    ai: AI_Data;

    try_attack := false;
}

Weapon :: struct {
    type: Weapon_Type;
    is_ready := true;
    union {
        boomerang: struct {
            is_active := false;
            is_returning := false;
            position: Vector2;
            goal_position: Vector2;
            move_speed := 100.0;
        }
        gloves: struct {

        }
        rapier: struct {

        }
        yoyo: struct {

        }
    }
}

Weapon_Type :: enum {
    BOOMERANG;
    GLOVES;
    RAPIER;
    YOYO;
}

Creature_Type :: enum {
    PLAYER;
    SMALL_FRY;
    MEDIUM_FRY;
    BIG_FRY;
}

simulate :: (using creature: *Creature) {
    if game.paused then return;

    alignment := dot(forward, forward_intended);
    if creature.has_ai {
        update_ai(creature);
        forward = lerp(forward, forward_intended, rotation_speed.cur * game.dt);
    } 
    else forward = forward_intended;

    if dot(forward, forward_intended) > 0.8
        then position += velocity * game.dt;

    if creature.try_attack && creature.weapon.is_ready {
        if creature.weapon.type == {
            case .BOOMERANG;
                boomerang := *creature.weapon.boomerang;
                boomerang.is_active = true;
                boomerang.position = creature.position + creature.forward * 10.0;
                boomerang.goal_position = creature.position + creature.forward * 310.0;
                creature.weapon.is_ready = false;
        }
    }

    if creature.weapon.type == {
        case .BOOMERANG;
            boomerang := *creature.weapon.boomerang;
            if boomerang.is_active {
                if !boomerang.is_returning {
                    direction := boomerang.goal_position - boomerang.position;
                    boomerang.position += unit_vector(direction) * boomerang.move_speed * game.dt;
                    if length(boomerang.position - boomerang.goal_position) < 1.0 {
                        boomerang.is_returning = true;
                    }
                }
                else {
                    direction := creature.position - boomerang.position;
                    boomerang.position += unit_vector(direction) * boomerang.move_speed * game.dt;
                    if length(boomerang.position - creature.position) < 10.0 {
                        creature.weapon.is_ready = true;
                        boomerang.is_active = false;
                        boomerang.is_returning = false;
                    }
                }
            }
    }
}

render :: (using creature: *Creature) {
    for * creature.animations update_animation(it);
    draw_texture_centered_with_rotation(Current_Frame(creature.animations[0]), world_to_screen(creature.position), atan2(-creature.forward.y, creature.forward.x));

    if creature.weapon.type == {
        case .BOOMERANG;
            boomerang := creature.weapon.boomerang;
            if boomerang.is_active {
                print("%\n", boomerang.position);
                // draw_texture_centered_with_rotation(Current_Frame(creature.animations[1]), world_to_screen(creature.position), atan2(-creature.forward.y, creature.forward.x));
            }
    }
}

Creatures: struct {
    PLAYER :: Creature.{
        // for some reason you have to name your arguments here, sadge
        move_speed = .{min=100.0, max=550.0, cur=300.0},
        health = .{min=0, max=3, cur=3},
        type = .PLAYER,
    };
    // Enemies -------------------------------------------------------------------------------
    SMALL_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=5.0, cur=4.0},
        move_speed = .{min=100.0, max=550.0, cur=150.0},
        health = .{min=0, max=1, cur=1},
        type = .SMALL_FRY,
        has_ai = true,
    };
    MEDIUM_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=5.0, cur=2.0},
        move_speed = .{min=100.0, max=550.0, cur=100.0},
        health = .{min=0, max=2, cur=2},
        type = .MEDIUM_FRY,
        has_ai = true,
    };
    BIG_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=5.0, cur=1.0},
        move_speed = .{min=100.0, max=550.0, cur=50.0},
        health = .{min=0, max=3, cur=3},
        type = .BIG_FRY,
        has_ai = true,
    };
}
