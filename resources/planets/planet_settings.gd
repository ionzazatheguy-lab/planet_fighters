@tool
extends Resource
class_name PlanetSettings

@export var radius: float = 10.0:
	set(v):
		radius = v
		emit_changed()

@export_range(16, 256) var resolution: int = 128:
	set(v):
		resolution = v
		emit_changed()

@export_group("Mountains")
@export var mountain_height: float = 2.0:
	set(v):
		mountain_height = v
		emit_changed()

@export var mountain_exponent: float = 2.5:
	set(v):
		mountain_exponent = v
		emit_changed()

@export var terrain_noise: FastNoiseLite = FastNoiseLite.new():
	set(v):
		terrain_noise = v
		# If the noise itself changes (like frequency), bubble that update up
		if terrain_noise and not terrain_noise.changed.is_connected(emit_changed):
			terrain_noise.changed.connect(emit_changed)
		emit_changed()

@export_group("Continents")
@export var continent_mask: FastNoiseLite = FastNoiseLite.new():
	set(v):
		continent_mask = v
		if continent_mask and not continent_mask.changed.is_connected(emit_changed):
			continent_mask.changed.connect(emit_changed)
		emit_changed()

@export var mask_sharpness: float = 1.0:
	set(v):
		mask_sharpness = v
		emit_changed()
		
@export var nav_subdiv: int = 4:
	set(v):
		nav_subdiv = v
		emit_changed()
