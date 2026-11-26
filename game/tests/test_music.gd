extends TestSuite
## Every song the game asks for exists, and its loop start is inside the song (data/music.json).


func _songs_used() -> Array:
	var used := [str(GameData.music.get("menu", ""))]
	for w in GameData.world_list():
		used.append(str(w.get("music", "")))
		for s in w["stages"]:
			used.append(GameData.stage_music(s["id"]))
	return used


func test_every_song_used_exists() -> void:
	for song in _songs_used():
		check(song != "", "a song is set")
		check(ResourceLoader.exists("res://audio/music/%s.ogg" % song), "%s.ogg exists" % song)


func test_loop_starts_are_inside_the_songs() -> void:
	var starts: Dictionary = GameData.music.get("loop_start", {})
	for song in _songs_used():
		check(starts.has(song), "%s has a loop start" % song)
		var stream: AudioStream = load("res://audio/music/%s.ogg" % song)
		var start := float(starts.get(song, -1))
		check(start >= 0.0 and start < stream.get_length() - 4.0, "%s loops back to %.2f s of %.2f s" % [song, start, stream.get_length()])
