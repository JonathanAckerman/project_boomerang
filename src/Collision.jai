Collider :: struct {
    shape: Collider_Shape;
    position: Vector2;
    union {
        radius: float;
        size: Vector2;
    }
    was_colliding := false;
}
Collider_Shape :: enum { CIRCLE; RECT; }

Rigidbody :: struct {
    is_static := true;
    mass := 999;
    is_ghost := false;
}

Hit :: struct {
    damage: int;
    damage_type: Damage_Type;
    id: Hit_ID;
    tick_rate: float64;
}
Damage_Type :: enum {
    NORMAL;
    FIRE;
    OCCULT;
}
make_hit :: (id: Hit_ID, damage: int, damage_type: Damage_Type = .NORMAL, tick_rate: float64) -> Hit {
    hit: Hit;
    hit.damage = damage;
    hit.damage_type = damage_type;
    hit.id = id;
    hit.tick_rate = tick_rate;
    return hit;
}

Hitbox :: struct {
    using #as collider: Collider;
    owner: *void;
    hit: Hit;
    // on_hit_landed maybe? in order to feedback details of the hit/hurt
}
produce_hitbox :: (collider: Collider, owner: *void, hit: Hit) {
    hitbox: Hitbox;
    hitbox.collider = collider;
    hitbox.owner = owner;
    hitbox.hit = hit;
    array_add(*game.collision_system.hitboxes, hitbox);
}

Hurtbox :: struct {
    using #as collider: Collider;
    hurtable: *Hurtable;
    owner: *void;
    on_hit: (*Hurtable, Hit); // on_get_hurt maybe?
}
produce_hurtbox :: (collider: Collider, hurtable: *Hurtable, owner: *void, on_hit: (*Hurtable, Hit)) {
    hurtbox: Hurtbox;
    hurtbox.collider = collider;
    hurtbox.hurtable = hurtable;
    hurtbox.owner = owner;
    hurtbox.on_hit = on_hit;
    array_add(*game.collision_system.hurtboxes, hurtbox);
}

Collision :: struct {
    other: *void;
    projection: Vector2;
    normal:     Vector2;
}

Collidebox :: struct {
    using #as collider: Collider;
    owner: *void;
    on_collision_started: (*void, Collision);
    on_collision:         (*void, Collision);
}
produce_collidebox :: (collider: Collider, 
                       owner: *void, 
                       on_collision_started: (*void, Collision) = null, 
                       on_collision:         (*void, Collision) = null) {
    collidebox: Collidebox;
    collidebox.collider = collider;
    collidebox.owner    = owner;
    collidebox.on_collision_started = on_collision_started;
    collidebox.on_collision         = on_collision;
    array_add(*game.collision_system.collideboxes, collidebox);
}

Catalystbox :: struct {
    using #as collider: Collider;
    owner: *void;
}
produce_catalystbox :: (collider: Collider, owner: *void) {
    catalystbox: Catalystbox;
    catalystbox.collider = collider;
    catalystbox.owner = owner;
    array_add(*game.collision_system.catalystboxes, catalystbox);
}

Triggerbox :: struct {
    using #as collider: Collider;
    owner: *void;
    on_trigger: (Catalystbox, Triggerbox);
}
produce_triggerbox :: (collider: Collider, owner: *void, on_trigger: (Catalystbox, Triggerbox)) {
    triggerbox: Triggerbox;
    triggerbox.collider = collider;
    triggerbox.owner = owner;
    triggerbox.on_trigger = on_trigger;
    array_add(*game.collision_system.triggerboxes, triggerbox);
}

handle_collision :: () {
    using game.collision_system;

    for * a: collideboxes {
        is_colliding := false;

        for * b: collideboxes {
            if a == b || a.owner == b.owner continue;
            is_colliding_with_b, collision := check_collision(a, b);

            // Collision
            if is_colliding_with_b {
                if a.on_collision then a.on_collision(a.owner, collision);

                // Collision Started
                if !a.was_colliding {
                    if a.on_collision_started then a.on_collision_started(a.owner, collision);
                }
                is_colliding = true;
            }
        }

        (cast(*Entity) a.owner).collider.was_colliding = is_colliding;
    }

    for * hitbox: hitboxes {
        for * hurtbox: hurtboxes {
            if hitbox.owner == hurtbox.owner || !hurtbox.on_hit continue;
            if check_hit(hitbox, hurtbox) {
                hurtbox.on_hit(hurtbox.hurtable, hitbox.hit);
            }
        }
    }

    for * catalyst: catalystboxes {
        for * trigger: triggerboxes {
            if catalyst.owner == trigger.owner || !trigger.on_trigger continue;
            if check_intersection(catalyst, trigger) {
                trigger.on_trigger(catalyst, trigger);
            }
        }
    }
}

