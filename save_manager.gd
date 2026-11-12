extends Node

const SAVE_PATH := "user://pixelorbit_save.json"
const SAVE_VERSION := 1

func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"state": GameState.to_dict(),
		"timestamp": Time.get_unix_time_from_system(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data is Dictionary and data.has("state"):
		GameState.from_dict(data.state)

func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	# soft reset state
	GameState.from_dict({})
