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
                BOUNCING;
            }
            position: Vector2;
            velocity: Vector2;
            start_position: Vector2;
            bounces: Range(int);
            move_speed := 500.0;
            travel_distance := 500.0;
            collidebox: Collidebox;
            hit_id: Hit_ID;
            tick_rate := 0.5;
            emitter: *Particle_Emitter;
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
    BIG_GUY;
}

update :: (using creature: *Creature) {
    if has_collider {
        collider.position = position;
        produce_collidebox(collider, creature, creature_on_collision_started, creature_on_collision);
    }

    if has_ai && type == .BIG_GUY && game.state == .OPEN_WORLD then produce_triggerbox(collider, creature, on_trigger_fight);
    if !has_ai then produce_catalystbox(collider, creature);

    // @TEMP: for now make the physics collidebox also be the hurtbox
    hit_response := ifx has_ai then enemy_on_hit else player_on_hit;
    produce_hurtbox(collider, *hurtable, creature, hit_response);

    if weapon.type == {
        case .BOOMERANG;
            boomerang := *weapon.boomerang;
            if boomerang.status != .SHEATHED {
                // @TEMP: use collidebox for hitbox
                produce_hitbox(boomerang.collidebox.collider, creature, make_hit(boomerang.hit_id, 1, tick_rate=boomerang.tick_rate));
                boomerang.collidebox.position = boomerang.position;

                if !has_ai && game.state == .OPEN_WORLD then produce_catalystbox(boomerang.collidebox.collider, creature);
            }

            if boomerang.status == .LEAVING || boomerang.status == .BOUNCING {
                produce_collidebox(boomerang.collidebox.collider, *creature.weapon, boomerang_on_collision);
            }
    }
}

simulate :: (using creature: *Creature) {
    if game.paused || game.is_gameplay_paused() return;

    if hurtable.health.cur <= 0 {
        despawn(creature);
        if creature.on_death then creature.on_death();
        return;
    }

    position += velocity * frame.dt;

    if has_ai {
        update_ai(creature);
        forward = lerp(forward, forward_intended, rotation_speed.cur * frame.dt);
    }
    else {
        forward = forward_intended;
    }

    for * hurtable.hit_blocks {
        it.timer -= frame.dt;
        if it.timer <= 0.0 then remove it;
    }

    // respond to Attack input
    if try_attack {
        if weapon.type == {
            case .BOOMERANG;
                boomerang := *weapon.boomerang;
                if boomerang.status == .SHEATHED {
                    boomerang.status = .LEAVING;
                    boomerang.position = position + forward * 10.0;
                    boomerang.start_position = boomerang.position;
                    boomerang.velocity = forward * boomerang.move_speed;
                    boomerang.hit_id = game.get_next_hit_id();
                    boomerang.emitter.is_active = true;
                }
                else {
                    // @TODO: nerf this with a delay Action
                    boomerang.status = .SHEATHED;
                    boomerang.emitter.is_active = false;
                }
        }
    }

    // update attack
    if weapon.type == {
        case .BOOMERANG;
            boomerang := *weapon.boomerang;
            if boomerang.status != .SHEATHED {
                boomerang.position += boomerang.velocity * frame.dt;
                boomerang.emitter.position = boomerang.position;
            }

            if boomerang.status == .LEAVING {
                if length(boomerang.position - boomerang.start_position) > boomerang.travel_distance {
                    boomerang.status = .RETURNING;
                    boomerang.hit_id = game.get_next_hit_id();
                }
            } 
            
            if boomerang.status == .RETURNING {
                direction := position - boomerang.position;
                boomerang.velocity = unit_vector(direction) * boomerang.move_speed;
                if length(boomerang.position - position) < boomerang.collidebox.radius {
                    boomerang.bounces.cur = boomerang.bounces.max;
                    boomerang.status = .SHEATHED;
                    boomerang.emitter.is_active = false;
                }
            }

            if boomerang.status == .BOUNCING {
                if length(boomerang.position - boomerang.start_position) > boomerang.travel_distance {
                    boomerang.status = .RETURNING;
                    weapon.boomerang.hit_id = game.get_next_hit_id();
                }
                if length(boomerang.position - position) < boomerang.collidebox.radius {
                    boomerang.bounces.cur = boomerang.bounces.max;
                    boomerang.status = .SHEATHED;
                    boomerang.emitter.is_active = false;
                }
            }
    }
}

render :: (using creature: *Creature) {
    for * animations update_animation(it);
    add_to_draw_buffer(Current_Frame(animations[0]), position, .ENTITY, forward);

    if weapon.type == {
        case .BOOMERANG;
            boomerang := *weapon.boomerang;
            if boomerang.status != .SHEATHED {
                if !game.paused && !game.is_gameplay_paused() then update_animation(*boomerang.animation);
                add_to_draw_buffer(Current_Frame(boomerang.animation), boomerang.position, .ENTITY, .{0,-1}); // @Note: boomerang has a hardcoded forward
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

creature_on_spawn :: () {

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
        entity_type = .CREATURE,
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
        entity_type = .CREATURE,
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
        entity_type = .CREATURE,
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
        entity_type = .CREATURE,
    };
    BIG_GUY :: Creature.{
        rotation_speed = .{min=0.1, max=5.0, cur=1.0},
        move_speed = .{min=0.0, max=550.0, cur=20.0},
        health = .{min=0, max=10, cur=10},
        type = .BIG_GUY,
        has_ai = true,
        collider.radius = 100.0,
        has_collider = true,
        mass = 300,
        has_rigidbody = true,
        rigidbody.is_static = false,
        entity_type = .CREATURE,
    };
}
