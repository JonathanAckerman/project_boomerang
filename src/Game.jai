Hit_ID :: #type,distinct u64;

game: struct {
    state: Game_State;
    resetting: bool;
    debug:     bool;
    paused:    bool;
    gameplay_paused_until: float64; // @Jay: maybe this should be ApolloTime?
    is_gameplay_paused :: inline () -> bool { return game.gameplay_paused_until > 0.0; }
    slowmo: Slowmo;

    player: Handle(Creature);
    camera: struct {
        zoom := 1.0;
        position: Vector2;
    }

    collision_system: struct {
        hitboxes:  [..] Hitbox;
        hurtboxes: [..] Hurtbox;

        collideboxes: [..] Collidebox;
        
        catalystboxes: [..] Catalystbox;
        triggerboxes:  [..] Triggerbox;
    }

    particle_system: struct {
        emitters: [..] Particle_Emitter;
        particles: [..] Particle;
    }

    _hit_id: Hit_ID;
    get_next_hit_id :: () -> Hit_ID { game._hit_id += 1; return game._hit_id; }

    map: Texture;

    test_trigger: Trigger;
}

Trigger :: struct {
    is_active := true;
    using #as collider: Collider = .{shape=.RECT, position=.{530, 550}, size=.{10, 100}};
}

frame: struct {
    dt: float;
    scale: float = 1.0;
    time: float64;
}

Game_State :: enum {
    INITIAL;
}

game_loop :: inline () {
    using game;
    using context.entity_storage;
    frame.time = GetTime();
    frame.dt = GetFrameTime() * frame.scale;
    game.gameplay_paused_until -= frame.dt / frame.scale;

    // simulate ----------------------------------------------------------------
    handle_input();

    simulate();

    if test_trigger.is_active {
        produce_triggerbox(test_trigger, *test_trigger, on_trigger_fight);
    }

    handle_collision();

    // draw --------------------------------------------------------------------
    BeginDrawing();

    ClearBackground(DARKGRAY);
    DrawTextureV(map, world_to_screen(.{0,0}), WHITE);

    for _Wall     render(it);
    for _Creature render(it);

    DrawFPS(0, 0);

    {
        cstr := temp_c_string("PROJECT BOOMERANG");
        measure := MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1);
        DrawTextPro(the_font, cstr, .{WINDOW_WIDTH-2, WINDOW_HEIGHT-2}, measure, 0, xx the_font.baseSize, 1, WHITE);
    }

    for particle_system.particles { render(it); }

    if debug {
        using collision_system;
        draw_colliders(hitboxes,      RED);
        draw_colliders(hurtboxes,     BLUE);
        draw_colliders(collideboxes,  YELLOW);
        draw_colliders(catalystboxes, BLACK);
        draw_colliders(triggerboxes,  WHITE);

        draw_colliders :: (array: [] $T, color: Color) #expand {
            for array {
                ss_pos := world_to_screen(it.position);
                if it.shape == {
                    case .CIRCLE;
                        DrawCircleLines(xx ss_pos.x, xx ss_pos.y, xx it.radius, color);
                    case .RECT;
                        ss_pos -= it.size/2.0;
                        DrawRectangleLines(xx ss_pos.x, xx ss_pos.y, xx it.size.x, xx it.size.y, color);
                }
            }
        }
    }

    EndDrawing();

    // cleanup -----------------------------------------------------------------
    array_reset_keeping_memory(*collision_system.hitboxes);
    array_reset_keeping_memory(*collision_system.hurtboxes);
    array_reset_keeping_memory(*collision_system.collideboxes);
    array_reset_keeping_memory(*collision_system.catalystboxes);
    array_reset_keeping_memory(*collision_system.triggerboxes);

    // clean up particles
    for particle_system.particles { 
        if it.lifetime <= 0.0 {
            it.emitter.alive_particles -= 1;
            remove it;
        }
    }

    cleanup_despawning_entities();
    reset_temporary_storage();
}

