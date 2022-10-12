Entity :: struct {
    using #as entity_base: Entity_Base;
    rotation_speed: Stat_Range(float);
    move_speed: Stat_Range(float);
    position: Vector2;
    velocity: Vector2;
    forward: Vector2 = .{1, 0};
    forward_intended: Vector2 = .{1, 0};
    animations: [..] Animation;
    has_collider := false;
    collider: Collider; // @Jay: maybe make this an array, maybe usingas it?
    has_rigidbody := false; // perhaps these should be pointers to an Entity array of T
    using #as rigidbody: Rigidbody;
}

Hurtable :: struct {
    health: Stat_Range(int);
    hit_blocks: [..] Block_Info;
}
Block_Info :: struct {
    hit_id: Hit_ID;
    end_time: float64;
}
make_block :: (hit_id: Hit_ID, end_time: float64) -> Block_Info {
    block: Block_Info;
    block.hit_id = hit_id;
    block.end_time = end_time;
    return block;
}

Stat_Range :: struct(T: Type) {
    union { min: T; minimum: T; }
    union { max: T; maximum: T; }
    union { cur: T; current: T; }
}