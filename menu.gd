extends Control

@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var gems_label: Label = $TopBar/GemsLabel
@onready var level_label: Label = $TopBar/LevelLabel
@onready var worlds_btn: Button = $Center/VBox/WorldsBtn
@onready var infinite_btn: Button = $Center/VBox/InfiniteBtn
@onready var campaign_btn: Button = $Center/VBox/CampaignBtn
@onready var skills_btn: Button = $SideLeft/SkillsBtn
@onready var build_btn: Button = $SideLeft/BuildBtn
@onready var settings_btn: Button = $SideRight/SettingsBtn
@onready var skills_panel: PanelContainer = $SkillsPanel
@onready var build_panel: PanelContainer = $BuildPanel
@onready var world_panel: PanelContainer = $WorldPanel
@onready var skills_list: VBoxContainer = $SkillsPanel/Margin/VBox/Scroll/List
@onready var build_list: VBoxContainer = $BuildPanel/Margin/VBox/Scroll/List
@onready var world_list: VBoxContainer = $WorldPanel/Margin/VBox/Scroll/List

func _ready() -> void:
	_refresh_resources()
	GameState.resources_changed.connect(_refresh_resources)
	worlds_btn.pressed.connect(func(): _toggle_panel(world_panel))
	infinite_btn.pressed.connect(_start_infinite)
	campaign_btn.pressed.connect(_start_campaign)
	skills_btn.pressed.connect(func(): _toggle_panel(skills_panel); _build_skills_ui())
	build_btn.pressed.connect(func(): _toggle_panel(build_panel); _build_buildings_ui())
	settings_btn.pressed.connect(_on_settings)
	skills_panel.visible = false
	build_panel.visible = false
	world_panel.visible = false
	$SkillsPanel/Margin/VBox/Close.pressed.connect(func(): skills_panel.visible = false)
	$BuildPanel/Margin/VBox/Close.pressed.connect(func(): build_panel.visible = false)
	$WorldPanel/Margin/VBox/Close.pressed.connect(func(): world_panel.visible = false)
	_build_worlds_ui()

func _refresh_resources() -> void:
	coins_label.text = "✦ %d" % GameState.coins
	gems_label.text = "◆ %d" % GameState.gems
	level_label.text = "Ур. %d" % GameState.level

func _toggle_panel(p: PanelContainer) -> void:
	var was := p.visible
	skills_panel.visible = false
	build_panel.visible = false
	world_panel.visible = false
	p.visible = not was

func _start_infinite() -> void:
	GameState.current_mode = "infinite"
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _start_campaign() -> void:
	GameState.current_mode = "campaign"
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _build_skills_ui() -> void:
	for c in skills_list.get_children():
		c.queue_free()
	var order := ["dmg", "hp", "regen", "shield", "crit", "gold", "xp", "turret", "drone", "beam", "pulse", "overdrive"]
	var names := {
		"dmg": "Урон", "hp": "Здоровье", "regen": "Реген", "shield": "Щит",
		"crit": "Крит", "gold": "Монеты", "xp": "Опыт", "turret": "Турели",
		"drone": "Дроны", "beam": "Лучи", "pulse": "Импульс", "overdrive": "Разгон"
	}
	for id in order:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s  Lv.%d" % [names.get(id, id), GameState.skill_level(id)]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cost := GameState.skill_cost(id)
		var btn := Button.new()
		btn.text = "%d ✦" % cost
		btn.disabled = GameState.coins < cost
		btn.pressed.connect(_upgrade_skill.bind(id))
		row.add_child(lbl)
		row.add_child(btn)
		skills_list.add_child(row)

func _upgrade_skill(id: String) -> void:
	if GameState.upgrade_skill(id):
		SaveManager.save_game()
		_build_skills_ui()
		_refresh_resources()

func _build_buildings_ui() -> void:
	for c in build_list.get_children():
		c.queue_free()
	for type in GameState.BLD.keys():
		var def: Dictionary = GameState.BLD[type]
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s (%d/%d)\n%s" % [def.name, GameState.building_count(type), def.max, def.desc]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		btn.text = "%d✦ %d◆" % [def.cost[0], def.cost[1]]
		btn.disabled = not GameState.can_build(type)
		btn.pressed.connect(_do_build.bind(type))
		row.add_child(lbl)
		row.add_child(btn)
		build_list.add_child(row)

func _do_build(type: String) -> void:
	if GameState.build(type):
		SaveManager.save_game()
		_build_buildings_ui()
		_refresh_resources()

func _build_worlds_ui() -> void:
	for c in world_list.get_children():
		c.queue_free()
	for w in GameState.WORLDS:
		var btn := Button.new()
		var unlocked: bool = w.id in GameState.unlocked_worlds
		btn.text = "%s  %s" % [w.name, "" if unlocked else "🔒 ур.%d" % w.req_level]
		btn.disabled = not unlocked
		btn.pressed.connect(_select_world.bind(w.id))
		if GameState.current_world == w.id:
			btn.modulate = Color(0.7, 1.0, 1.0)
		world_list.add_child(btn)

func _select_world(id: int) -> void:
	GameState.current_world = id
	SaveManager.save_game()
	world_panel.visible = false
	_build_worlds_ui()

func _on_settings() -> void:
	# simple reset for now
	pass
