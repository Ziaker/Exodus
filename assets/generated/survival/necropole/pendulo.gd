extends Node3D
## A origem descreve um arco e a mancha se desloca no sentido contrário.

const PERIOD := 5.2
const SWING := 0.58
const CORD := 1.06

var clock := 0.0
var lamps: Array[SpotLight3D] = []
var anchors: Array[Vector3] = []
var eye: Camera3D


func install(points: Array[Vector3], observer: Camera3D, stone_light: Color) -> void:
	eye = observer
	for point in points:
		var lamp := SpotLight3D.new()
		lamp.light_color = stone_light
		lamp.light_energy = 3.05
		lamp.light_specular = 0.0
		lamp.spot_range = 8.3
		lamp.spot_angle = 33.0
		lamp.spot_attenuation = 0.64
		lamp.spot_angle_attenuation = 1.78
		lamp.shadow_enabled = true
		lamp.shadow_bias = 0.022
		lamp.shadow_normal_bias = 0.7
		add_child(lamp)
		lamps.append(lamp)
		anchors.append(point)
	place_lights()


func _process(delta: float) -> void:
	clock += delta
	place_lights()


func place_lights() -> void:
	for index in range(lamps.size()):
		var lamp := lamps[index]
		var origin := anchors[index]
		var phase := clock * TAU / PERIOD + index * TAU / float(lamps.size())
		var angle := SWING * sin(phase)
		var drift := sin(angle)
		lamp.global_position = origin + Vector3(CORD * drift, -CORD * cos(angle), 0.0)
		var reflection := origin + Vector3(-2.62 * drift, -origin.y + 0.10, -2.2)
		lamp.look_at(reflection, Vector3.UP)
		lamp.visible = eye.global_position.distance_squared_to(origin) < 15.0 * 15.0