game_reset :: () {
    using game;
    log("RESETTING GAME");
    reset_entity_storage();
    load_all_animations();

    game = .{};
    array_reserve(*collision_system.hitboxes, 1024);
    array_reserve(*collision_system.hurtboxes, 1024);
    array_reserve(*collision_system.collideboxes, 1024);
    map = LoadTexture("C:/jai/sandbox/project_boomerang/assets/textures/grass.png");

    max_particles := 0;
    for particle_system.emitters {
        max_particles += it.max_particles;
    }
    array_reserve(*particle_system.particles, max_particles);

    // init creatures
    {
        c := Creatures.PLAYER; 
        c.position = .{0, 0};
        c.collider.position = c.position;
        array_add(*c.animations, NewAnimation("player/idle"));
        c.weapon.type = .BOOMERANG;
        c.weapon.boomerang.animation = NewAnimation("boomerang/spin");
        c.weapon.boomerang.animation.should_loop = true;
        c.weapon.boomerang.collidebox.radius = 10.0;
        e: Particle_Emitter = .{
            is_active=false,
            size=.{10, 10}, 
            max_particles=100,
            spawn_interval=.01, 
            spawn_timer=0.0, 
            decay_interval=0.5, 
            start_scale=0.5,
            end_scale=0.1,
            start_color=GRAY,
            end_color=WHITE,
            start_velocity=.{0, 0},
            acceleration=.{0, 0},
        };
        e.texture = LoadTexture("C:/jai/sandbox/project_boomerang/assets/textures/cloud.png");
        array_add(*particle_system.emitters, e);
        c.weapon.boomerang.emitter = *particle_system.emitters[particle_system.emitters.count-1];
        player = spawn(c);
    }

    // init walls
    {
        w: Wall;
        w.position = .{1000, 505};
        array_add(*w.animations, NewAnimation("wall/idle"));
        w.has_collider = true;
        w.collider.shape = .RECT;
        w.collider.size = .{1000, 10};
        w.has_rigidbody = true;
        w.entity_type = .WALL;
        spawn(w);

        w.position = .{1000, 1495};
        w.entity_type = .WALL;
        spawn(w);

        w.position = .{1500, 1000};
        w.collider.size = .{10, 1000};
        w.entity_type = .WALL;
        spawn(w);

        w.position = .{500, 1050};
        w.collider.size = .{10, 900};
        w.entity_type = .WALL;
        spawn(w);
    }
}

on_trigger_fight :: (catalyst: Catalystbox, trigger: Triggerbox) {
    using game;
    gameplay_paused_until = 2.0;

    c := Creatures.SMALL_FRY;
    c.position = .{700, 700};
    c.collider.position = c.position;
    array_add(*c.animations, NewAnimation("small_fry/idle"));
    spawn(c);
    e: Particle_Emitter;
    e = .{
        is_active=true,
        deactivate_timer=1.0,
        size=.{50, 50}, 
        max_particles=100,
        spawn_interval=.01, 
        spawn_timer=0.0, 
        decay_interval=1.0, 
        start_scale=0.1,
        end_scale=0.3,
        start_color=WHITE,
        end_color=GRAY,
        start_velocity=.{0, -150},
        speed_noise=.{min=0, max=1},
        direction_noise=.{min=-PI/2, max=PI/2},
        acceleration=.{0, -150},
    };
    e.position=c.position;
    e.texture = LoadTexture("C:/jai/sandbox/project_boomerang/assets/textures/cloud.png");
    array_add(*particle_system.emitters, e);

    c = Creatures.MEDIUM_FRY;
    c.position = .{800, 700};
    c.collider.position = c.position;
    array_add(*c.animations, NewAnimation("medium_fry/idle"));
    spawn(c);
    e = .{
        is_active=true,
        deactivate_timer=1.0,
        size=.{50, 50}, 
        max_particles=100,
        spawn_interval=.01, 
        spawn_timer=0.0, 
        decay_interval=1.0, 
        start_scale=0.2,
        end_scale=0.6,
        start_color=WHITE,
        end_color=GRAY,
        start_velocity=.{0, -50},
        acceleration=.{0, -1000},
    };
    e.position=c.position;
    e.texture = LoadTexture("C:/jai/sandbox/project_boomerang/assets/textures/cloud.png");
    array_add(*particle_system.emitters, e);

    c = Creatures.BIG_FRY;
    c.position = .{1000, 700};
    c.collider.position = c.position;
    array_add(*c.animations, NewAnimation("big_fry/idle"));
    c.on_death = end_arena;
    spawn(c);
    e = .{
        is_active=true,
        deactivate_timer=1.0,
        size=.{100, 100}, 
        max_particles=100,
        spawn_interval=.01, 
        spawn_timer=0.0, 
        decay_interval=1.0, 
        start_scale=0.5,
        end_scale=1.0,
        start_color=WHITE,
        end_color=GRAY,
        start_velocity=.{0, -500},
        acceleration=.{0, 0},
    };
    e.position=c.position;
    e.texture = LoadTexture("C:/jai/sandbox/project_boomerang/assets/textures/cloud.png");
    array_add(*particle_system.emitters, e);

    w: Wall;
    w.position = .{500, 550};
    array_add(*w.animations, NewAnimation("wall/idle"));
    w.has_collider = true;
    w.collider.shape = .RECT;
    w.collider.size = .{10, 100};
    w.has_rigidbody = true;
    w.entity_type = .WALL;
    spawn(w);

    (cast(*Trigger) trigger.owner).is_active = false;
}

