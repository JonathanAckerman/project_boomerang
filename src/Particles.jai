Particle_Emitter :: struct {
    is_active := true;
    position: Vector2;
    size: Vector2;
    max_particles: int;
    deactivate_timer: float;
    
    spawn_interval: float; // will spawn after X seconds
    spawn_timer: float;
    decay_interval: float; // will live for X seconds

    texture: Texture;
    start_color: Color = WHITE;
    end_color:   Color = WHITE;
    start_scale: float;
    end_scale:   float;

    particles: [..] Particle;
}

Particle :: struct {
    position: Vector2;
    velocity: Vector2;
    acceleration: Vector2;
    color: Color;
    scale: float;
    lifetime: float;
    // @TODO: rotation is tricky so lets ignore it for now
}

emit :: (using emitter: *Particle_Emitter) {
    if game.paused return;

    if is_active {
        spawn_timer -= frame.dt;

        if spawn_timer <= 0.0 {
            if particles.count < max_particles {
                particle: Particle;
                x := random_get_within_range(position.x - size.x/2.0, position.x + size.x/2.0);
                y := random_get_within_range(position.y - size.y/2.0, position.y + size.y/2.0);
                particle.position = xy(x, y);
                particle.velocity = .{0,-50};
                particle.acceleration = .{0,-100};
                particle.color = start_color;
                particle.scale = start_scale;
                array_add(*particles, particle);
            }
            spawn_timer = spawn_interval;
        }
    }
}

simulate :: (using emitter: *Particle_Emitter) {
    if game.paused return;

    deactivate_timer -= frame.dt;
    if deactivate_timer <= 0.0 then is_active = false;

    for * particles {
        it.lifetime += frame.dt;

        if it.lifetime > decay_interval {
            remove it;
        } else {
            t := it.lifetime / decay_interval;

            // @TODO: this is probably wrong because of color Value
            it.color.r = cast(u8) lerp(cast(float) start_color.r, cast(float) end_color.r, t);
            it.color.g = cast(u8) lerp(cast(float) start_color.g, cast(float) end_color.g, t);
            it.color.b = cast(u8) lerp(cast(float) start_color.b, cast(float) end_color.b, t);
            it.color.a = cast(u8) lerp(cast(float) start_color.a, cast(float) end_color.a, t);

            it.scale = lerp(start_scale, end_scale, t);

            it.position += it.velocity * frame.dt;
            it.velocity += it.acceleration * frame.dt;
        }
    }
}

render :: (using emitter: Particle_Emitter) {
    for particles {
        // @Jay: maybe we need to sort these by some metric like lifetime
        draw_texture_centered_with_rotation(texture, world_to_screen(it.position), 0.0, it.scale, it.color);
    }
}