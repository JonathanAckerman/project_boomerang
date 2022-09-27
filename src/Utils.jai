lerp_theta :: (a: float, b: float, t: float) -> float {
    // confine `a and `b to 0..2PI
    if a < 0    then a = 2*PI + a;
    if a > 2*PI - EPSILON then a = a - 2*PI;
    if b < 0    then b = 2*PI + b;
    if b > 2*PI - EPSILON then b = b - 2*PI;

    t2 := b-a;
    // @Jay: What is dt?
    dt := clamp(t2-floor(t2/TAU) * TAU, 0, TAU);
    return lerp(a, a + (ifx dt > PI then dt-TAU else dt), t);
}

rad2deg :: (radians) => radians*180/PI;

xy_angle :: (angle) => xy(cos(angle), sin(angle));

atan2_between :: (a, b) => atan2(a.y-b.y, a.x-b.x);

normalize_angle :: (x) => fmod(fmod(x, TAU) + TAU, TAU); // probably Bad

inside_angle :: (a, b, range) => acos(cos(a)*cos(b) + sin(a)*sin(b)) <= range/2;

rotate_vector :: (v: Vector2, radians: float) -> Vector2 {
    return xy(v.x * cos(radians) - v.y * sin(radians), v.x * sin(radians) + v.y * cos(radians));
}

// @Note: end is one past the end ala C++
array_rotate :: (first: *$T, new_first: *T, end: *T) -> *T {
    if first == new_first then return end;
    if new_first == end then return first;

    read := new_first;
    write := first;
    next_read := first;

    while (read != end) {
        if write == next_read then next_read = read;
        Swap(write, read);
        read += 1;
        write += 1;
    }

    array_rotate(write, next_read, end);
    return write;
}

triple_product :: (lhs: Vector3, rhs: Vector3) -> Vector3 {
    return cross(cross(lhs, rhs), lhs);
}

round :: (f: float) -> float {
    if f == 0 return 0;

    if f > 0 return floor(f + 0.5);
    else     return ceil(f - 0.5);
}

last :: (array: [] $T) -> T { // maybe this should return a pointer
    return array[array.count - 1];
}

max_element :: (array: [] $T) -> int {
    if array.count == 1 return 0;

    max_elem := array[0];
    max_elem_index := 0;
    for array {
        if it > max_elem {
            max_elem = it;
            max_elem_index = it_index;
        }
    }
    return max_elem_index;
}

EPSILON :: 0.0001;