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
            animation: Animation;
            is_active := false;
            is_returning := false;
            position: Vector2;
            goal_position: Vector2;
            rotation_point: Vector2;
            move_speed := 500.0;
            collider: Collider;
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
    if has_ai {
        update_ai(creature);
        forward = lerp(forward, forward_intended, rotation_speed.cur * game.dt);
    } 
    else forward = forward_intended;

    if dot(forward, forward_intended) > 0.8
        then position += velocity * game.dt;

    if has_collider {
        collider.position = position;
        array_add(*game.physics_colliders, collider);
    }

    // respond to Attack input
    if try_attack && weapon.is_ready {
        if weapon.type == {
            case .BOOMERANG;
                boomerang := *weapon.boomerang;
                boomerang.is_active = true;
                boomerang.position = position + forward * 10.0;
                boomerang.goal_position = position + forward * 610.0;
                boomerang.rotation_point = position + forward * 310.0;
                weapon.is_ready = false;
        }
    }

    // update attack
    if weapon.type == {
        case .BOOMERANG;
            boomerang := *weapon.boomerang;
            if boomerang.is_active {
                for boomerang.animation.frames for it.colliders {
                    if it.type == .HIT then array_add(*game.hit_colliders, it);
                }

                if !boomerang.is_returning {
                    displacement_vector := boomerang.position - boomerang.rotation_point;
                    boomerang.position = boomerang.rotation_point + rotate_vector(displacement_vector, -game.dt * 1.5);

                    if length(boomerang.position - boomerang.goal_position) < 10.0 {
                        boomerang.is_returning = true;
                    }
                } else {
                    direction := position - boomerang.position;
                    boomerang.position += unit_vector(direction) * boomerang.move_speed * game.dt;
                    if length(boomerang.position - position) < 10.0 {
                        weapon.is_ready = true;
                        boomerang.is_active = false;
                        boomerang.is_returning = false;
                    }
                }
                boomerang.collider.position = boomerang.position;
                array_add(*game.physics_colliders, boomerang.collider);
            }
    }

    // // look for colliders on the creature's animation
    // for anim: animations {
    //     for frame: anim.frames {
    //         for collider: frame.colliders {
    //             if collider.type == {
    //                 case .PHYSICS; array_add(*game.physics_colliders, collider);
    //                 case .HURT;    array_add(*game.hurt_colliders, collider);
    //                 case .HIT;     array_add(*game.hit_colliders, collider);
    //             }
    //         }
    //     }
    // }
}

render :: (using creature: *Creature) {
    for * animations update_animation(it);
    draw_texture_centered_with_rotation(Current_Frame(animations[0]), world_to_screen(position), atan2(-forward.y, forward.x));

    if weapon.type == {
        case .BOOMERANG;
            boomerang := *weapon.boomerang;
            if boomerang.is_active {
                update_animation(*boomerang.animation);
                draw_texture_centered_with_rotation(Current_Frame(boomerang.animation), world_to_screen(boomerang.position), 0.0);
            }
    }
}

Creatures: struct {
    PLAYER :: Creature.{
        // for some reason you have to name your arguments here, sadge
        move_speed = .{min=100.0, max=550.0, cur=300.0},
        health = .{min=0, max=3, cur=3},
        type = .PLAYER,
        collider.radius = 20.0,
        has_collider = true,
    };
    // Enemies -------------------------------------------------------------------------------
    SMALL_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=5.0, cur=4.0},
        move_speed = .{min=100.0, max=550.0, cur=150.0},
        health = .{min=0, max=1, cur=1},
        type = .SMALL_FRY,
        has_ai = true,
        collider.radius = 12.0,
        has_collider = true,
    };
    MEDIUM_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=5.0, cur=2.0},
        move_speed = .{min=100.0, max=550.0, cur=100.0},
        health = .{min=0, max=2, cur=2},
        type = .MEDIUM_FRY,
        has_ai = true,
        collider.radius = 20.0,
        has_collider = true,
    };
    BIG_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=5.0, cur=1.0},
        move_speed = .{min=100.0, max=550.0, cur=50.0},
        health = .{min=0, max=3, cur=3},
        type = .BIG_FRY,
        has_ai = true,
        collider.radius = 30.0,
        has_collider = true,
    };
}
