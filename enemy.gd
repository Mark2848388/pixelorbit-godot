extends CharacterBody2D
class_name Enemy

signal killed(enemy: Enemy)

@export var base_hp: float = 12.0
@export var base_speed: float = 80.0
@export var base_damage: float = 6.0
@export var score_value: int = 10
@export var coin_value: int = 2

var hp: float = 12.0
var max_hp: float = 12.0
var speed: float = 80.0
var damage: float = 6.0
var frozen: float = 0.0
var is_boss: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func setup(world: Dictionary, wave: int, boss: bool = false) -> void:
	is_boss = boss
	var hp_m: float = world.get("hp_mult", 1.0)
	var dmg_m: float = world.get("dmg_mult", 1.0)
	var spd_m: float = world.get("speed", 1.0)
	if boss:
		max_hp = base_hp * 18.0 * hp_m * (1.0 + wave * 0.08)
		speed = base_speed * 0.55 * spd_m
		damage = base_damage * 2.2 * dmg_m
		score_value = 200 + wave * 20
		coin_value = 25 + wave * 3
		scale = Vector2(1.8, 1.8)
		if sprite:
			sprite.modulate = Color(1.0, 0.4, 1.0)
	else:
		max_hp = base_hp * hp_m * (1.0 + wave * 0.12)
		speed = base_speed * spd_m * (1.0 + wave * 0.02)
		damage = base_damage * dmg_m * (1.0 + wave * 0.05)
		score_value = 10 + wave
		coin_value = 1 + int(wave / 5)
	hp = max_hp
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if frozen > 0:
		frozen -= delta
		modulate = Color(0.5, 0.8, 1.0)
		return
	modulate = Color.WHITE
	# Move toward bottom / player area
	velocity = Vector2(0, speed)
	# slight horizontal wobble
	velocity.x = sin(Time.get_ticks_msec() * 0.003 + position.x * 0.01) * 30.0
	move_and_slide()
	# Off screen bottom
	if global_position.y > get_viewport_rect().size.y + 40:
		queue_free()

func take_damage(amount: float) -> void:
	hp -= amount
	modulate = Color(1.5, 1.5, 1.5)
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(self):
		modulate = Color.WHITE
	if hp <= 0:
		killed.emit(self)
		queue_free()

func freeze(duration: float) -> void:
	frozen = max(frozen, duration)

func _on_body_entered(body: Node) -> void:
	if body is PlayerShip:
		body.take_damage(damage)
		if not is_boss:
			queue_free()
