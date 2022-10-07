game: struct {
    resetting: bool;
    paused: bool;
    state: Game_State;
    dt: float;

    player: Handle(Creature);
    camera: struct {
        zoom := 1.0;
        position: Vector2;
    }

    collision_system: struct {
        hitboxes: [..] Hitbox;
        hurtboxes: [..] Hurtbox;
        collideboxes: [..] Collidebox;
    }
}

Game_State :: enum {
    INITIAL;
}

game_loop :: inline () {
    using game;
    using context.entity_storage;
    dt = GetFrameTime();

    // simulate ----------------------------------------------------------------
    handle_input();

    simulate();

    handle_collision();

    // draw --------------------------------------------------------------------
    BeginDrawing();

    ClearBackground(DARKGRAY);

    for _Creature render(it);

    DrawFPS(0, 0);

    {
        cstr := temp_c_string("PROJECT BOOMERANG");
        measure := MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1);
        DrawTextPro(the_font, cstr, .{WINDOW_WIDTH-2, WINDOW_HEIGHT-2}, measure, 0, xx the_font.baseSize, 1, WHITE);
    }

    EndDrawing();


    // cleanup -----------------------------------------------------------------
    cleanup_despawning_entities();
    reset_temporary_storage();
}

game_reset :: () {
    using game;
    log("RESETTING GAME");
    reset_entity_storage();
    load_all_animations();

    game = .{};
    array_reserve(*game.collision_system.hitboxes, 1024);
    array_reserve(*game.collision_system.hurtboxes, 1024);
    array_reserve(*game.collision_system.collideboxes, 1024);

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
        player = spawn(c);

        c = Creatures.SMALL_FRY;
        c.position = .{300, 300};
        c.collider.position = c.position;
        array_add(*c.animations, NewAnimation("small_fry/idle"));
        spawn(c);

        c = Creatures.MEDIUM_FRY;
        c.position = .{500, 400};
        c.collider.position = c.position;
        array_add(*c.animations, NewAnimation("medium_fry/idle"));
        spawn(c);

        c = Creatures.BIG_FRY;
        c.position = .{700, 500};
        c.collider.position = c.position;
        array_add(*c.animations, NewAnimation("big_fry/idle"));
        spawn(c);
    }
}

simulate :: () {
    using game;
    using context.entity_storage;
    
    for _Creature simulate(it);

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
    log("Enemy is being damaged for %", hit.damage);
    if hurtable.health.cur > hurtable.health.min then hurtable.health.cur -= hit.damage;
    if hurtable.health.cur <= 0 {
        log("Enemy was killed");
    }
}

boomerang_on_collision :: (owner: *void, collision: Collision) {
    other := cast(*Entity) collision.other;
    if !other.rigidbody.is_static return;

    player := cast(*Creature) owner;
    if player.weapon.boomerang.status == .LEAVING then player.weapon.boomerang.status = .RETURNING;
}
boomerang_on_hit :: (hurtable: *Hurtable, hit: Hit) {
    log("The boomerang hit something!"); // note "hit" != "collide"
}