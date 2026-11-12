extends Node2D
## Main combat loop — infinite or campaign

signal run_ended(won: bool, score: int, coins: int, kills: int)

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_container: Node2D = $Enemies
@onready var hud: CanvasLayer = $HUD
@onready var hp_bar: ProgressBar = $HUD/TopBar/HPBar
@onready var shield_bar: ProgressBar = $HUD/TopBar/ShieldBar
@onready var score_label: Label = $HUD/TopBar/ScoreLabel
@onready var wave_label: Label = $HUD/TopBar/WaveLabel
@onready var coin_label: Label = $HUD/TopBar/CoinLabel
@onready var pause_btn: Button = $HUD/PauseBtn
@onready var result_panel: PanelContainer = $HUD/ResultPanel
@onready var result_title: Label = $HUD/ResultPanel/VBox/Title
@onready var result_stats: Label = $HUD/ResultPanel/VBox/Stats
@onready var result_btn: Button = $HUD/ResultPanel/VBox/BackBtn

var player: PlayerShip
var world: Dictionary
var mode: String = "infinite"
var campaign_level: int = 1
var wave: int = 0
var score: int = 0
var run_coins: int = 0
var kills: int = 0
var spawn_timer: float = 0.0
var wave_timer: float = 0.0
var enemies_alive: int = 0
var paused: bool = false
var running: bool = false
var boss_spawned: bool = false

const PlayerScene := preload("res://scenes/player.tscn")
const EnemyScene := preload("res://scenes/enemy.tscn")
const BossScene := preload("res://scenes/boss.tscn")

func _ready() -> void:
	result_panel.visible = false
	pause_btn.pressed.connect(_toggle_pause)
	result_btn.pressed.connect(_back_to_menu)
	world = GameState.get_world()
	mode = GameState.current_mode
	_start_run()

func _start_run() -> void:
	running = true
	wave = 0
	score = 0
	run_coins = 0
	kills = 0
	boss_spawned = false
	# Spawn player
	player = PlayerScene.instantiate()
	add_child(player)
	player.global_position = player_spawn.global_position
	player.setup(GameState.get_combat_stats())
	player.died.connect(_on_player_died)
	player.hit.connect(_on_player_hit)
	_update_hud()
	_next_wave()

func _next_wave() -> void:
	wave += 1
	boss_spawned = false
	wave_timer = 18.0 + wave * 1.5
	spawn_timer = 0.8
	_update_hud()
	# Campaign: boss every 5 levels, end after 7
	if mode == "campaign" and wave > 7:
		_end_run(true)
		return

func _process(delta: float) -> void:
	if not running or paused or not is_instance_valid(player):
		return
	spawn_timer -= delta
	wave_timer -= delta
	if spawn_timer <= 0 and enemies_alive < 12 + wave:
		_spawn_enemy()
		spawn_timer = max(0.35, 1.4 - wave * 0.05)
	# Boss at end of wave timer or campaign boss wave
	if not boss_spawned and (wave_timer <= 0 or (mode == "campaign" and wave % 5 == 0 and wave_timer < 10)):
		_spawn_boss()
		boss_spawned = true
	if wave_timer <= -3.0 and enemies_alive <= 0:
		_next_wave()
	_update_hud()

func _spawn_enemy() -> void:
	var e: Enemy = EnemyScene.instantiate()
	enemy_container.add_child(e)
	var x := randf_range(30, get_viewport_rect().size.x - 30)
	e.global_position = Vector2(x, -30)
	e.setup(world, wave, false)
	e.killed.connect(_on_enemy_killed)
	enemies_alive += 1

func _spawn_boss() -> void:
	var e: Enemy = BossScene.instantiate()
	enemy_container.add_child(e)
	e.global_position = Vector2(get_viewport_rect().size.x * 0.5, -50)
	e.setup(world, wave, true)
	e.killed.connect(_on_enemy_killed)
	enemies_alive += 1

func _on_enemy_killed(e: Enemy) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	kills += 1
	score += e.score_value
	run_coins += e.coin_value
	GameState.total_kills += 1

func _on_player_died() -> void:
	_end_run(false)

func _on_player_hit(_amount: float) -> void:
	_update_hud()

func _update_hud() -> void:
	if is_instance_valid(player):
		hp_bar.max_value = player.max_hp
		hp_bar.value = player.hp
		shield_bar.max_value = max(1.0, player.max_shield)
		shield_bar.value = player.shield
	score_label.text = "Очки: %d" % score
	wave_label.text = "Волна %d" % wave
	coin_label.text = "✦ %d" % run_coins

func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	pause_btn.text = "▶" if paused else "❚❚"

func _end_run(won: bool) -> void:
	running = false
	# Apply rewards
	var mult: float = GameState.get_combat_stats().coin_mult
	var gained: int = int(run_coins * mult)
	GameState.add_coins(gained)
	GameState.add_xp(score / 4)
	if score > GameState.high_score:
		GameState.high_score = score
	if mode == "campaign" and won:
		var key := str(GameState.current_world)
		var prev: int = GameState.campaign_progress.get(key, 0)
		GameState.campaign_progress[key] = max(prev, campaign_level)
	SaveManager.save_game()
	# Show result
	result_panel.visible = true
	result_title.text = "ПОБЕДА!" if won else "ПОРАЖЕНИЕ"
	result_stats.text = "Очки: %d\nМонеты: +%d\nУбийства: %d" % [score, gained, kills]
	run_ended.emit(won, score, gained, kills)

func _back_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