check_collision :: (a: *Collidebox, b: *Collidebox) -> bool, Collision {
    collision: Collision;
    collision.other = b.owner;
    is_colliding, projection, normal := check_intersection(a, b);
    if is_colliding { 
        collision.projection = projection; 
        collision.normal = normal;
    }
    return is_colliding, collision;
}

check_hit :: (hitbox: *Hitbox, hurtbox: *Hurtbox) -> bool {
    return check_intersection(hitbox, hurtbox);
}

check_intersection :: (a: *Collider, b: *Collider) -> bool, Vector2, Vector2 {
    is_overlapping: bool; projection: Vector2; normal: Vector2;
    if #complete a.shape == {
        case .CIRCLE; if #complete b.shape == {
            case .CIRCLE; 
                is_overlapping, projection, normal = circle_circle(a, b);
            case .RECT;
                is_overlapping, projection, normal = aabb_circle(b, a);
        }
        case .RECT; if #complete b.shape == {
            case .CIRCLE;
                is_overlapping, projection, normal = aabb_circle(a, b);
            case .RECT;
                is_overlapping, normal = aabb_aabb(a, b);
        }
    }
    return is_overlapping, projection, normal;

    circle_circle :: inline (a: *Collider, b: *Collider) -> bool, Vector2, Vector2 {
        displacement := a.position - b.position;
        distance := length(displacement);
        overlap_scalar := (a.radius + b.radius) - distance;

        is_overlapping := distance < (a.radius + b.radius);
        normal := unit_vector(displacement);
        projection := normal * overlap_scalar;
        return is_overlapping, projection, normal;
    }
    // @Jay: if these dont modify they should pass by value
    aabb_aabb :: inline (a: *Collider, b: *Collider) -> bool, Vector2 {
        normal: Vector2;
        a_lower_left  := a.position - a.size/2.0;
        a_upper_right := a.position + a.size/2.0;
        b_lower_left  := a.position - a.size/2.0;
        b_upper_right := a.position + a.size/2.0;

        b_right_of_a := b_lower_left.x > a_upper_right.x;
        b_left_of_a := b_upper_right.x < a_lower_left.x;
        b_below_a := b_upper_right.y > a_lower_left.y;
        b_above_a := b_lower_left.y < a_upper_right.y;

        is_overlapping := !(b_right_of_a || b_left_of_a || b_below_a || b_above_a);
        if is_overlapping {
            b_on_right  := abs(a_upper_right.x - b_lower_left.x);
            b_on_left   := abs(a_lower_left.x - b_upper_right.x);
            b_on_top    := abs(a_upper_right.y - b_lower_left.y);
            b_on_bottom := abs(a_lower_left.y - b_upper_right.y);

            x_min := min(b_on_right, b_on_left);
            y_min := min(b_on_bottom, b_on_top);
            if x_min < y_min {
                normal = ifx b_on_right < b_on_left then Vector2.{-1,0} else .{1,0};
            } else {
                normal = ifx b_on_bottom < b_on_top then Vector2.{0,-1} else .{0,1};
            }
        }

        return is_overlapping, normal;
    }
    aabb_circle :: inline (r: *Collider, c: *Collider) -> bool, Vector2, Vector2 {
        half_size := r.size/2.0;
        displacement := c.position - r.position;
        closest_x := r.position.x + clamp(displacement.x, -half_size.x, half_size.x);
        closest_y := r.position.y + clamp(displacement.y, -half_size.y, half_size.y);

        circle_to_closest := c.position - xy(closest_x, closest_y);
        if length(circle_to_closest) < c.radius
        {
            overlap_scalar := c.radius - length(circle_to_closest);
            projection := unit_vector(circle_to_closest) * overlap_scalar;
            normal: Vector2;

            if closest_x == r.position.x - r.size.x/2.0 then normal = .{-1,0};
            if closest_x == r.position.x + r.size.x/2.0 then normal = .{1,0};
            if closest_y == r.position.y - r.size.y/2.0 then normal = .{0,-1};
            if closest_y == r.position.y + r.size.y/2.0 then normal = .{0,1};

            normal = unit_vector(normal);
            return true, projection, normal;
        }
        return false, .{}, .{};
    }
}