simulate :: () {
    using game;
    using context.entity_storage;

    simulate(*slowmo);
    
    for _Wall     simulate(it);
    for _Creature simulate(it);

    for * particle_system.emitters {
        emit(it);
        simulate(it);
    }
    for * particle_system.particles {
        simulate(it);
    }

    player_obj, _ := from_handle(player); 
    camera.position = player_obj.position;
}

player_on_hit :: (hurtable: *Hurtable, hit: Hit) {
    log("Player is being damaged for %", hit.damage);
    if hurtable.health.cur > hurtable.health.min then hurtable.health.cur -= hit.damage;
    if hurtable.health.cur <= 0 {
        log("Player was killed");
    }
}
enemy_on_hit :: (hurtable: *Hurtable, hit: Hit) {
    for hurtable.hit_blocks if it.hit_id == hit.id return;

    array_add(*hurtable.hit_blocks, make_block(hit.id, GetTime() + hit.tick_rate));
    if hurtable.health.cur > hurtable.health.min {
        hurtable.health.cur -= hit.damage;
        game.slowmo = .{
            is_active = true,
            scale = 0.2,
            attack = 0.01,
            sustain = 0.01,
            decay = 0.01,
        };
    }
}

boomerang_on_collision :: (owner: *void, collision: Collision) {
    weapon := cast(*Weapon) owner;
    other := cast(*Entity) collision.other;
    if other.entity_type == {
        case .CREATURE; return;
        case .PROJECTILE;
            // return to player and @TODO deflect projectile
            if weapon.boomerang.status == .LEAVING then weapon.boomerang.status = .RETURNING;
            weapon.boomerang.hit_id = game.get_next_hit_id();
        case .WALL;
            if weapon.boomerang.status == .LEAVING then weapon.boomerang.status = .BOUNCING;
            weapon.boomerang.hit_id = game.get_next_hit_id();

            // print("collision with: %\n", other);
            // print("normal: %\n", collision.normal);
            // print("velocity: %\n", weapon.boomerang.velocity);

            inv_velocity := weapon.boomerang.velocity * -1.0;
            incidence_angle := acos(dot(inv_velocity, collision.normal) / length(inv_velocity));
            {
                v := atan2(-inv_velocity.y, inv_velocity.x);
                n := atan2(-collision.normal.y, collision.normal.x);
                // @TODO: fix this jank
                if collision.normal == .{-1, 0} {
                    if v > n then n = PI;        // since atan2 wraps at PI
                    if v < 0 then v += 2.0 * PI; // since atan2 wraps at PI
                }
                if v < n then incidence_angle *= -1.0;
            }
            // print("angle: %\n", incidence_angle);

            weapon.boomerang.velocity = unit_vector(rotate_vector(collision.normal, incidence_angle)) * weapon.boomerang.move_speed;
            weapon.boomerang.start_position = weapon.boomerang.position;
    }

}

end_arena :: () {
    for context.entity_storage._Wall {
        despawn(it);
    }
    game.gameplay_paused_until = 0.5;
}
