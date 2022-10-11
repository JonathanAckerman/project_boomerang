Creature :: struct {
    using #as entity: Entity;
    using #as hurtable: Hurtable;
    type: Creature_Type;
    weapon: Weapon;

    has_ai := false;
    ai: AI_Data;

    try_attack := false;
}

Weapon :: struct {
    type: Weapon_Type;
    union {
        boomerang: struct {
            animation: Animation;
            status: enum {
                SHEATHED;
                LEAVING;
                RETURNING;
            }
            position: Vector2;
            goal_position: Vector2;
            rotation_point: Vector2;
            move_speed := 500.0;
            collidebox: Collidebox;
            hit_id: Hit_ID;
            tick_rate : float64 = 0.5;
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
    if hurtable.health.cur <= 0 {
        despawn(creature);
        return;
    }

    alignment := dot(forward, forward_intended);
    if has_ai {
        update_ai(creature);
        forward = lerp(forward, forward_intended, rotation_speed.cur * frame.dt);
    }
    else {
        forward = forward_intended;
        produce_catalystbox(collider, creature);
    }

    if dot(forward, forward_intended) > 0.8
        then position += velocity * frame.dt;

    // @Jay: figure out sequencing for taking damage (if the creature dies) and collision resolution
    if has_collider {
        collider.position = position;
        produce_collidebox(collider, creature, creature_on_collision_started, creature_on_collision);
    }

    // @TEMP: for now make the physics collidebox also be the hurtbox
    hit_response := ifx has_ai then enemy_on_hit else player_on_hit;
    produce_hurtbox(collider, *hurtable, creature, hit_response);
    for hurtable.hit_blocks if frame.time >= it.end_time then remove it;

    // respond to Attack input
    if try_attack {
        if weapon.type == {
            case .BOOMERANG;
                boomerang := *weapon.boomerang;
                if boomerang.status == .SHEATHED {
                    boomerang.status = .LEAVING;
                    boomerang.position = position + forward * 10.0;
                    boomerang.goal_position = position + forward * 610.0;
                    boomerang.rotation_point = position + forward * 310.0;
                    boomerang.hit_id = game.get_next_hit_id();
                }
        }
    }
    // maybe also have an input to call the boomerang back?

    // update attack
    if weapon.type == {
        case .BOOMERANG;
            boomerang := *weapon.boomerang;
            
            if boomerang.status == .LEAVING {    
                displacement_vector := boomerang.position - boomerang.rotation_point;
                angular_speed := boomerang.move_speed / length(displacement_vector);
                boomerang.position = boomerang.rotation_point + rotate_vector(displacement_vector, -angular_speed * frame.dt);

                if length(boomerang.position - boomerang.goal_position) < 10.0 {
                    boomerang.status = .RETURNING;
                    boomerang.hit_id = game.get_next_hit_id();
                }

                produce_collidebox(boomerang.collidebox.collider, *creature.weapon, boomerang_on_collision);
            } 
            
            if boomerang.status == .RETURNING {
                direction := position - boomerang.position;
                boomerang.position += unit_vector(direction) * boomerang.move_speed * frame.dt;
                if length(boomerang.position - position) < 10.0 {
                    boomerang.status = .SHEATHED;
                }
            }

            if boomerang.status != .SHEATHED {
                for boomerang.animation.frames {
                    // for it.hitboxes produce_hitbox(it.collider, creature, it.hit);
                    // @TEMP: use collidebox for hitbox
                    produce_hitbox(boomerang.collidebox.collider, creature, make_hit(boomerang.hit_id, 1, tick_rate=boomerang.tick_rate));
                }
                boomerang.collidebox.position = boomerang.position;
            }
    }
}

render :: (using creature: *Creature) {
    for * animations update_animation(it);
    draw_texture_centered_with_rotation(Current_Frame(animations[0]), world_to_screen(position), atan2(-forward.y, forward.x));

    if weapon.type == {
        case .BOOMERANG;
            boomerang := *weapon.boomerang;
            if boomerang.status != .SHEATHED {
                update_animation(*boomerang.animation);
                draw_texture_centered_with_rotation(Current_Frame(boomerang.animation), world_to_screen(boomerang.position), 0.0);
            }
    }
}

creature_on_collision :: (owner: *void, collision: Collision) {
    owner_creature := (cast(*Creature) owner);
    other_creature := (cast(*Creature) collision.other);

    if owner_creature.has_rigidbody && other_creature.has_rigidbody {
        if owner_creature.rigidbody.mass < other_creature.rigidbody.mass
            then owner_creature.position += collision.projection;
        if owner_creature.rigidbody.mass == other_creature.rigidbody.mass
            then owner_creature.position += collision.projection / 2.0;
    }
}
creature_on_collision_started :: (owner: *void, collision: Collision) {
}

// Archetypes -----------------------------------------------------------------------
Creatures: struct {
    PLAYER :: Creature.{
        // for some reason you have to name your arguments here, sadge
        move_speed = .{min=100.0, max=550.0, cur=300.0},
        health = .{min=0, max=3, cur=3},
        type = .PLAYER,
        collider.radius = 20.0,
        has_collider = true,
        mass = 100,
        has_rigidbody = true,
        rigidbody.is_static = false,
    };
    // Enemies ----------------------------------------------------------------------
    SMALL_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=5.0, cur=4.0},
        move_speed = .{min=100.0, max=550.0, cur=150.0},
        health = .{min=0, max=1, cur=1},
        type = .SMALL_FRY,
        has_ai = true,
        has_collider = true,
        mass = 50,
        collider.radius = 12.0,
        has_rigidbody = true,
        rigidbody.is_static = false,
    };
    MEDIUM_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=5.0, cur=2.0},
        move_speed = .{min=100.0, max=550.0, cur=100.0},
        health = .{min=0, max=2, cur=2},
        type = .MEDIUM_FRY,
        has_ai = true,
        has_collider = true,
        mass = 100,
        collider.radius = 20.0,
        has_rigidbody = true,
        rigidbody.is_static = false,
    };
    BIG_FRY :: Creature.{
        rotation_speed = .{min=0.1, max=5.0, cur=1.0},
        move_speed = .{min=100.0, max=550.0, cur=50.0},
        health = .{min=0, max=3, cur=3},
        type = .BIG_FRY,
        has_ai = true,
        collider.radius = 30.0,
        has_collider = true,
        mass = 200,
        has_rigidbody = true,
        rigidbody.is_static = false,
    };
}
