class_name SoundFeedback
extends Node

var audio_player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var tone_queue: Array[Dictionary] = []
var active_tone: Dictionary = {}
var phase := 0.0
var elapsed := 0.0
var effects_volume := 0.7
const MIX_RATE := 22050.0

func set_effects_volume(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0)
	if audio_player != null:
		audio_player.volume_db = linear_to_db(effects_volume)

func get_effects_volume() -> float:
	return effects_volume

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.12
	audio_player.stream = generator
	audio_player.volume_db = -13.0
	add_child(audio_player)
	audio_player.play()
	playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _exit_tree() -> void:
	if audio_player != null:
		audio_player.stop()
		audio_player.stream = null

func _process(_delta: float) -> void:
	if playback == null and audio_player != null:
		playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	for frame in playback.get_frames_available():
		playback.push_frame(Vector2.ONE * _next_sample())

func play_food() -> void:
	_queue_tone(660.0, 0.07, 0.22)
	_queue_tone(880.0, 0.09, 0.18)

func play_ability() -> void:
	_queue_tone(390.0, 0.11, 0.23)
	_queue_tone(585.0, 0.13, 0.2)

func play_quest_reward() -> void:
	_queue_tone(523.0, 0.1, 0.2)
	_queue_tone(659.0, 0.1, 0.2)
	_queue_tone(784.0, 0.16, 0.22)

func play_growth() -> void:
	_queue_tone(440.0, 0.1, 0.18)
	_queue_tone(660.0, 0.14, 0.22)

func play_warning() -> void:
	_queue_tone(220.0, 0.16, 0.18)

func play_environment_cue(biome: String) -> void:
	var base := 180.0
	if biome.find("Wetland") >= 0 or biome.find("Marsh") >= 0:
		base = 260.0
	elif biome.find("Ridge") >= 0 or biome.find("Highland") >= 0 or biome.find("Volcanic") >= 0:
		base = 135.0
	elif biome.find("Glacier") >= 0:
		base = 330.0
	_queue_tone(base, 0.18, 0.08)
	_queue_tone(base * 1.25, 0.24, 0.06)

func _queue_tone(frequency: float, duration: float, volume: float) -> void:
	tone_queue.append({"frequency": frequency, "duration": duration, "volume": volume})

func _next_sample() -> float:
	if active_tone.is_empty():
		if tone_queue.is_empty():
			return 0.0
		active_tone = tone_queue.pop_front()
		phase = 0.0
		elapsed = 0.0
	var duration := float(active_tone["duration"])
	var frequency := float(active_tone["frequency"])
	var volume := float(active_tone["volume"])
	var envelope := sin(PI * clampf(elapsed / duration, 0.0, 1.0))
	var sample := sin(phase) * volume * envelope
	phase += TAU * frequency / MIX_RATE
	elapsed += 1.0 / MIX_RATE
	if elapsed >= duration:
		active_tone.clear()
	return sample
