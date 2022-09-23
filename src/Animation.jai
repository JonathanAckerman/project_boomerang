Animation :: struct {
    frames: [..] Animation_Frame;
    duration: float;
    frame_timer: float;

    current_frame := 0;
    should_loop := false;
    has_finished := false;
}

Animation_Frame :: struct {
    using texture: *Texture;
    tint: Color = WHITE;
    size: Vector2;
}