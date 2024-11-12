package thule

import "core:math"
import "base:intrinsics"

@(require_results)
ease_out_elastic :: proc(x: $T) -> T
where intrinsics.type_is_float(T)
{
    c4 := T((2 * math.PI) / 3)

    return x == 0 ? 0 : x == 1 ? 1 : math.pow(2, -10 * x) * math.sin((x * 10.0 - 0.75) * c4) + 1
}

@(require_results)
ease_in_elastic :: proc(x: $T) -> T
where intrinsics.type_is_float(T)
{
    c4 := T((2 * math.PI) / 3)

    return x == 0 ? 0 : x == 1 ? 1 : -math.pow(2, 10 * x - 10) * math.sin((x * 10 - 10.75) * c4)
}

@(require_results)
ease_out_quad :: proc(x: $T) -> T
where intrinsics.type_is_float(T)
{
    return 1 - (1 - x) * (1 - x)
}

@(require_results)
ease_in_quad :: proc(x: $T) -> T
where intrinsics.type_is_float(T)
{
    return x * x
}

@(require_results)
ease_out_quart :: proc(x: $T) -> T
where intrinsics.type_is_float(T)
{
    return 1 - math.pow(1 - x, 4)
}

@(require_results)
ease_in_quart :: proc(x: $T) -> T
where intrinsics.type_is_float(T)
{
    return x * x * x * x
}
