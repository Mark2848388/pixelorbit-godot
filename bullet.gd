extends Area2D

var direction: Vector2 = Vector2.UP
var speed: float = 520.0
var damage: float = 5.0
var crit_chance: float = 0.05
var crit_mult: float = 2.0
var is_player: bool = true
var lifetime: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	# Off screen
	var rect := get_viewport_rect()
	if position.y < -20 or position.y > rect.size.y + 20 or position.x < -20 or position.x > rect.size.x + 20:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if is_player and body is Enemy:
		var dmg := damage
		if randf() < crit_chance:
			dmg *= crit_mult
		body.take_damage(dmg)
		queue_free()
	elif not is_player and body is PlayerShip:
		body.take_damage(damage)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# optional shield / other areas
	pass
