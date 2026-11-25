extends Node3D

@export var title := ""
@export_range(1, 9) var map_number := 1
## Width along local X and depth along local Z, in game metres.
@export var footprint := Vector2(8.0, 8.0)
@export var name_distance := 8.0


func distance_from_outline(world_point: Vector3) -> float:
	var local := to_local(world_point)
	var outside := Vector2(absf(local.x), absf(local.z)) - footprint * 0.5
	return Vector2(maxf(0.0, outside.x), maxf(0.0, outside.y)).length()
