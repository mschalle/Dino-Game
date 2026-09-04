class_name SoundFeedback
extends Node

var audio_player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var tone_queue: Array[Dictionary] = []
var active_tone: Dictionary = {}
var phase := 0.0
var elapsed := 0.0
const MIX_RATE := 22050.0

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
