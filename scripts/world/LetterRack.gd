extends StaticBody3D

# Delivers plot letters based on flags. Each letter delivered exactly once.

@export var letters_file: String = ""
@export var rack_label:   String = "Check for letters"


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interact_label", rack_label)


func interact() -> void:
	if letters_file == "":
		return

	var file := FileAccess.open(letters_file, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()

	var hud := get_tree().get_first_node_in_group("hud")
	var delivered_any := false

	for letter in json.data.get("letters", []):
		var req: String = letter.get("requires_flag", "")
		if req != "" and not GameManager.get_flag(req):
			continue
		var del_flag: String = letter.get("delivered_flag", "")
		if del_flag != "" and GameManager.get_flag(del_flag):
			continue

		# Deliver the letter
		var lid: String = letter.get("id", "")
		GameManager.add_journal_entry("letter", letter.get("content", ""), lid)

		var board_label: String = letter.get("board_label", "")
		if board_label != "" and lid != "":
			GameManager.add_board_clue(lid, board_label, "letter")

		if del_flag != "":
			GameManager.set_flag(del_flag, true)

		var item_id: String = letter.get("item_id", "")
		if item_id != "":
			GameManager.add_item(item_id)

		delivered_any = true

	if hud:
		hud.show_message("You have new correspondence." if delivered_any else "No new letters.")
