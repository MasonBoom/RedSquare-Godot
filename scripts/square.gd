extends Node3D

@onready var walker = $Player
@onready var hud = $Interface/Overlay
@onready var air: AudioStreamPlayer = $SquareAir


func _ready() -> void:
	walker.set_spawn($Spawn)
	var sights := get_tree().get_nodes_in_group("landmarks")
	sights.sort_custom(func(a, b): return a.map_number < b.map_number)
	hud.setup(walker, sights)
	air.finished.connect(air.play)
	air.play()
