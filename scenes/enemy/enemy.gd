extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $Untitled/AnimationPlayer


@export var planet: MaskedPlanet
@export var SPEED := 3.0
@export var target_marker: Node3D

var path: PackedVector3Array = []
var path_index: int = 0
var final_target_global: Vector3
var previous_location = Vector3(0,0,0)

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	if target_marker:
		update_target_location(target_marker.global_transform.origin)

func _physics_process(delta: float) -> void:
	var animation_changes = false
	var on_final_leg := path_index >= path.size()
	var target_global: Vector3 = final_target_global if on_final_leg else planet.to_global(path[path_index])

	var current_location: Vector3 = global_transform.origin
	var to_target: Vector3 = target_global - current_location

	var local_pos: Vector3 = planet.to_local(current_location)
	up_direction = (planet.global_transform.basis * local_pos.normalized())

	var tangential: Vector3 = to_target.slide(up_direction) # ignore height mismatch

	if tangential.length() < 0.2:
		velocity = Vector3.ZERO
		update_animation(false) # Force IDLE when reaching target
		animation_changes  = true
		
		if on_final_leg:
			set_physics_process(false)
			return
		path_index += 1
		return

	velocity = tangential.normalized() * SPEED
	move_and_slide()

	var new_local: Vector3 = planet.to_local(global_transform.origin)
	global_transform.origin = planet.to_global(planet.get_surface_point(new_local.normalized())[0])

	if tangential.length() > 0.1:
		look_at(global_transform.origin + tangential, up_direction)

	# Calculate actual displacement moved this frame
	var distance_moved := global_transform.origin.distance_to(previous_location)
	previous_location = global_transform.origin

	# Play animation based on actual displacement
	if animation_changes == true:
		update_animation(distance_moved > 0.01)
	print(animation_player.current_animation)


func update_animation(is_moving: bool) -> void:
	if is_moving:
		if animation_player.current_animation != "IDLE":
			animation_player.play("IDLE??")
	else:
		if animation_player.current_animation != "MOVING":
			animation_player.play("MOVING")

func update_target_location(target_location_global: Vector3) -> void:
	final_target_global = target_location_global
	set_physics_process(true)
	var from_local: Vector3 = planet.to_local(global_transform.origin)
	var to_local: Vector3 = planet.to_local(target_location_global)
	path = planet.GetPath(from_local, to_local)
	path_index = 0
