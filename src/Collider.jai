Collider :: struct {
    shape: Collider_Shape;
    type: Collider_Type;
    position: Vector2;
    union {
        radius: float;
        size: Vector2;
    }
    is_colliding := false;
}

Collider_Type :: enum {
    PHYSICS;
    HURT;
    HIT;
}

Collider_Shape :: enum {
    CIRCLE;
    RECT;
}