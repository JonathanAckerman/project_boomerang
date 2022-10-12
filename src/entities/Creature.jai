Creature :: struct {
    using #as entity: Entity;
    using #as hurtable: Hurtable;
    type: Creature_Type;
    weapon: Weapon;

    has_ai := false;
    ai: AI_Data;

    try_attack := false;

    on_death: ()->();
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
            forward:  Vector2;
            path: Bezier_Cubic;
            move_speed := 500.0;
            collidebox: Collidebox;
            hit_id: Hit_ID;
            tick_rate : float64 = 0.5;
            use_curve_shot := false;
            shot_side: float;
        }

        gloves: struct {

        }
        rapier: struct {

        }
        yoyo: struct {

        }
    }
}

Bezier_Cubic :: struct {
    p0: Vector2;
    p1: Vector2;
    p2: Vector2;
    p3: Vector2;
    t: float = 0.0;
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
    if game.paused || game.is_gameplay_paused() return;

    if hurtable.health.cur <= 0 {
        despawn(creature);
        if creature.on_death then creature.on_death();
        return;
    }

    position += velocity * frame.dt;
    if has_collider {
        collider.position = position;
        produce_collidebox(collider, creature, creature_on_collision_started, creature_on_collision);
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

    // @TEMP: for now make the physics collidebox also be the hurtbox
    hit_response := ifx has_ai then enemy_on_hit else player_on_hit;
    produce_hurtbox(collider, *hurtable, creature, hit_response);
    for hurtable.hit_blocks if frame.time >= it.end_time then remove it;

    // @TEMP: just to see the path in real time
    if game.debug && weapon.boomerang.status == .SHEATHED {
        boomerang := *weapon.boomerang;
        attack_forward := ifx boomerang.forward != .{0, 0} then boomerang.forward else forward;
        if !boomerang.use_curve_shot {
            boomerang.position = position + attack_forward * 10.0;
            boomerang.path.p0 = boomerang.position;
            boomerang.path.p3 = position + attack_forward * 510.0;
            boomerang.path.p1 = boomerang.path.p0 + rotate_vector(attack_forward, boomerang.shot_side * PI/4.0) * 150.0;
            boomerang.path.p2 = boomerang.path.p3 + rotate_vector(attack_forward, boomerang.shot_side * PI/2.0) * 250.0;
        }
        else {
            boomerang.position = position + rotate_vector(forward, boomerang.shot_side * PI/2) * 10.0;
            boomerang.path.p0 = boomerang.position;
            boomerang.path.p3 = position + attack_forward * 710.0;
            boomerang.path.p1 = boomerang.path.p0 + rotate_vector(attack_forward, boomerang.shot_side * PI/2.0) * 500.0;
            boomerang.path.p2 = boomerang.path.p3 + rotate_vector(attack_forward, boomerang.shot_side * PI/2.0) * 500.0;
        }
    }

    // respond to Attack input
    if try_attack {
        if weapon.type == {
            case .BOOMERANG;
                boomerang := *weapon.boomerang;
                if boomerang.status == .SHEATHED {
                    boomerang.status = .LEAVING;
                    attack_forward := ifx boomerang.forward != .{0, 0} then boomerang.forward else forward;
                    if !boomerang.use_curve_shot {
                        boomerang.position = position + attack_forward * 10.0;
                        boomerang.path.p0 = boomerang.position;
                        boomerang.path.p3 = position + attack_forward * 510.0;
                        boomerang.path.p1 = boomerang.path.p0 + rotate_vector(attack_forward, boomerang.shot_side * PI/4.0) * 150.0;
                        boomerang.path.p2 = boomerang.path.p3 + rotate_vector(attack_forward, boomerang.shot_side * PI/2.0) * 250.0;
                        boomerang.hit_id = game.get_next_hit_id();
                        game.test_particle_emitter4.is_active = true;
                    }
                    else {
                        boomerang.position = position + rotate_vector(forward, boomerang.shot_side * PI/2) * 10.0;
                        boomerang.path.p0 = boomerang.position;
                        boomerang.path.p3 = position + attack_forward * 710.0;
                        boomerang.path.p1 = boomerang.path.p0 + rotate_vector(attack_forward, boomerang.shot_side * PI/2.0) * 500.0;
                        boomerang.path.p2 = boomerang.path.p3 + rotate_vector(attack_forward, boomerang.shot_side * PI/2.0) * 500.0;
                        boomerang.hit_id = game.get_next_hit_id();
                        game.test_particle_emitter4.is_active = true;
                    }
                }
                else {
                    // @TODO: nerf this with a delay Action
                    boomerang.status = .SHEATHED;
                    game.test_particle_emitter4.is_active = false;
                    boomerang.path = .{};
                }
        }
    }

    // update attack
    if weapon.type == {
        case .BOOMERANG;
            boomerang := *weapon.boomerang;
            
            if boomerang.status == .LEAVING {
                boomerang.path.t += frame.dt;
                {
                    t := boomerang.path.t/1.5;
                    p0_component := boomerang.path.p0 * ((-t*t*t) + (3.0*t*t) - (3.0*t) + 1.0);
                    p1_component := boomerang.path.p1 * ((3.0*t*t*t) - (6.0*t*t) + (3.0*t));
                    p2_component := boomerang.path.p2 * ((-3.0*t*t*t) + (3.0*t*t));
                    p3_component := boomerang.path.p3 * (t*t*t);
                    boomerang.position = p0_component + p1_component + p2_component + p3_component;
                }

                if length(boomerang.position - boomerang.path.p3) < 10.0 {
                    boomerang.status = .RETURNING;
                    boomerang.hit_id = game.get_next_hit_id();
                    weapon.boomerang.path.t = 0.0;
                }

                produce_collidebox(boomerang.collidebox.collider, *creature.weapon, boomerang_on_collision);
            } 
            
            if boomerang.status == .RETURNING {
                direction := position - boomerang.position;
                boomerang.position += unit_vector(direction) * boomerang.move_speed * frame.dt;
                if length(boomerang.position - position) < 10.0 {
                    boomerang.status = .SHEATHED;
                    game.test_particle_emitter4.is_active = false;
                }
            }

            if boomerang.status != .SHEATHED {
                for boomerang.animation.frames {
                    // for it.hitboxes produce_hitbox(it.collider, creature, it.hit);
                    // @TEMP: use collidebox for hitbox
                    produce_hitbox(boomerang.collidebox.collider, creature, make_hit(boomerang.hit_id, 1, tick_rate=boomerang.tick_rate));
                }
                boomerang.collidebox.position = boomerang.position;
                game.test_particle_emitter4.position = boomerang.position;
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
                if !game.paused && !game.is_gameplay_paused() then update_animation(*boomerang.animation);
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
