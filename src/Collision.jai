Collider :: struct {
    shape: Collider_Shape;
    position: Vector2;
    union {
        radius: float;
        size: Vector2;
    }
}
Collider_Shape :: enum { CIRCLE; RECT; }

Rigidbody :: struct {
    is_static := true;
    mass := 999;
}

Hit :: struct {
    damage: int;
    damage_type: Damage_Type;
}
Damage_Type :: enum {
    NORMAL;
    FIRE;
    OCCULT;
}
make_hit :: (damage: int, damage_type: Damage_Type = .NORMAL) -> Hit {
    hit: Hit;
    hit.damage = damage;
    hit.damage_type = damage_type;
    return hit;
}

Hitbox :: struct {
    using #as collider: Collider;
    hit: Hit;
}
produce_hitbox :: (collider: Collider, hit: Hit) {
    hitbox: Hitbox;
    hitbox.collider = collider;
    hitbox.hit = hit;
    array_add(*game.collision_system.hitboxes, hitbox);
}

Hurtbox :: struct {
    using #as collider: Collider;
    hurtable: *Hurtable;
    on_hit: (*Hurtable, Hit);
}
produce_hurtbox :: (collider: Collider, hurtable: *Hurtable, on_hit: (*Hurtable, Hit)) {
    hurtbox: Hurtbox;
    hurtbox.collider = collider;
    hurtbox.hurtable = hurtable;
    hurtbox.on_hit = on_hit;
    array_add(*game.collision_system.hurtboxes, hurtbox);
}

Collision :: struct {

}

Collidebox :: struct {
    using #as collider: Collider;
    owner: *void;
    on_collide: (*void, Collision);
}
produce_collidebox :: (collider: Collider, owner: *void, on_collide: (*void, Collision)) {
    collidebox: Collidebox;
    collidebox.collider = collider;
    collidebox.owner = owner;
    collidebox.on_collide = on_collide;
    array_add(*game.collision_system.collideboxes, collidebox);
}

handle_collision :: () {
    using game.collision_system;

    for * a: collideboxes {
        for * b: collideboxes {
            if a == b || !a.on_collide continue;
            is_colliding, collision := check_collision(a, b);
            if is_colliding {
                a.on_collide(a.owner, collision);
            }
        }
    }
    for * hitbox: hitboxes {
        for * hurtbox: hurtboxes {
            if check_hit(hitbox, hurtbox) {
                if hurtbox.on_hit then hurtbox.on_hit(hurtbox.hurtable, hitbox.hit);
                else log("no on_hit defined!!");
            }
        }
    }
    array_reset_keeping_memory(*hitboxes);
    array_reset_keeping_memory(*hurtboxes);
    array_reset_keeping_memory(*collideboxes);
}

check_collision :: (a: *Collidebox, b: *Collidebox) -> bool, Collision {
    collision: Collision;
    is_colliding := distance(a.position, b.position) <= a.radius + b.radius;
    if is_colliding { /* fill out collision */ }
    return is_colliding, collision;
}

check_hit :: (hitbox: *Hitbox, hurtbox: *Hurtbox) -> bool {
    return check_intersection(hitbox, hurtbox);
}

check_intersection :: (a: *Collider, b: *Collider) -> bool {
    if #complete a.shape == {
        case .CIRCLE; if #complete b.shape == {
            case .CIRCLE; return circle_circle(a, b);
            case .RECT;   return aabb_circle(b, a);
        }
        case .RECT; if #complete b.shape == {
            case .CIRCLE; return aabb_circle(a, b);
            case .RECT;   return aabb_aabb(a, b);
        }
    }

    circle_circle :: inline (a, b) => distance(a.position, b.position) <= a.radius + b.radius;
    // @Jay: if these dont modify they should pass by value
    aabb_aabb :: inline (a: *Collider, b: *Collider) -> bool {
        a_lower_left  := a.position - a.size/2.0;
        a_upper_right := a.position + a.size/2.0;
        b_lower_left  := a.position - a.size/2.0;
        b_upper_right := a.position + a.size/2.0;
        return !(b_lower_left.x > a_upper_right.x 
                || b_upper_right.x < a_lower_left.x 
                || b_upper_right.y > a_lower_left.y 
                || b_lower_left.y < a_upper_right.y);
    }
    aabb_circle :: inline (r: *Collider, c: *Collider) -> bool {
        half_size := r.size/2.0;
        displacement := c.position - r.position;
        closest_x := r.position.x + clamp(displacement.x, -half_size.x, half_size.x);
        closest_y := r.position.y + clamp(displacement.y, -half_size.y, half_size.y);

        circle_to_closest := c.position - xy(closest_x, closest_y);
        if length(circle_to_closest) < c.radius
        {
            return true;
            // overlap_scalar := c.radius - length(circle_to_closest);
            // if c.rigidBody.mass < r.rigidBody.mass
            // {
            //     if shouldResolve then c.position += unit_vector(circle_to_closest) * overlap_scalar;
            //     return true;
            // }
        }
        return false;
    }
}