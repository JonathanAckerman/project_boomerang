Entity :: struct {
    using #as entity_base: Entity_Base;
    rotation_speed: Stat_Range_f;
    move_speed: Stat_Range_f;
    position: Vector2;
    velocity: Vector2;
    forward: Vector2;
    forward_intended: Vector2;
    animation: Animation;
}

Stat_Range :: struct {
    union { min: int; minimum: int; }
    union { max: int; maximum: int; }
    union { cur: int; current: int; }
}
Stat_Range_f :: struct {
    union { min: float; minimum: float; }
    union { max: float; maximum: float; }
    union { cur: float; current: float; }
}
