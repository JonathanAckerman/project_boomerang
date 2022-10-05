Entity :: struct {
    using #as entity_base: Entity_Base;
    rotation_speed: Stat_Range(float);
    move_speed: Stat_Range(float);
    position: Vector2;
    velocity: Vector2;
    forward: Vector2;
    forward_intended: Vector2;
    animations: [..] Animation;
    has_collider := false;
    collider: Collider; // @Jay: maybe make this an array, maybe usingas it?
    using #as rigidbody: Rigidbody;
}

Hurtable :: struct {
    health: Stat_Range(int);
}

Stat_Range :: struct(T: Type) {
    union { min: T; minimum: T; }
    union { max: T; maximum: T; }
    union { cur: T; current: T; }
}