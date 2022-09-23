Creature :: struct {
    using #as entity: Entity;
    speed: float;
}

simulate :: (using creature: *Creature, dt: float) {
    if game.paused then return;

    orientation = lerp_theta(orientation, orientation_intended, rotation_speed * dt);
    position += velocity * dt;
}

render :: (using creature: *Creature) {
    DrawCircleV(position, UNIT_SCALE, BLUE);
    LINE_LENGTH_BACK :: 4;
    LINE_LENGTH_FRONT :: 16;
    back_point := xy(cos(orientation), sin(orientation)) * LINE_LENGTH_BACK;
    front_point := xy(cos(orientation), sin(orientation)) * LINE_LENGTH_FRONT;
    DrawLineV(position + back_point, position + front_point, RED);
}

CT_PLAYER :: Creature.{
    speed = 150
};

UNIT_SCALE :: 12;
