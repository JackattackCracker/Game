extends CanvasLayer

@onready var crosshair:       Label = $Crosshair
@onready var interact_prompt: Label = $InteractPrompt
@onready var message_display: Label = $MessageDisplay
@onready var subtitle_label:  Label = $SubtitleLabel

const MESSAGE_DURATION  := 4.0
var _msg_timer      := 0.0
var _subtitle_timer := 0.0


func _ready() -> void:
	add_to_group("hud")
	interact_prompt.visible = false
	message_display.visible = false
	subtitle_label.visible  = false


func _process(delta: float) -> void:
	if _msg_timer > 0.0:
		_msg_timer -= delta
		if _msg_timer <= 0.0:
			message_display.visible = false

	if _subtitle_timer > 0.0:
		_subtitle_timer -= delta
		if _subtitle_timer <= 0.0:
			subtitle_label.visible = false


func show_interact_prompt(action_text: String) -> void:
	interact_prompt.text = "[E]  " + action_text
	interact_prompt.visible = true


func hide_interact_prompt() -> void:
	interact_prompt.visible = false


func show_message(text: String, duration: float = MESSAGE_DURATION) -> void:
	message_display.text = text
	message_display.visible = true
	_msg_timer = duration


# Called by EavesdropZone for overheard conversation lines.
func show_subtitle(speaker: String, text: String, duration: float) -> void:
	subtitle_label.text = speaker + ":  \"" + text + "\""
	subtitle_label.visible = true
	_subtitle_timer = duration
