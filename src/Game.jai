Hit_ID :: #type,distinct u64;

game: struct {
    state: Game_State;
    resetting: bool;
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
}

frame: struct {
    dt: float;
    scale: float = 1.0;
}

debug: struct {
    render_colliders: bool = true;
    dont_render_graphics: bool;

    collider_render_texture: RenderTexture;
}

editor: struct {
    enabled: bool;
}

Game_State :: enum {
    OPEN_WORLD;
    ARENA_FIGHT;
}

game_loop :: inline () {
    using game;
    using context.entity_storage;
    frame.dt = GetFrameTime() * frame.scale;
    if !game.paused then game.gameplay_paused_until -= frame.dt / frame.scale;

    // simulate ------------------------------------------------------------------------------
    handle_input(); // @Note: eventually we'll want input that isn't related to the game state

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

    handle_collision();

    // draw --------------------------------------------------------------------
    BeginDrawing();

    ClearBackground(DARKGRAY);

    if !debug.dont_render_graphics {
        DrawTextureV(map, world_to_screen(.{0,0}), WHITE);

        for _Wall     render(it);
        for _Creature render(it);

        for particle_system.particles render(it);
    }

    if debug.render_colliders {
        using collision_system;

        if !game.paused && !game.is_gameplay_paused() {
            BeginTextureMode(debug.collider_render_texture);
            ClearBackground(BLANK);
            draw_colliders(hitboxes,      RED);
            draw_colliders(hurtboxes,     BLUE);
            draw_colliders(collideboxes,  YELLOW);
            draw_colliders(catalystboxes, BLACK);
            draw_colliders(triggerboxes,  WHITE);
            EndTextureMode();
        }

        draw_colliders :: (array: [] $T, color: Color) #expand {
            for array {
                ss_pos := world_to_screen(it.position);
                if it.shape == {
                    case .CIRCLE;
                        DrawCircleLines(xx ss_pos.x, xx ss_pos.y, it.radius, color);
                    case .RECT;
                        DrawRectangleLines(xx (ss_pos.x - it.size.x/2), xx (ss_pos.y - it.size.y/2), xx it.size.x, xx it.size.y, color);
                }
            }
        }
    }

    {
        str := "PROJECT BOOMERANG";
        measure := MeasureTextEx(fonts.courier_new, temp_c_string(str), xx fonts.courier_new.baseSize, 1);
        add_to_draw_buffer(.SCREEN_UI, fonts.courier_new, str, .{WINDOW_WIDTH-2, WINDOW_HEIGHT} - xy(0, measure.y/2), xx measure, xx fonts.courier_new.baseSize, 1, WHITE);
        str = "SECOND FONT";
        measure = MeasureTextEx(fonts.mecha, temp_c_string(str), xx fonts.mecha.baseSize + 4.0, 12);
        add_to_draw_buffer(.SCREEN_UI, fonts.mecha, str, .{WINDOW_WIDTH-2, WINDOW_HEIGHT-2}, xx measure, xx fonts.mecha.baseSize + 4.0, 12, PINK);
    }

    // Sort draw_buffer
    less_than :: (a, b) => cast(s64)a.traunch - cast(s64)b.traunch;
    bubble_sort(draw_buffer, less_than);

    for draw_buffer {
        is_screen_space := it.traunch == .SCREEN_UI;
        position := ifx is_screen_space
            then it.position
            else world_to_screen(it.position);

        if it.type == {
            case .DEBUG; // this is just for debug shapes not handled by the collision_system
                using it.debug;
                if shape == {
                    case .CIRCLE;
                        DrawCircleLines(xx position.x, xx position.y, xx radius, color);
                    case .LINE;
                        DrawLineV(position, end_point, color);
                    case .RECT;
                        DrawRectangleLines(xx (position.x - size.x/2), xx (position.y - size.y/2), xx size.x, xx size.y, color);
                }
            case .TEXTURE;
                using it.texture;
                draw_texture_centered_with_rotation(texture, ss(position), rotation, scale, color);
            case .ANIM;
                draw_texture_centered_with_rotation(it.frame, position, it.rotation, is_screen_space);
            case .TEXT;
                using it.text;
                DrawTextPro(font, temp_c_string(str), position, origin, rotation, size, spacing, color);
        } 
    }
    array_reset_keeping_memory(*draw_buffer);

    // draw collision_system
    source : Rectangle = .{0, -WINDOW_HEIGHT, WINDOW_WIDTH, -WINDOW_HEIGHT};
    dest   : Rectangle = .{0, 0, WINDOW_WIDTH, WINDOW_HEIGHT};
    DrawTexturePro(debug.collider_render_texture.texture, source, dest, .{0, 0}, 0, WHITE);

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
    load_all_fonts();

    game = .{};
    frame = .{};
    debug.collider_render_texture = LoadRenderTexture(WINDOW_WIDTH, WINDOW_HEIGHT);

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
        c.weapon.boomerang.collidebox.radius = 50.0;
        c.weapon.boomerang.bounces = .{min=0, cur=2, max=2};
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

        c = Creatures.BIG_GUY;
        c.position = .{500, 500};
        c.collider.position = c.position;
        array_add(*c.animations, NewAnimation("big_guy/idle"));
        c.on_death = end_arena;
        spawn(c);
    }
}

