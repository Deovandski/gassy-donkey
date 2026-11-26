extends Node
## Plays sound effects and music. Effects: game/audio/sfx/<name>.wav; music: game/audio/music/<name>.ogg,
## the 2014 BIDU songs made into loops by tools/make_bidu_music.py. Each song plays its intro once, then
## repeats from its loop start (data/music.json "loop_start").
## Volumes come from the save's settings (music, sfx: 0 to 1).

const SFX_DIR := "res://audio/sfx/"
const MUSIC_DIR := "res://audio/music/"
const VOICES := 8

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_name := ""
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)
	apply_volumes()
	SaveManager.changed.connect(apply_volumes)


func apply_volumes() -> void:
	_set_bus("Music", float(SaveManager.setting("music")))
	_set_bus("SFX", float(SaveManager.setting("sfx")))


static func _set_bus(bus: String, volume: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_mute(i, volume <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(volume, 0.001)))


func play(sfx_name: String, pitch := 1.0, volume_db := 0.0) -> void:
	var stream := _load(SFX_DIR + sfx_name + ".wav")
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


## One of the four farts, picked at random, with a slightly random pitch.
func fart() -> void:
	play("fart_%d" % randi_range(1, 4), randf_range(0.9, 1.15))


func music(track: String) -> void:
	if track == _music_name and _music.playing:
		return
	_music_name = track
	var stream := _load(MUSIC_DIR + track + ".ogg")
	if stream is AudioStreamOggVorbis:
		stream.loop = true
		stream.loop_offset = float(GameData.music.get("loop_start", {}).get(track, 0.0))
	_music.stream = stream
	if stream:
		_music.play()


## The menus' song.
func menu_music() -> void:
	music(str(GameData.music.get("menu", "")))


func stop_music() -> void:
	_music_name = ""
	_music.stop()


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]
