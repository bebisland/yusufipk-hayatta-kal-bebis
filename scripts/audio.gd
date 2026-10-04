extends Node
## Autoload "Audio": a small voice pool for sound effects plus the looping
## music track. Survives scene changes, so music runs from the intro into
## the game and across restarts without a gap.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_PATH := "res://assets/audio/music.ogg"
const VOICES := 16
## Same sound retriggered faster than this is dropped (auto-fire, hit spam).
const MIN_GAP := 0.045
const MUSIC_DB := -24.0

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}
var _music: AudioStreamPlayer
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -80.0
	add_child(_music)
	if ResourceLoader.exists(MUSIC_PATH):
		var s: AudioStream = load(MUSIC_PATH)
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		_music.stream = s


func play(name: String, volume_db := 0.0, pitch_jitter := 0.06) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(name, -1.0) < MIN_GAP:
		return
	_last_played[name] = now
	if not _streams.has(name):
		var path := SFX_DIR + name + ".wav"
		_streams[name] = load(path) if ResourceLoader.exists(path) else null
	var stream: AudioStream = _streams[name]
	if not stream:
		return
	var p := _free_voice()
	p.stream = stream
	p.volume_db = -24
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


## First idle voice, so long cues (wave horn, level up) are not cut off by
## rapid-fire sounds; only when all voices are busy is the oldest reused.
func _free_voice() -> AudioStreamPlayer:
	for i in VOICES:
		var p := _players[(_next + i) % VOICES]
		if not p.playing:
			_next = (_next + i + 1) % VOICES
			return p
	var oldest := _players[_next]
	_next = (_next + 1) % VOICES
	return oldest


## Starts the music if it is not running, or fades it to a new level.
func music(target_db := MUSIC_DB, fade := 1.5) -> void:
	if not _music.stream:
		return
	if not _music.playing:
		_music.play()
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", target_db, fade)
