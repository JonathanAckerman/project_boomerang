Entity :: struct {
    using #as entity_base: Entity_Base;
    rotation_speed: Range(float);
    move_speed: Range(float);
    position: Vector2;
    velocity: Vector2;
    forward: Vector2 = .{1, 0};
    forward_intended: Vector2 = .{1, 0};
    animations: [..] Animation;
    has_collider := false;
    collider: Collider; // @Jay: maybe make this an array, maybe usingas it?
    has_rigidbody := false; // perhaps these should be pointers to an Entity array of T
    using #as rigidbody: Rigidbody;
    entity_type: Entity_Type; // lets us get the type out of a *void in a collision callback
}

Entity_Type :: enum {
    CREATURE;
    WALL;
    PROJECTILE;
}

Hurtable :: struct {
    health: Range(int);
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

Range :: struct(T: Type) {
    union { min: T; minimum: T; start: T; }
    union { cur: T; current: T; }
    union { max: T; maximum: T; end: T; }
}