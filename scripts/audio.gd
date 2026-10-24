class_name AudioFX
extends Node

const MIX_RATE := 22050


static func make_tone(freq: float, duration: float, volume: float = 0.5, wave: String = "sine") -> AudioStreamWAV:
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / MIX_RATE
		var envelope := 1.0 - (float(i) / float(sample_count))
		var sample := _wave_sample(wave, freq, t) * envelope * volume
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))
	return _build_stream(data)


static func make_arpeggio(freqs: Array, note_duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var per_note := int(note_duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(per_note * freqs.size() * 2)
	for n in range(freqs.size()):
		var freq: float = freqs[n]
		for i in range(per_note):
			var t := float(i) / MIX_RATE
			var envelope := 1.0 - (float(i) / float(per_note))
			var sample := sin(TAU * freq * t) * envelope * volume
			var idx := (n * per_note + i) * 2
			data.encode_s16(idx, int(clamp(sample, -1.0, 1.0) * 32767.0))
	return _build_stream(data)


static func make_noise_loop(duration: float, volume: float = 0.3) -> AudioStreamWAV:
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var sample := randf_range(-1.0, 1.0) * volume
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))
	var stream := _build_stream(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


static func make_hum_loop(freq: float, duration: float, volume: float = 0.25) -> AudioStreamWAV:
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / MIX_RATE
		var sample := _wave_sample("square", freq, t) * volume
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))
	var stream := _build_stream(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


static func _wave_sample(wave: String, freq: float, t: float) -> float:
	match wave:
		"square":
			return 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0
		"triangle":
			return asin(sin(TAU * freq * t)) * (2.0 / PI)
		_:
			return sin(TAU * freq * t)


static func _build_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


func play_crash() -> void:
	_play_one_shot(make_tone(90.0, 0.35, 0.7, "square"))


func play_trick() -> void:
	_play_one_shot(make_tone(880.0, 0.15, 0.5, "triangle"))


func play_charge() -> void:
	_play_one_shot(make_tone(660.0, 0.12, 0.45, "sine"))


func play_dock() -> void:
	_play_one_shot(make_arpeggio([523.0, 659.0, 784.0], 0.14, 0.5))


func _play_one_shot(stream: AudioStreamWAV) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
