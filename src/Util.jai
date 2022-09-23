lerp_theta :: (a: float, b: float, t: float) -> float {
    t2 := b-a;
    dt := clamp(t2-floor(t2/TAU) * TAU, 0, TAU);
    return lerp(a, a + (ifx dt > PI then dt-TAU else dt), t);
}

rad2deg :: (radians) => radians*180/PI;

xy_angle :: (angle) => xy(cos(angle), sin(angle));

atan2_between :: (a, b) => atan2(a.y-b.y, a.x-b.x);

normalize_angle :: (x) => fmod(fmod(x, TAU) + TAU, TAU); // probably Bad

inside_angle :: (a, b, range) => acos(cos(a)*cos(b) + sin(a)*sin(b)) <= range/2;
