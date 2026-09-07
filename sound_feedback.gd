class_name SoundFeedback
extends Node

var audio_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var ambience_fade: Tween
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
	if ambience_player != null:
		ambience_player.volume_db = linear_to_db(effects_volume * 0.22)

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
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "BiomeAmbience"
	ambience_player.volume_db = linear_to_db(effects_volume * 0.22)
	add_child(ambience_player)

func _exit_tree() -> void:
	if audio_player != null:
		audio_player.stop()
		audio_player.stream = null
	if ambience_player != null:
		ambience_player.stop()
		ambience_player.stream = null

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

func play_predator_warning() -> void:
	_queue_tone(120.0, 0.22, 0.16)
	_queue_tone(95.0, 0.28, 0.12)

func play_predator_attack() -> void:
	_queue_tone(170.0, 0.08, 0.2)
	_queue_tone(110.0, 0.16, 0.16)

func play_weather_toggle(enabled: bool) -> void:
	if enabled:
		_queue_tone(280.0, 0.12, 0.08)
		_queue_tone(360.0, 0.16, 0.06)
	else:
		_queue_tone(360.0, 0.12, 0.07)
		_queue_tone(240.0, 0.16, 0.05)

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
	_play_biome_ambience(biome)

func _play_biome_ambience(biome: String) -> void:
	if ambience_player == null:
		return
	var file_name := "Grassy Field Loop.wav"
	if biome.find("Wetland") >= 0 or biome.find("Marsh") >= 0 or biome.find("Cypress") >= 0:
		file_name = "Rain Forest Loop.wav"
	elif biome.find("Glacier") >= 0:
		file_name = "Hail Storm Loop.wav"
	elif biome.find("Ridge") >= 0 or biome.find("Highland") >= 0 or biome.find("Dunes") >= 0 or biome.find("Volcanic") >= 0:
		file_name = "Wind Loop.wav"
	var path := "res://Sound FX Starter Pack Vol. 1/Environment/%s" % file_name
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	if ambience_player.stream == stream and ambience_player.playing:
		return
	if ambience_fade != null and ambience_fade.is_valid():
		ambience_fade.kill()
	var target_db := linear_to_db(effects_volume * 0.22)
	if ambience_player.playing:
		ambience_fade = create_tween()
		ambience_fade.tween_property(ambience_player, "volume_db", -48.0, 1.0)
		ambience_fade.tween_callback(_start_ambience_stream.bind(stream, target_db))
	else:
		_start_ambience_stream(stream, target_db)

func _start_ambience_stream(stream: AudioStream, target_db: float) -> void:
	ambience_player.stream = stream
	ambience_player.volume_db = -48.0
	ambience_player.play()
	ambience_fade = create_tween()
	ambience_fade.tween_property(ambience_player, "volume_db", target_db, 1.0)

func play_landmark_discovery() -> void:
	_queue_tone(294.0, 0.12, 0.08)
	_queue_tone(440.0, 0.18, 0.09)

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
