Entity :: struct {
    using #as entity_base: Entity_Base;
    rotation_speed: Stat_Range_f;
    move_speed: Stat_Range_f;
    health: Stat_Range;
    position: Vector2;
    velocity: Vector2;
    orientation: float; // this should maybe be a forward vector instead
    orientation_intended: float;
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
