Particle_Emitter :: struct {
    texture: Texture;
    is_active := true;
    position: Vector2;
    size: Vector2;
    max_particles:   int;
    alive_particles: int;
    deactivate_timer: float;
    
    spawn_timer: float;
    spawn_interval: float; // will spawn a particle after X seconds
    decay_interval: float; // will live for X seconds

    start_color: Color = WHITE;
    end_color:   Color = WHITE;
    start_scale: float;
    end_scale:   float;
    start_velocity: Vector2;
    speed_noise: Range(float);
    direction_noise: Range(float);
    acceleration:   Vector2;
}

Particle :: struct {
    lifetime: float;
    position: Vector2;
    velocity: Vector2;
    color: Color;
    scale: float;

    emitter: *Particle_Emitter;
}

emit :: (using emitter: *Particle_Emitter) {
    if game.paused return;

    if is_active {
        spawn_timer -= frame.dt;

        if spawn_timer <= 0.0 {
            if alive_particles < max_particles {
                p: Particle;
                p.lifetime = decay_interval;
                x := random_get_within_range(position.x - size.x/2.0, position.x + size.x/2.0);
                y := random_get_within_range(position.y - size.y/2.0, position.y + size.y/2.0);
                p.position = xy(x, y);
                d := random_get_within_range(direction_noise.min, direction_noise.max);
                direction := rotate_vector(start_velocity, d);
                speed := random_get_within_range(speed_noise.min, speed_noise.max);
                p.velocity = direction * speed;
                p.color = start_color;
                p.scale = start_scale;
                p.emitter = emitter;
                array_add(*game.particle_system.particles, p);
                alive_particles += 1;
            }
            spawn_timer = spawn_interval;
        }
    }
}

simulate :: (using emitter: *Particle_Emitter) {
    if game.paused return;
    if deactivate_timer then deactivate_timer -= frame.dt;
    if deactivate_timer < 0.0 then is_active = false;
    // @TODO: think about how to clean up emitters that we're done with vs. ones we might use again
}

simulate :: (using particle: *Particle) {
    if game.paused return;
    
    lifetime -= frame.dt;
    t := 1.0 - lifetime / emitter.decay_interval;

    // @TODO: this is probably wrong because of color Value
    color.r = cast(u8) lerp(cast(float) emitter.start_color.r, cast(float) emitter.end_color.r, t);
    color.g = cast(u8) lerp(cast(float) emitter.start_color.g, cast(float) emitter.end_color.g, t);
    color.b = cast(u8) lerp(cast(float) emitter.start_color.b, cast(float) emitter.end_color.b, t);
    color.a = cast(u8) lerp(cast(float) emitter.start_color.a, cast(float) emitter.end_color.a, t);

    scale = lerp(emitter.start_scale, emitter.end_scale, t);

    position += velocity * frame.dt;
    velocity += emitter.acceleration * frame.dt;
}

render :: (using particle: Particle) {
    // @Jay: maybe we need to sort these by some metric like lifetime
    // draw_texture_centered_with_rotation(emitter.texture, world_to_screen(position), 0.0, scale, color);
    add_to_draw_buffer(*emitter.texture, position, .WORLD_UI, .{0,-1}, color, scale);
}