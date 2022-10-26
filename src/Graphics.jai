draw_texture_centered_with_rotation :: (frame: Animation_Frame, pos: Vector2, rotation: float, is_screen_space: bool = false)
{
    scale := frame.size.x / frame.texture.width;
    pos_to_center := frame.size/2;
    if !is_screen_space {
        pos_to_center *= game.camera.zoom;
        scale *= game.camera.zoom;
    }
    rotated_pos_to_center := rotate_vector(pos_to_center, -rotation);
    drawpos := pos - rotated_pos_to_center;
    DrawTextureEx(frame.texture, drawpos, -rad2deg(rotation), scale, frame.tint);
}

draw_texture_centered_with_rotation :: (texture: Texture, pos: Vector2, rotation: float, scale: float, color: Color)
{
    pos_to_center := scale * xy(xx texture.width, xx texture.height) / 2.0;
    rotated_pos_to_center := rotate_vector(pos_to_center, -rotation);
    drawpos := pos - rotated_pos_to_center;
    DrawTextureEx(texture, drawpos, -rad2deg(rotation), scale, color);
}

ss :: world_to_screen;
world_to_screen :: (world: Vector2) -> screen: Vector2 {
    to_ss_vector := WINDOW_CENTER - game.camera.position * game.camera.zoom;
    return world * game.camera.zoom + to_ss_vector;
}

draw_buffer: [..] Draw_Buffer_Item;

Draw_Buffer_Item :: struct {
    traunch: Draw_Traunch;
    type: item_type;
    item_type :: enum { ANIM; TEXTURE; DEBUG; TEXT; }
    union {
        using animation: struct {
            position: Vector2;
            rotation: float;
            frame: Animation_Frame;
        }
        texture: struct {
            texture: *Texture;
            position: Vector2;
            rotation: float;
            color: Color;
            scale: float;
        }
        debug: struct {
            debug_shape :: enum { CIRCLE; LINE; RECT; }
            shape: debug_shape;
            position: Vector2;
            radius: float;
            end_point: Vector2;
            size: Vector2;
            color: Color;
        }
        text: struct {
            font: Font;
            str: string;
            position: Vector2;
            origin: Vector2;
            size: float;
            spacing: float;
            color: Color;
            rotation: float;
        }
    }
}

Draw_Traunch :: enum {
    BACKGROUND;
    ENTITY;
    WORLD_UI;
    SCREEN_UI;
    DEBUG;
    EDITOR;
}

add_to_draw_buffer :: (shape: Draw_Buffer_Item.debug.debug_shape, position: Vector2, radius: float, color: Color) {
    buffered: Draw_Buffer_Item;
    buffered.debug.shape = shape;
    buffered.debug.position = position;
    buffered.debug.radius = radius;
    buffered.debug.color = color;
    buffered.traunch = .DEBUG;
    buffered.type = .DEBUG;
    array_add(*draw_buffer, buffered);
}
add_to_draw_buffer :: (shape: Draw_Buffer_Item.debug.debug_shape, position: Vector2, end_point: Vector2, color: Color) {
    buffered: Draw_Buffer_Item;
    buffered.debug.shape = shape;
    buffered.debug.position = position;
    if shape == .LINE then buffered.debug.end_point = end_point;
    else buffered.debug.size = end_point;
    buffered.debug.color = color;
    buffered.traunch = .DEBUG;
    buffered.type = .DEBUG;
    array_add(*draw_buffer, buffered);
}

add_to_draw_buffer :: (frame: Animation_Frame, position: Vector2, traunch: Draw_Traunch, forward: Vector2, scale: float = 1.0) {
    buffered: Draw_Buffer_Item;
    buffered.frame = frame;
    buffered.frame.size *= scale;
    buffered.position = position;
    buffered.rotation = atan2(-forward.y, forward.x);
    buffered.traunch = traunch;
    buffered.type = .ANIM;
    array_add(*draw_buffer, buffered);
}
add_to_draw_buffer :: (texture: *Texture, position: Vector2, traunch: Draw_Traunch, forward: Vector2, color: Color, scale: float = 1.0) {
    buffered: Draw_Buffer_Item;
    buffered.texture.texture = texture;
    buffered.texture.position = position;
    buffered.texture.rotation = atan2(-forward.y, forward.x);
    buffered.texture.color = color;
    buffered.texture.scale = scale;
    buffered.traunch = traunch;
    buffered.type = .TEXTURE;
    array_add(*draw_buffer, buffered);
}

add_to_draw_buffer :: (traunch: Draw_Traunch, font: Font, str: string, position: Vector2, origin: Vector2, size: float, spacing: float, color: Color, rotation: float = 0) {
    buffered: Draw_Buffer_Item;
    buffered.traunch = traunch;
    buffered.text.font = font;
    buffered.text.str = str;
    buffered.text.position = position;
    buffered.text.origin = origin;
    buffered.text.size = size;
    buffered.text.spacing = spacing;
    buffered.text.color = color;
    buffered.text.rotation = rotation;
    buffered.type = .TEXT;
    array_add(*draw_buffer, buffered);
}