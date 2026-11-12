extends Node
## Global game state — mirrors original Pixel Orbit data structures

signal resources_changed
signal skills_changed
signal buildings_changed
signal world_unlocked(world_id: int)

# Resources
var coins: int = 0
var gems: int = 0
var parts: int = 0
var energy: int = 50
var max_energy: int = 50

# Progress
var level: int = 1
var xp: int = 0
var xp_to_next: int = 100
var high_score: int = 0
var total_kills: int = 0

# Current run
var current_world: int = 0
var current_mode: String = "infinite"  # infinite | campaign
var campaign_progress: Dictionary = {}  # world_id -> max_level_cleared

# Skills (levels)
var skills: Dictionary = {
	"dmg": 0,
	"hp": 0,
	"regen": 0,
	"shield": 0,
	"crit": 0,
	"gold": 0,
	"xp": 0,
	"mine": 0,
	"turret": 0,
	"drone": 0,
	"beam": 0,
	"pulse": 0,
	"overdrive": 0,
}

# Buildings placed (simplified: list of {type, level})
var buildings: Array = []

# Unlocked worlds
var unlocked_worlds: Array = [0]

# Worlds definition (close to original)
var WORLDS: Array = [
	{
		"id": 0, "name": "СОЛНЕЧНАЯ", "desc": "Начало пути. Слабые враги, мягкий свет.",
		"bg": [Color("1a2a4a"), Color("0d1525")], "accent": Color("7ec8ff"),
		"hp_mult": 1.0, "dmg_mult": 1.0, "speed": 1.0, "req_level": 1
	},
	{
		"id": 1, "name": "КРИСТАЛЛ", "desc": "Острые грани и сильный щит врагов.",
		"bg": [Color("2a1a4a"), Color("150d25")], "accent": Color("c88aff"),
		"hp_mult": 1.4, "dmg_mult": 1.1, "speed": 1.1, "req_level": 5
	},
	{
		"id": 2, "name": "ПУСТЫНЯ", "desc": "Жара ускоряет всё. Быстрые волны.",
		"bg": [Color("4a2a1a"), Color("25150d")], "accent": Color("ffaa55"),
		"hp_mult": 1.6, "dmg_mult": 1.3, "speed": 1.35, "req_level": 10
	},
	{
		"id": 3, "name": "ТОКСИК", "desc": "Яд снижает реген. Осторожно.",
		"bg": [Color("1a4a2a"), Color("0d2515")], "accent": Color("55ff88"),
		"hp_mult": 2.0, "dmg_mult": 1.5, "speed": 1.2, "req_level": 16
	},
	{
		"id": 4, "name": "ВОЙД", "desc": "Темнота. Враги почти невидимы.",
		"bg": [Color("1a1a2a"), Color("050510")], "accent": Color("aa88ff"),
		"hp_mult": 2.5, "dmg_mult": 1.8, "speed": 1.4, "req_level": 24
	},
	{
		"id": 5, "name": "ЯДРО", "desc": "Финальный сектор. Боссы меняют тактику.",
		"bg": [Color("3a1a2a"), Color("150510")], "accent": Color("ff5588"),
		"hp_mult": 3.2, "dmg_mult": 2.2, "speed": 1.5, "req_level": 35
	},
]

# Building types
var BLD: Dictionary = {
	"gen": {"name": "КУЗНИЦА", "max": 3, "cost": [80, 0], "desc": "+кредиты в бою"},
	"lab": {"name": "БАШНЯ МАГОВ", "max": 2, "cost": [150, 15], "desc": "+опыт"},
	"tur": {"name": "СТРАЖЕВАЯ", "max": 4, "cost": [60, 5], "desc": "+турели"},
	"dome": {"name": "ЩИТ ЗАМКА", "max": 1, "cost": [200, 25], "desc": "+щит"},
	"bay": {"name": "КАЗАРМЫ", "max": 3, "cost": [180, 20], "desc": "+урон помощников"},
	"array": {"name": "БАТАРЕЯ", "max": 3, "cost": [220, 30], "desc": "+лучи"},
}

func _ready() -> void:
	SaveManager.load_game()