on_trigger_fight :: (catalyst: Catalystbox, trigger: Triggerbox) {
    using game;
    
    if (cast(*Entity) catalyst.owner).entity_type != .CREATURE then return;
    if (cast(*Creature) catalyst.owner).type != .PLAYER then return;

    trigger_position := (cast(*Entity) trigger.owner).position;
    catalyst_position := (cast(*Entity) catalyst.owner).position;
    midpt := (trigger_position - catalyst_position) / 2.0;
    base_position := catalyst_position + midpt;

    gameplay_paused_until = 2.0;

    c := Creatures.SMALL_FRY;
    x := random_get_within_range(-450, 450);
    y := random_get_within_range(-450, 450);
    c.position = base_position + xy(x, y);
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
    x = random_get_within_range(-450, 450);
    y = random_get_within_range(-450, 450);
    c.position = base_position + xy(x, y);
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
    x = random_get_within_range(-450, 450);
    y = random_get_within_range(-450, 450);
    c.position = base_position + xy(x, y);
    c.collider.position = c.position;
    array_add(*c.animations, NewAnimation("big_fry/idle"));
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

    // arena walls
    {
        w: Wall;
        w.position = base_position - .{0, 500};
        array_add(*w.animations, NewAnimation("wall/idle"));
        w.has_collider = true;
        w.collider.shape = .RECT;
        w.collider.size = .{1000, 100};
        w.has_rigidbody = true;
        w.entity_type = .WALL;
        spawn(w);

        w.position = base_position + .{500, 0};
        w.collider.size = .{100, 1000};
        spawn(w);

        w.position = base_position + .{0, 500};
        w.collider.size = .{1000, 100};
        spawn(w);

        w.position = base_position - .{500, 0};
        w.collider.size = .{100, 1000};
        spawn(w);
    }

    game.state = .ARENA_FIGHT;
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

    array_add(*hurtable.hit_blocks, make_block(hit.id, hit.tick_rate));
    if hurtable.health.cur > hurtable.health.min {
        hurtable.health.cur -= hit.damage;
        game.slowmo = .{
            is_active = true,
            scale = 0.1,
            attack = 0.01,
            sustain = 0.01,
            decay = 0.01,
        };
    }
}

boomerang_on_collision_started :: (owner: *void, collision: Collision) {
    weapon := cast(*Weapon) owner;
    other := cast(*Entity) collision.other;

    // if the boomerang collided with it's owner
    if other.entity_type == .CREATURE && weapon == *(cast(*Creature) collision.other).weapon
        return;

    weapon.boomerang.position += collision.projection;

    if other.entity_type == {
        case .CREATURE;
            if (cast(*Creature) collision.other).type == .BIG_GUY {
                weapon.boomerang.status = .RETURNING;
                weapon.boomerang.hit_id = game.get_next_hit_id();
            }
        case .PROJECTILE;
            // return to player and @TODO deflect projectile
            if weapon.boomerang.status == .LEAVING then weapon.boomerang.status = .RETURNING;
            weapon.boomerang.hit_id = game.get_next_hit_id();
        case .WALL;
            if weapon.boomerang.status == .LEAVING then weapon.boomerang.status = .BOUNCING;
            weapon.boomerang.hit_id = game.get_next_hit_id();

            if weapon.boomerang.bounces.cur == weapon.boomerang.bounces.min {
                weapon.boomerang.status = .RETURNING;
                return;
            }

            // print("collision with: %\n", other);
            // print("normal: %\n", collision.normal);
            // print("velocity: %\n", weapon.boomerang.velocity);

            if length(weapon.boomerang.velocity) > 0.0
            {
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

            weapon.boomerang.bounces.cur -= 1;
    }

}

end_arena :: () {
    for context.entity_storage._Wall {
        despawn(it);
    }
    game.gameplay_paused_until = 0.5;
}
