extends CharacterBody2D
class_name PlayerShip

signal died
signal hit(amount: float)

@export var speed: float = 280.0
@export var fire_rate: float = 0.18

var stats: Dictionary = {}
var hp: float = 40.0
var max_hp: float = 40.0
var shield: float = 0.0
var max_shield: float = 0.0
var fire_cd: float = 0.0
var invuln: float = 0.0
var pulse_cd: float = 0.0
var freeze_cd: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func setup(combat_stats: Dictionary) -> void:
	stats = combat_stats
	max_hp = stats.hp
	hp = max_hp
	max_shield = stats.shield
	shield = max_shield
	fire_rate = max(0.08, 0.22 - stats.get("beam", 0) * 0.01)

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	# Movement — horizontal only (mobile friendly)
	var dir := 0.0
	if Input.is_action_pressed("move_left"):
		dir -= 1.0
	if Input.is_action_pressed("move_right"):
		dir += 1.0
	# Touch / mouse
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mx := get_global_mouse_position().x
		if abs(mx - global_position.x) > 8:
			dir = sign(mx - global_position.x)
	velocity.x = dir * speed
	velocity.y = 0
	move_and_slide()
	# Clamp to screen
	var half := get_viewport_rect().size.x * 0.5
	global_position.x = clamp(global_position.x, 24, get_viewport_rect().size.x - 24)
	# Auto fire
	fire_cd -= delta
	if fire_cd <= 0:
		_fire()
		fire_cd = fire_rate
	# Regen
	if shield < max_shield:
		shield = min(max_shield, shield + stats.regen * delta * 0.5)
	elif hp < max_hp:
		hp = min(max_hp, hp + stats.regen * delta)
	invuln = max(0.0, invuln - delta)
	pulse_cd = max(0.0, pulse_cd - delta)
	freeze_cd = max(0.0, freeze_cd - delta)
	# Abilities
	if Input.is_action_just_pressed("ability_1") and pulse_cd <= 0:
		_pulse()
	if Input.is_action_just_pressed("ability_2") and freeze_cd <= 0:
		_freeze()

func _fire() -> void:
	var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
	var b: Node2D = bullet_scene.instantiate()
	b.global_position = global_position + Vector2(0, -18)
	b.direction = Vector2.UP
	b.damage = stats.dmg * stats.damage_mult
	b.crit_chance = stats.crit
	b.crit_mult = stats.crit_dmg
	b.is_player = true
	get_parent().add_child(b)
	# extra beams
	var beams: int = int(stats.get("beam", 0))
	if beams >= 1:
		var b2: Node2D = bullet_scene.instantiate()
		b2.global_position = global_position + Vector2(-12, -12)
		b2.direction = Vector2(-0.15, -1).normalized()
		b2.damage = stats.dmg * 0.7 * stats.damage_mult
		b2.is_player = true
		get_parent().add_child(b2)
	if beams >= 2:
		var b3: Node2D = bullet_scene.instantiate()
		b3.global_position = global_position + Vector2(12, -12)
		b3.direction = Vector2(0.15, -1).normalized()
		b3.damage = stats.dmg * 0.7 * stats.damage_mult
		b3.is_player = true
		get_parent().add_child(b3)

func _pulse() -> void:
	pulse_cd = 8.0
	# damage all nearby enemies
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.global_position.distance_to(global_position) < 160:
			e.take_damage(stats.pulse)

func _freeze() -> void:
	freeze_cd = 12.0
	for e in get_tree().get_nodes_in_group("enemies"):
		e.freeze(2.5)

func take_damage(amount: float) -> void:
	if invuln > 0 or hp <= 0:
		return
	if shield > 0:
		var absorbed: float = min(shield, amount)
		shield -= absorbed
		amount -= absorbed
	if amount > 0:
		hp -= amount
		invuln = 0.6
		hit.emit(amount)
		modulate = Color(1, 0.4, 0.4)
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(self):
			modulate = Color.WHITE
	if hp <= 0:
		died.emit()
		queue_free()

func heal(amount: float) -> void:
	hp = min(max_hp, hp + amount)
