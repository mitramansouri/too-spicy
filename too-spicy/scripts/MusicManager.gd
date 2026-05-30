extends Node

const MENU_MUSIC_PATH := "res://sounds/main_menu.mp3"
const GAME_MUSIC_PATH := "res://sounds/bgmusik.mp3"

const MENU_MUSIC_VOLUME_DB := -6.0
const GAME_MUSIC_VOLUME_DB := -6.0
const PAUSED_VOLUME_DB := -18.0

var player: AudioStreamPlayer = null
var current_track_key := ""
var normal_volume_db := -6.0


func _ready():
	print("MusicManager ready")
	
	ensure_player_exists()
func play_template_music(template_id: String, music_path: String, volume_db: float = GAME_MUSIC_VOLUME_DB):
	play_track("template_" + template_id, music_path, volume_db)

func ensure_player_exists():
	if player != null:
		return

	player = AudioStreamPlayer.new()
	player.name = "GlobalMusicPlayer"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = "Master"
	add_child(player)

	print("Music player created")


func play_menu_music():
	play_track("menu", MENU_MUSIC_PATH, MENU_MUSIC_VOLUME_DB)


func play_game_music():
	play_track("game", GAME_MUSIC_PATH, GAME_MUSIC_VOLUME_DB)


func play_track(track_key: String, path: String, volume_db: float):
	ensure_player_exists()

	print("Trying to play music: ", path)

	if current_track_key == track_key and player.playing:
		print("Music already playing: ", track_key)
		player.volume_db = volume_db
		normal_volume_db = volume_db
		return

	var loaded_resource: Resource = load(path)

	if loaded_resource == null:
		push_warning("Could not load music: " + path)
		print("FAILED: music file not found")
		return

	if not loaded_resource is AudioStream:
		push_warning("Music file is not an AudioStream: " + path)
		print("FAILED: file is not AudioStream")
		return

	var audio_stream: AudioStream = loaded_resource as AudioStream
	make_stream_loop(audio_stream)

	current_track_key = track_key
	normal_volume_db = volume_db

	player.stream = audio_stream
	player.volume_db = volume_db
	player.play()

	print("Music started: ", track_key)
	print("Player playing: ", player.playing)
	print("Volume db: ", player.volume_db)


func make_stream_loop(audio_stream: AudioStream):
	if audio_stream is AudioStreamOggVorbis:
		var ogg_stream := audio_stream as AudioStreamOggVorbis
		ogg_stream.loop = true

	elif audio_stream is AudioStreamMP3:
		var mp3_stream := audio_stream as AudioStreamMP3
		mp3_stream.loop = true

	elif audio_stream is AudioStreamWAV:
		var wav_stream := audio_stream as AudioStreamWAV
		wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD


func dim_for_pause():
	ensure_player_exists()
	player.volume_db = PAUSED_VOLUME_DB


func restore_after_pause():
	ensure_player_exists()
	player.volume_db = normal_volume_db


func stop_music():
	ensure_player_exists()
	player.stop()
	current_track_key = ""
