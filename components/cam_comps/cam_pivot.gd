extends Node3D
@export var cam_distance:float
@export var mouse_sensitivity := 0.003
@export var max_zoom_in := 2.0  # minimal distance (closest)
@export var max_zoom_out := 10.0  # maximal distance (farthest)
@export var zoom_speed := 0.5     # step per wheel tick
var dragging = false
@export var friction := 4.0          # higher = stops coasting faster
@export var pitch_limit_deg := 89.0  # stop it flipping over the top
var zoom_dist := 0.0
@onready var cam = $Camera3D

func _ready():
	cam.position.z = -cam_distance
	zoom_dist = -cam.transform.origin.z
	_clamp_zoom()

func _clamp_zoom():
	zoom_dist = clamp(zoom_dist,(max_zoom_in),(max_zoom_out))
	var t = cam.transform
	t.origin.z = -zoom_dist
	cam.transform = t


var rot_velocity := Vector2.ZERO
var mouse_delta := Vector2.ZERO

var yaw = 0.0
var pitch = 0.0

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_dist -= zoom_speed
			_clamp_zoom()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_dist += zoom_speed
			_clamp_zoom()
	elif event is InputEventMouseMotion and dragging:
		mouse_delta += event.relative

func _process(delta):
	if dragging:
		rot_velocity = mouse_delta * mouse_sensitivity
		mouse_delta = Vector2.ZERO
	else:
		rot_velocity = rot_velocity.lerp(Vector2.ZERO, clamp(friction * delta, 0, 1))

	yaw -= rot_velocity.x
	pitch += rot_velocity.y   
	pitch = clamp(pitch, deg_to_rad(-pitch_limit_deg), deg_to_rad(pitch_limit_deg))

	rotation = Vector3(pitch, yaw, 0)
