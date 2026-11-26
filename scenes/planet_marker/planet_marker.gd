@tool
extends Marker3D
class_name PlanetTargetMarker

@export var planet: MaskedPlanet:
	set(v):
		planet = v
		_snap()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_snap()

func _snap() -> void:
	if not planet or not is_instance_valid(planet):
		return
	var local_pos: Vector3 = planet.to_local(global_transform.origin)
	if local_pos.length() < 0.01:
		return
	var surface_point = planet.get_surface_point(local_pos.normalized())
	global_transform.origin = planet.to_global(surface_point[0])
