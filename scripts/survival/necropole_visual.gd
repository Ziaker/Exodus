extends Node3D

const MAP := preload("res://scripts/survival/necropole_map.gd")
const GEOMETRY := preload("res://assets/generated/survival/necropole/necropole.glb")
const SKY_SHADER := preload("res://assets/generated/survival/necropole/ceu_plasma.gdshader")
const STONE_SHADER := preload("res://assets/generated/survival/necropole/pedra_ensaio.gdshader")
const PENDULUM := preload("res://assets/generated/survival/necropole/pendulo.gd")
const LAMP_COLOR := Color("#e9edf2")


func install(pivot: Node3D, camera: Camera3D) -> void:
	name = "Necropole"
	var geometry := GEOMETRY.instantiate() as Node3D
	geometry.name = "Geometry"
	geometry.position = Vector3(MAP.ORIGIN.x, 0.0, MAP.ORIGIN.y)
	add_child(geometry)
	var stone := ShaderMaterial.new()
	stone.shader = STONE_SHADER
	stone.set_shader_parameter("azul_chumbo", 0.88)
	stone.set_shader_parameter("offset_world", geometry.position)
	for child in geometry.find_children("*", "MeshInstance3D", true, false):
		(child as MeshInstance3D).material_override = stone

	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	settings.sky = Sky.new()
	var clouds := ShaderMaterial.new()
	clouds.shader = SKY_SHADER
	settings.sky.sky_material = clouds
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("#c8cfd7")
	settings.ambient_light_energy = 1.17
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	settings.fog_enabled = true
	settings.fog_light_color = Color("#49352f")
	settings.fog_density = 0.016
	settings.fog_sky_affect = 0.09
	var environment := WorldEnvironment.new()
	environment.environment = settings
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, -43.0, 0.0)
	sun.light_color = Color("#e5e6e4")
	sun.light_energy = 1.12
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 17.0
	add_child(sun)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.0, 1.12, 0.44)
	lamp.light_color = LAMP_COLOR
	lamp.light_energy = 0.77
	lamp.omni_range = 3.1
	pivot.add_child(lamp)

	var anchors: Array[Vector3] = []
	for room: String in MAP.DATA.data.checkpoints:
		var center := MAP.center(room)
		anchors.append(Vector3(center.x, 3.1, center.y + 2.8))
	var rig := PENDULUM.new()
	add_child(rig)
	rig.install(anchors, camera, LAMP_COLOR)
