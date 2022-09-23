Animation :: struct {
    frames: [..] AnimationFrame;
    duration: float;
    frameTimer: float;

    currentFrame := 0;
    shouldLoop := false;
    hasFinished := false;
}

AnimationFrame :: struct {
    using texture: *Texture;
    tint: Color = WHITE;
    size: Vector2;
}