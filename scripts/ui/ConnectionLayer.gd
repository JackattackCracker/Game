extends Control

# Draws red string lines between clue cards on the board.
# Lives inside CorkboardPane — shares the same coordinate space as CardsLayer.

var _lines: Array[Dictionary] = []


func clear() -> void:
	_lines.clear()
	queue_redraw()


func add_line(from: Vector2, to: Vector2, is_deduction: bool = false) -> void:
	_lines.append({"from": from, "to": to, "deduction": is_deduction})
	queue_redraw()


func highlight_line(from: Vector2, to: Vector2) -> void:
	for line in _lines:
		if line["from"].is_equal_approx(from) and line["to"].is_equal_approx(to):
			line["deduction"] = true
			queue_redraw()
			return


func _draw() -> void:
	for line in _lines:
		var col := Color(0.85, 0.72, 0.1, 0.95) if line["deduction"] \
				else Color(0.62, 0.16, 0.12, 0.85)
		draw_line(line["from"], line["to"], col, 2.5, true)