func get_world(id: int = -1) -> Dictionary:
	if id < 0:
		id = current_world
	if id >= 0 and id < WORLDS.size():
		return WORLDS[id]
	return WORLDS[0]

func add_coins(amount: int) -> void:
	coins += amount
	resources_changed.emit()

func add_xp(amount: int) -> void:
	var mult := 1.0 + skills.get("xp", 0) * 0.15
	xp += int(amount * mult)
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(100 * pow(1.15, level - 1))
		# unlock worlds by level
		for w in WORLDS:
			if w.req_level <= level and w.id not in unlocked_worlds:
				unlocked_worlds.append(w.id)
				world_unlocked.emit(w.id)
	resources_changed.emit()

func skill_level(id: String) -> int:
	return skills.get(id, 0)

func skill_cost(id: String) -> int:
	var lv: int = skill_level(id)
	return 50 + lv * 40 + lv * lv * 10

func upgrade_skill(id: String) -> bool:
	if not skills.has(id):
		return false
	var cost := skill_cost(id)
	if coins < cost:
		return false
	coins -= cost
	skills[id] += 1
	skills_changed.emit()
	resources_changed.emit()
	return true

func building_count(type: String) -> int:
	var c := 0
	for b in buildings:
		if b.type == type:
			c += 1
	return c

func can_build(type: String) -> bool:
	if not BLD.has(type):
		return false
	var def: Dictionary = BLD[type]
	if building_count(type) >= def.max:
		return false
	var cost: Array = def.cost
	return coins >= cost[0] and gems >= cost[1]

func build(type: String) -> bool:
	if not can_build(type):
		return false
	var def: Dictionary = BLD[type]
	coins -= def.cost[0]
	gems -= def.cost[1]
	buildings.append({"type": type, "level": 1})
	buildings_changed.emit()
	resources_changed.emit()
	return true

func get_combat_stats() -> Dictionary:
	## Calculate effective combat bonuses from skills + buildings
	var s := {
		"dmg": 4.0 + skill_level("dmg") * 1.5,
		"hp": 40.0 + skill_level("hp") * 12.0,
		"regen": 0.3 + skill_level("regen") * 0.25,
		"shield": 10.0 + skill_level("shield") * 8.0,
		"crit": 0.05 + skill_level("crit") * 0.04,
		"crit_dmg": 2.0,
		"coin_mult": 1.0 + skill_level("gold") * 0.2,
		"turret": skill_level("turret") * 0.5,
		"drone": skill_level("drone"),
		"beam": skill_level("beam"),
		"pulse": 10.0 + skill_level("pulse") * 6.0,
		"damage_mult": 1.0 + skill_level("overdrive") * 0.05,
	}
	for b in buildings:
		match b.type:
			"gen":
				s.coin_mult += 0.15 * b.level
			"lab":
				pass  # xp handled elsewhere
			"tur":
				s.turret += 0.6 * b.level
			"dome":
				s.shield += 18.0 * b.level
			"bay":
				s.damage_mult += 0.04 * b.level
			"array":
				s.beam += 0.5 * b.level
	return s

func to_dict() -> Dictionary:
	return {
		"coins": coins,
		"gems": gems,
		"parts": parts,
		"energy": energy,
		"max_energy": max_energy,
		"level": level,
		"xp": xp,
		"xp_to_next": xp_to_next,
		"high_score": high_score,
		"total_kills": total_kills,
		"skills": skills.duplicate(),
		"buildings": buildings.duplicate(true),
		"unlocked_worlds": unlocked_worlds.duplicate(),
		"campaign_progress": campaign_progress.duplicate(),
	}

func from_dict(d: Dictionary) -> void:
	coins = d.get("coins", 0)
	gems = d.get("gems", 0)
	parts = d.get("parts", 0)
	energy = d.get("energy", 50)
	max_energy = d.get("max_energy", 50)
	level = d.get("level", 1)
	xp = d.get("xp", 0)
	xp_to_next = d.get("xp_to_next", 100)
	high_score = d.get("high_score", 0)
	total_kills = d.get("total_kills", 0)
	skills = d.get("skills", skills)
	buildings = d.get("buildings", [])
	unlocked_worlds = d.get("unlocked_worlds", [0])
	campaign_progress = d.get("campaign_progress", {})
	resources_changed.emit()
