extends Node

# Simple audio manager. Autoloaded at /root/AudioManager.
# Handles SFX (fire-and-forget), looping music, and looping ambient layers.

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Master"
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = &"Master"
	add_child(_ambient_player)


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func play_music(stream: AudioStream, volume_db: float = -6.0) -> void:
	if not stream or _music_player.stream == stream:
		return
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()


func play_ambient(stream: AudioStream, volume_db: float = -10.0) -> void:
	if not stream:
		return
	_ambient_player.stream = stream
	_ambient_player.volume_db = volume_db
	_ambient_player.play()


func stop_music() -> void:
	_music_player.stop()


func stop_ambient() -> void:
	_ambient_player.stop()
