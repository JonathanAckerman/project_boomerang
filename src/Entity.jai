Entity :: struct {
    using #as entity_base: Entity_Base;
    rotation_speed: Stat_Range;
    move_speed: Stat_Range;
    health: Stat_Range;
    position: Vector2;
    velocity: Vector2;
    orientation: float;
    orientation_intended: float;
}

Stat_Range :: struct {
    union { cur: int; current: int; }
    union { min: int; minimum: int; }
    union { max: int; maximum: int; }
}
