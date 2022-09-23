Entity :: struct {
    using #as entity_base: Entity_Base;
    position: Vector2;
    velocity: Vector2;
    orientation: float;
    orientation_intended: float;
    rotation_speed: float = 1;
}
