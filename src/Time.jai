Slowmo :: struct {
    is_active := false;
    scale: float;

    attack:  float;
    sustain: float;
    decay:   float;

    attack_duration:  float;
    decay_duration:   float;
}

simulate :: (using slowmo: *Slowmo) {
    if !is_active return;

    if !attack_duration then attack_duration = attack;
    if !decay_duration then decay_duration = decay;

    if attack > 0.0 {
        attack -= frame.dt;
        frame.scale = lerp(1.0, scale, 1.0 - attack/attack_duration);
    }
    else if sustain > 0.0 {
        sustain -= frame.dt;
        frame.scale = scale;
    }
    else if decay > 0.0 {
        decay -= frame.dt;
        frame.scale = lerp(scale, 1.0, 1.0 - decay/decay_duration);
    }
    else {
        is_active = false;
        frame.scale = 1.0;
    }
}