extends Node

## Save Data Constants and Variables
const SAVE_KEY_VOLUMES : String = "volumes"
const SAVE_KEY_BGM_PROGRESS : String = "bgm_progress"

const SAVE_KEY_MASTER : String = "master"
const SAVE_KEY_BGM : String = "bgm"
const SAVE_KEY_SFX : String = "sfx"
const SAVE_KEY_DIALOGUE : String = "dialogue"

const META_FINISH_DETECTION : String = "finish_detection"
const META_BASE_VOLUME : String = "base_volume_linear"
const META_KEY : String = "sound_key"

## Volume Constants and Variables
const BUS_MASTER : String = "Master"
const BUS_BGM : String = "BGM"
const BUS_SFX : String = "SFX"
const BUS_DIALOGUE : String = "Dialogue"
const MIN_SAFE_LINEAR : float = 0.0001

var master_volume_linear : float = 1.0
var bgm_volume_linear : float = 1.0
var sfx_volume_linear : float = 1.0
var dialogue_volume_linear : float = 1.0

## BGM Constants and Variables
const DEFAULT_FADE_TIME : float = 0.35
const MIN_FADE_DB : float = -80.0
const RESUME_END_CLOSE_ENOUGH : float = 0.06

var bgm_player_a : AudioStreamPlayer = null
var bgm_player_b : AudioStreamPlayer = null
var bgm_is_a_active : bool = true
var bgm_active_track_key : String = ""
var bgm_progress_by_track : Dictionary = {}
var bgm_stream_by_key : Dictionary = {}
var bgm_fade_tween : Tween = null
var bgm_active_player : AudioStreamPlayer = null

## SFX Constants and Variables
const DEFAULT_SFX_POOL_SIZE : int = 24
const DEFAULT_SFX_POLYPHONY : int = 4
const DEFAULT_SFX_PITCH_JITTER : float = 0.02
const DEFAULT_SFX_MIN_INTERVAL : float = 0.02

var sfx_players_pool : Array[AudioStreamPlayer] = []
var sfx_active_players_by_key : Dictionary = {}
var sfx_last_play_time_by_key : Dictionary = {}
var sfx_rng : RandomNumberGenerator = RandomNumberGenerator.new()

## Dialogue Constants and Variables
const DEFAULT_DIALOGUE_POOL_SIZE : int = 12
const DEFAULT_DIALOGUE_POLYPHONY : int = 1
const DEFAULT_DIALOGUE_PITCH_JITTER : float = 0.06
const DEFAULT_DIALOGUE_MIN_INTERVAL : float = 0.03

var dialogue_players_pool : Array[AudioStreamPlayer] = [] as Array[AudioStreamPlayer]
var dialogue_active_players_by_key : Dictionary = {}
var dialogue_last_play_time_by_key : Dictionary = {}
var dialogue_rng : RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	# TODO Pulls audio save data.
	var audio_save_data : Dictionary = {}
	# Ensures sounds run while paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Setup systems.
	_setup_bgm()
	_setup_sfx()
	_setup_dialogue()
	load_audio_data(audio_save_data)

## Outputs all audio-related save data.
func save_audio_data() -> Dictionary:
	var data : Dictionary = {}
	data[SAVE_KEY_VOLUMES] = _get_volume_save_data()
	data[SAVE_KEY_BGM_PROGRESS] = get_bgm_progress_save_data()
	return data

## Loads all audio-related save data. If empty, will assume defaults.
func load_audio_data(incoming_data : Dictionary) -> void:
	# Apply saved volumes if data has it, otherwise apply defaults.
	if incoming_data.has(SAVE_KEY_VOLUMES) : _set_volume_save_data(incoming_data[SAVE_KEY_VOLUMES])
	else : _apply_all_bus_volumes()

	# Apply saved BGM progress if data has it, otherwise clear BGM progress.
	if incoming_data.has(SAVE_KEY_BGM_PROGRESS) : set_bgm_progress_save_data(incoming_data[SAVE_KEY_BGM_PROGRESS])
	else : clear_bgm_progress()

## Small helper class to enable awaits.
class FinishDetection extends RefCounted:
	signal finished(incoming_key : String)
	
	var sfx_key : String = ""
	var is_completed : bool = false
	
	func complete() -> void:
		if is_completed : return
		is_completed = true
		finished.emit(sfx_key)

## Triggers the custom finished signal.
func _complete_audio_player(incoming_player : AudioStreamPlayer) -> void:
	if !incoming_player : return
	
	if incoming_player.has_meta(META_FINISH_DETECTION):
		var finish_detection : FinishDetection = incoming_player.get_meta(META_FINISH_DETECTION) as FinishDetection
		if finish_detection : finish_detection.complete()
	
	# Disconnect to avoid double-calls on reused players.
	if incoming_player.finished.is_connected(_on_sfx_player_finished):
		incoming_player.finished.disconnect(_on_sfx_player_finished)
	if incoming_player.finished.is_connected(_on_dialogue_player_finished):
		incoming_player.finished.disconnect(_on_dialogue_player_finished)

# ---- Volume Methods
## Attempts to set the the requested bus volume from the requested linear value between (0..1).
func set_bus_volume_linear(incoming_bus_name : String, incoming_linear : float) -> void:
	# Ensures the incoming_linear stays between (0..1).
	var clamped_linear : float = clamp(incoming_linear, 0.0, 1.0)
	
	# Attempts to find a match for the requested bus, then saves the incoming_linear.
	#	Aborts if bus isn't found.
	match incoming_bus_name:
		BUS_MASTER : master_volume_linear = clamped_linear
		BUS_BGM : bgm_volume_linear = clamped_linear
		BUS_SFX : sfx_volume_linear = clamped_linear
		BUS_DIALOGUE : dialogue_volume_linear = clamped_linear
		_ : return
	
	# Apply the volume to the bus if valid match.
	_apply_bus_volume_linear(incoming_bus_name, clamped_linear)

## Returns with the audio volume data as a [Dictionary].
func _get_volume_save_data() -> Dictionary:
	return {
		SAVE_KEY_MASTER: master_volume_linear,
		SAVE_KEY_BGM: bgm_volume_linear,
		SAVE_KEY_SFX: sfx_volume_linear,
		SAVE_KEY_DIALOGUE: dialogue_volume_linear,
	}

## Sets the volume according to the incoming data, if it exists. Otherwise, assume defaults.
func _set_volume_save_data(incoming_data : Dictionary) -> void:
	if incoming_data.has(SAVE_KEY_MASTER) : master_volume_linear = clamp(float(incoming_data[SAVE_KEY_MASTER]), 0.0, 1.0)
	if incoming_data.has(SAVE_KEY_BGM) : bgm_volume_linear = clamp(float(incoming_data[SAVE_KEY_BGM]), 0.0, 1.0)
	if incoming_data.has(SAVE_KEY_SFX) : sfx_volume_linear = clamp(float(incoming_data[SAVE_KEY_SFX]), 0.0, 1.0)
	if incoming_data.has(SAVE_KEY_DIALOGUE) : dialogue_volume_linear = clamp(float(incoming_data[SAVE_KEY_DIALOGUE]), 0.0, 1.0)
	
	_apply_all_bus_volumes()

## Applies the volumes to each audio bus.
func _apply_all_bus_volumes() -> void:
	_apply_bus_volume_linear(BUS_MASTER, master_volume_linear)
	_apply_bus_volume_linear(BUS_BGM, bgm_volume_linear)
	_apply_bus_volume_linear(BUS_SFX, sfx_volume_linear)
	_apply_bus_volume_linear(BUS_DIALOGUE, dialogue_volume_linear)

## Applies the requested audio bus volume to the appropriate bus.
func _apply_bus_volume_linear(incoming_bus_name : String, incoming_linear : float) -> void:
	# Attempts to locate the correct bus. Do nothing if cannot locate.
	var bus_index : int = AudioServer.get_bus_index(incoming_bus_name)
	if bus_index == -1 : return
	
	# Engine gets weird when it works with 0, as linear_to_db() sets it to -INF.
	#	Use safe_linear to prevent this, do not change this.
	var safe_linear : float = max(MIN_SAFE_LINEAR, incoming_linear)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(safe_linear))

# --- BGM Methods
## Initializes the BGM players and connects them to the correct bus.
func _setup_bgm() -> void:
	bgm_player_a = AudioStreamPlayer.new()
	bgm_player_b = AudioStreamPlayer.new()
	add_child(bgm_player_a)
	add_child(bgm_player_b)
	
	bgm_player_a.bus = BUS_BGM
	bgm_player_b.bus = BUS_BGM
	bgm_player_a.volume_db = 0.0
	bgm_player_b.volume_db = MIN_FADE_DB
	
	if OS.has_feature("web"):
		bgm_player_a.set_playback_type(AudioServer.PLAYBACK_TYPE_STREAM)
		bgm_player_b.set_playback_type(AudioServer.PLAYBACK_TYPE_STREAM)

## Attempts to play the requested audio as a BGM from an [AudioStream]. [br][br]
##
## "incoming_stream" : The [AudioStream] to play. [br]
## "incoming_track_key" : The key used for resume/progress caching. If key is empty, attempt to use resource_path, otherwise fall back to "class:id"[br]
## "should_restart" : [code]true[/code] forces the track to start at 0.0. [br]
## "fade_time" : Crossfade time in seconds.
func play_bgm(
	incoming_stream : AudioStream,
	incoming_track_key : String = "",
	should_restart : bool = false,
	fade_time : float = DEFAULT_FADE_TIME
) -> void:
	# Abort if stream is invalid.
	if !incoming_stream : return

	# If key is empty, attempt to use resource_path, otherwise fall back to "class:id"
	if incoming_track_key.is_empty():
		if incoming_stream.resource_path != "" : incoming_track_key = incoming_stream.resource_path
		else : incoming_track_key = "%s:%s" % [incoming_stream.get_class(), str(incoming_stream.get_instance_id())]
	
	# Remember which stream belongs to this key so it can be resumed later by saved key.
	bgm_stream_by_key[incoming_track_key] = incoming_stream
	
	# Same track already playing: leave it alone unless explicitly restarting.
	if incoming_track_key == bgm_active_track_key and bgm_active_track_key != "":
		var active_bgm_player : AudioStreamPlayer = _get_active_bgm_player()
		if active_bgm_player and should_restart:
			active_bgm_player.stop()
			active_bgm_player.stream = incoming_stream
			active_bgm_player.bus = BUS_BGM
			active_bgm_player.volume_db = 0.0
			active_bgm_player.play(0.0)
			_bind_bgm_finished(active_bgm_player, incoming_track_key, incoming_stream)
		return
	
	# Caches the current BGM progress if there is any playing.
	_cache_active_bgm_progress()
	
	# Retrieves the start position.
	var start_position : float = _get_resume_position(incoming_track_key, incoming_stream, should_restart)
	
	# If it's a new track, crossfade into it.
	# Finds the active and inactive bgm_players and preps them for crossfading.
	var outgoing_player : AudioStreamPlayer = _get_active_bgm_player()
	var incoming_player : AudioStreamPlayer = _get_inactive_bgm_player()

	# Preps the incoming_player's metadata.
	bgm_active_track_key = incoming_track_key
	incoming_player.stream = incoming_stream
	incoming_player.bus = BUS_BGM
	incoming_player.volume_db = MIN_FADE_DB
	incoming_player.play(start_position)

	# Check if the outgoing_player is playing. If not, don't bother fading it out.
	var outgoing_for_fade : AudioStreamPlayer = outgoing_player if outgoing_player.playing else null
	_start_bgm_crossfade(outgoing_for_fade, incoming_player, fade_time)

	# Binds the finished signal of the newly active player to trigger _on_bgm_player_finished
	#	which will reset the cached progress on naturally finishing a nonlooping BGM.
	_bind_bgm_finished(incoming_player, incoming_track_key, incoming_stream)

## Attempts to play the requested audio as a BGM from a [String] path. [br][br]
## 
## "incoming_stream_path" : The [String] path to the requested audio track. [br]
## "should_restart" : [code]true[/code] will force the requested audio track to start from the beginning.[br]
## "fade_time" : How long the crossfade time should take in seconds.
func play_bgm_path(
	incoming_stream_path : String,
	should_restart : bool = false,
	fade_time : float = DEFAULT_FADE_TIME
) -> void:
	# Abort if either the path itself or if the path does not point to a valid AudioStream.
	if incoming_stream_path.is_empty() : return
	var incoming_stream : AudioStream = load(incoming_stream_path) as AudioStream
	if incoming_stream == null : return

	# Use path as the track key.
	play_bgm(incoming_stream, incoming_stream_path, should_restart, fade_time)

## Attempts to play the requested audio as a BGM from a [String] key. [br][br]
## 
## "incoming_track_key" : The [String] key to the requested audio track. [br]
## "should_restart" : [code]true[/code] will force the requested audio track to start from the beginning.[br]
## "fade_time" : How long the crossfade time should take in seconds.
func play_bgm_saved_key(
	incoming_track_key : String,
	should_restart : bool = false,
	fade_time : float = DEFAULT_FADE_TIME
) -> void:
	# Abort if key is empty or unknown.
	if incoming_track_key.is_empty() : return
	if !bgm_stream_by_key.has(incoming_track_key) : return
	
	var incoming_stream : AudioStream = bgm_stream_by_key[incoming_track_key] as AudioStream
	if incoming_stream == null : return
	
	play_bgm(incoming_stream, incoming_track_key, should_restart, fade_time)


## Requests to stop the currently playing BGM. If a fade_time is set, it will fade out within that time.
##	Otherwise, hard cuts.
func stop_bgm(fade_time : float = 0.0) -> void:
	# Caches the current BGM progress if there is any playing.
	_cache_active_bgm_progress()
	
	# Finds both bgm_players.
	var active_player : AudioStreamPlayer = _get_active_bgm_player()
	var inactive_player : AudioStreamPlayer = _get_inactive_bgm_player()
	
	# If no fade time, hard cuts all players to stop and resets bgm_active_track_key.
	if fade_time <= 0.0:
		if active_player : active_player.stop()
		if inactive_player : inactive_player.stop()
		bgm_active_track_key = ""
		return
	
	# If there is a fade time, set up the fade.
	# Ensure the bgm_fade_tween is killed.
	_kill_bgm_fade_tween()
	
	# If the active_player is playing, fade it out to MIN_FADE_DB. When fade is done,
	#	stops the player and resets bgm_active_track_key.
	if active_player && active_player.playing:
		bgm_fade_tween = create_tween()
		bgm_fade_tween.tween_property(active_player, "volume_db", MIN_FADE_DB, fade_time)
		bgm_fade_tween.tween_callback(func() -> void:
			active_player.stop()
			bgm_active_track_key = ""
		)
	# Stops the active_player if it's paused and also stops the inactive_player.
	# No fade required as it shouldn't be audible.
	if active_player && active_player.stream_paused: active_player.stop()
	if inactive_player : inactive_player.stop()

## Requests to pause the current BGM.
func pause_bgm() -> void:
	# Caches the current BGM progress if there is any playing.
	_cache_active_bgm_progress()
	
	# Checks to see if there is an active_player, if so, pause it.
	var active_player : AudioStreamPlayer = _get_active_bgm_player()
	if active_player : active_player.stream_paused = true

## Requests to resume the current BGM.
func resume_bgm() -> void:
	# Checks to see if there is an active_player, if so, unpause it.
	var active_player : AudioStreamPlayer = _get_active_bgm_player()
	if active_player : active_player.stream_paused = false

## Clears the current BGM progress cache. If a path is input, clears only that specific track if it exists.
func clear_bgm_progress(incoming_stream_path : String = "") -> void:
	if incoming_stream_path.is_empty():
		bgm_progress_by_track.clear()
		return
	if bgm_progress_by_track.has(incoming_stream_path):
		bgm_progress_by_track.erase(incoming_stream_path)

## Outputs BGM data.
func get_bgm_progress_save_data() -> Dictionary:
	# Outputs a copy to not accidently mutate the variables here.
	var copy : Dictionary = {}
	for key in bgm_progress_by_track.keys():
		copy[key] = bgm_progress_by_track[key]
	return copy

## Loads BGM data.
func set_bgm_progress_save_data(incoming_data : Dictionary) -> void:
	bgm_progress_by_track.clear()
	for key in incoming_data.keys():
		bgm_progress_by_track[str(key)] = float(incoming_data[key])

## Gets the active BGM's key.
func get_active_bgm_key() -> String:
	return bgm_active_track_key

## Crossfades from outgoing_player into the incoming_player.
func _start_bgm_crossfade(outgoing_player : AudioStreamPlayer, incoming_player : AudioStreamPlayer, fade_time : float) -> void:
	# Ensure the bgm_fade_tween is killed.
	_kill_bgm_fade_tween()
	
	# Sets the active_bgm to bgm_player_a if it's about to be crossfaded into.
	bgm_is_a_active = (incoming_player == bgm_player_a)
	
	# If requested fade_time is 0.0 or less, don't bother setting up a tween, just smash cut with no crossfade.
	if fade_time <= 0.0:
		if outgoing_player : outgoing_player.stop()
		incoming_player.volume_db = 0.0
		return
	
	# Sets up the bgm_fade_tween to fade in.
	bgm_fade_tween = create_tween()
	bgm_fade_tween.tween_property(incoming_player, "volume_db", 0.0, fade_time)
	
	# If we have an outgoing_player, fade that out parallel to the incoming_player, causing the crossfade.
	#	Stops the outgoing_player once the fade out is complete.
	if outgoing_player:
		bgm_fade_tween.parallel().tween_property(outgoing_player, "volume_db", MIN_FADE_DB, fade_time)
		bgm_fade_tween.tween_callback(func() -> void : outgoing_player.stop())

## Kills the bgm_fade_tween if it's active.
func _kill_bgm_fade_tween() -> void:
	if bgm_fade_tween && bgm_fade_tween.is_running() : bgm_fade_tween.kill()
	bgm_fade_tween = null

## Caches the current BGM's progress to bgm_progress_by_track.
func _cache_active_bgm_progress() -> void:
	# Aborts if there's no active BGM playing.
	if bgm_active_track_key == "" : return
	var active_player : AudioStreamPlayer = _get_active_bgm_player()
	if active_player == null : return
	
	# Saves wherever the current bgm_player is at into the progress tracker.
	if active_player.playing or active_player.stream_paused:
		var play_position = active_player.get_playback_position()
		var track_length = active_player.stream.get_length()
		
		if track_length - play_position < RESUME_END_CLOSE_ENOUGH : play_position = 0.0
		bgm_progress_by_track[bgm_active_track_key] = play_position

## Returns with the saved progress position if requested, otherwise 0.0.
func _get_resume_position(incoming_track_key : String, incoming_stream : AudioStream, should_restart : bool) -> float:
	# If restart requested or this is a newly requested track, return 0.0.
	if should_restart : return 0.0
	if !bgm_progress_by_track.has(incoming_track_key) : return 0.0
	
	# Grabs the metadata from the requested track.
	var cached : float = float(bgm_progress_by_track[incoming_track_key])
	var length : float = incoming_stream.get_length()
	var loops : bool = _check_if_loops(incoming_stream)
	
	# If the length is <= 0.0, ensure the return is at least 0.0 and trust the cached value.
	if length <= 0.0 : return max(0.0, cached)
	# If the length is close enough to the end of the track and doesn't need to loop,
	#	just assume it has ended and restart to the beginning anyways.
	if !loops and cached >= max(0.0, length - RESUME_END_CLOSE_ENOUGH) : return 0.0
	# Defense if cached > length and is supposed to loop.
	if loops : return fposmod(cached, length)
	
	# If all defenses passed, just return the cached value.
	return cached

## Attempts to check if the track loops or not. Has to be done like this because Godot
##	does not have this check natively for some reason.
func _check_if_loops(incoming_stream : AudioStream) -> bool:
	if incoming_stream is AudioStreamWAV:
		return (incoming_stream as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED
	if incoming_stream is AudioStreamOggVorbis:
		return (incoming_stream as AudioStreamOggVorbis).loop
	if incoming_stream is AudioStreamMP3:
		return (incoming_stream as AudioStreamMP3).loop
	return false

## Updates which bgm_player is bound to the signal
func _bind_bgm_finished(incoming_player : AudioStreamPlayer, incoming_track_key : String, incoming_stream : AudioStream) -> void:
	# Disconnect the previous signal if it exists.
	if bgm_active_player:
		if bgm_active_player.finished.is_connected(_on_bgm_player_finished):
			bgm_active_player.finished.disconnect(_on_bgm_player_finished)
	
	# Sets the bgm_active_player to the incoming_player. Ensures the signal is bound correctly.
	bgm_active_player = incoming_player
	if incoming_player && !incoming_player.finished.is_connected(_on_bgm_player_finished):
		incoming_player.finished.connect(_on_bgm_player_finished.bind(incoming_track_key, incoming_stream))

## Reacts on the bgm_active_player.finished signal to reset a non-looping track back to 0.0
##	when it's finished naturally. It then resets bgm_active_track_key back to empty.
func _on_bgm_player_finished(incoming_track_key : String, _incoming_stream : AudioStream) -> void:
	bgm_progress_by_track[incoming_track_key] = 0.0
	if incoming_track_key == bgm_active_track_key : bgm_active_track_key = ""

## Returns with whichever is the active bgm_player.
func _get_active_bgm_player() -> AudioStreamPlayer:
	return (bgm_player_a if bgm_is_a_active else bgm_player_b)

## Returns with whichever isn't the active bgm_player.
func _get_inactive_bgm_player() -> AudioStreamPlayer:
	return (bgm_player_b if bgm_is_a_active else bgm_player_a)

# --- SFX Methods
## Initializes the SFX pool and connects them to the correct bus.
func _setup_sfx(incoming_pool_size : int = DEFAULT_SFX_POOL_SIZE) -> void:
	sfx_rng.randomize()
	sfx_players_pool.clear()
	sfx_active_players_by_key.clear()
	sfx_last_play_time_by_key.clear()
	
	# Initializes each AudioStreamPlayer and assigns them to sfx_players_pool.
	var pool_size : int = max(1, incoming_pool_size)
	for i in range(pool_size):
		var each_player : AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(each_player)
		each_player.bus = BUS_SFX
		each_player.volume_db = 0.0
		sfx_players_pool.append(each_player)

## Attempts to play the requested audio as a SFX. Returns a signal for await usage.[br][br]
## "incoming_stream" : The [AudioStream] to the requested audio track.[br]
## "incoming_sfx_key" : Any [String] name to use as an indicator of what it is.[br]
## "incoming_volume_linear" : An independant volume multiplier (0..1).[br]
## "incoming_max_polyphony" : Max simultaneous players for this key, if exceeded, steals oldest player.[br]
## "incoming_pitch_jitter" : Random pitch variance to reduce phase stacking.[br]
## "incoming_min_interval" : Prevents multiples of the same key from playing until this variable in seconds.[br][br]
## [u]Examples:[/u][br]
## The following is valid, and will use the path as the key. It will also wait for the SFX to finish before continuing.:
## [codeblock]await play_sfx(load("res://audio/sfx/sound.wav"))[/codeblock]
## If multiple files are desired to be played at the same time and share the same polyphony bucket then:
## [codeblock]
## play_sfx(load("res://audio/sfx/hit_01.wav"), "hit")
## play_sfx(load("res://audio/sfx/hit_02.wav"), "hit")
## [/codeblock]
func play_sfx(
	incoming_stream : AudioStream,
	incoming_sfx_key : String = "",
	incoming_volume_linear : float = 1.0,
	incoming_max_polyphony : int = DEFAULT_SFX_POLYPHONY,
	incoming_pitch_jitter : float = DEFAULT_SFX_PITCH_JITTER,
	incoming_min_interval : float = DEFAULT_SFX_MIN_INTERVAL
) -> Signal:
	var finish_detection : FinishDetection = FinishDetection.new()

	# Abort if no stream.
	if !incoming_stream:
		finish_detection.complete()
		return finish_detection.finished

	# If key is empty, attempt to use resource_path, otherwise fall back to "class:id"
	if incoming_sfx_key.is_empty():
		if incoming_stream.resource_path != "" : incoming_sfx_key = incoming_stream.resource_path
		else : incoming_sfx_key = "%s:%s" % [incoming_stream.get_class(), str(incoming_stream.get_instance_id())]
	
	# Sends the key name to FinishDetection.
	finish_detection.sfx_key = incoming_sfx_key
	
	# Disallows playing if it hasn't been long enough since the last time the key has been played.
	var now_time : float = float(Time.get_ticks_msec()) * 0.001
	if incoming_min_interval > 0.0:
		if sfx_last_play_time_by_key.has(incoming_sfx_key):
			var last_time : float = float(sfx_last_play_time_by_key[incoming_sfx_key])
			if now_time - last_time < incoming_min_interval:
				finish_detection.complete()
				return finish_detection.finished
	sfx_last_play_time_by_key[incoming_sfx_key] = now_time
	
	# Ensure array exists for this key.
	if !sfx_active_players_by_key.has(incoming_sfx_key):
		sfx_active_players_by_key[incoming_sfx_key] = [] as Array[AudioStreamPlayer]
	
	# Once validated, set the incoming AudioStream to the valid player.
	var active_list : Array[AudioStreamPlayer] = sfx_active_players_by_key[incoming_sfx_key] as Array[AudioStreamPlayer]
	
	# Enforce per-key max polyphony by stealing the oldest.
	var max_polyphony : int = max(1, incoming_max_polyphony)
	while active_list.size() >= max_polyphony:
		var stolen_player : AudioStreamPlayer = active_list.pop_front()
		if stolen_player:
			stolen_player.stop()
			_release_sfx_player(stolen_player)
	
	# Attempts to acquire an available player from sfx_players_pool.
	var sfx_player : AudioStreamPlayer = _get_sfx_player_from_pool()
	if !sfx_player:
		# If there are no available players from the pool, attempt to steal from
		#	 oldest of this key. If it still can't just abort.
		if active_list.size() > 0:
			var forced_player : AudioStreamPlayer = active_list.pop_front()
			if forced_player:
				forced_player.stop()
				_release_sfx_player(forced_player)
				sfx_player = _get_sfx_player_from_pool()
		if !sfx_player:
			finish_detection.complete()
			return finish_detection.finished
	
	# Assign stream.
	sfx_player.stream = incoming_stream
	
	# Changes the pitch by incoming_pitch_jitter to reduce phase stacking.
	if incoming_pitch_jitter > 0.0:
		sfx_player.pitch_scale = 1.0 + sfx_rng.randf_range(-incoming_pitch_jitter, incoming_pitch_jitter)
	else : sfx_player.pitch_scale = 1.0
	
	# Store volume multiplier as metadata so it can recompute on polyphony changes.
	sfx_player.set_meta(META_KEY, incoming_sfx_key)
	sfx_player.set_meta(META_BASE_VOLUME, clamp(incoming_volume_linear, 0.0, 1.0))
	sfx_player.set_meta(META_FINISH_DETECTION, finish_detection)
	
	# Binds the player to a cleanup function.
	if sfx_player.finished.is_connected(_on_sfx_player_finished):
		sfx_player.finished.disconnect(_on_sfx_player_finished)
	sfx_player.finished.connect(_on_sfx_player_finished.bind(sfx_player, incoming_sfx_key))
	
	# Appends the SFX to the list for tracking and readjusts volume if polyphony is applicable.
	active_list.append(sfx_player)
	_recompute_sfx_polyphony_volume(incoming_sfx_key)
	
	# Once all preperations are complete, play the SFX.
	sfx_player.play()
	return finish_detection.finished

## Attempts to play the requested audio as a SFX. Returns a signal for await usage.[br][br]
## "incoming_stream_path" : The [String] path to the requested audio track.[br]
## "incoming_sfx_key" : Any [String] name to use as an indicator of what it is.[br]
## "incoming_volume_linear" : An independant volume multiplier (0..1).[br]
## "incoming_max_polyphony" : Max simultaneous players for this key, if exceeded, steals oldest player.[br]
## "incoming_pitch_jitter" : Random pitch variance to reduce phase stacking.[br]
## "incoming_min_interval" : Prevents multiples of the same key from playing until this variable in seconds.[br][br]
## [u]Examples:[/u][br]
## The following is valid, and will use the path as the key. It will also wait for the SFX to finish before continuing.:
## [codeblock]await play_sfx("res://audio/sfx/sound.wav")[/codeblock]
## If multiple files are desired to be played at the same time and share the same polyphony bucket then:
## [codeblock]
## play_sfx("res://audio/sfx/hit_01.wav", "hit")
## play_sfx("res://audio/sfx/hit_02.wav", "hit")
## [/codeblock]
func play_sfx_path(
	incoming_stream_path : String,
	incoming_sfx_key : String = "",
	incoming_volume_linear : float = 1.0,
	incoming_max_polyphony : int = DEFAULT_SFX_POLYPHONY,
	incoming_pitch_jitter : float = DEFAULT_SFX_PITCH_JITTER,
	incoming_min_interval : float = DEFAULT_SFX_MIN_INTERVAL
) -> Signal:
	# Sets up the detection class to enable await functionality.
	var finish_detection : FinishDetection = FinishDetection.new()
	
	# Abort if path itself is empty or if the path does not point to a valid AudioStream.
	if incoming_stream_path.is_empty():
		finish_detection.complete()
		return finish_detection.finished
	var incoming_stream : AudioStream = load(incoming_stream_path) as AudioStream
	if !incoming_stream:
		finish_detection.complete()
		return finish_detection.finished
	
	# If no key provided, use path, then sends all data to play_sfx_stream.
	if incoming_sfx_key.is_empty() : incoming_sfx_key = incoming_stream_path
	finish_detection.sfx_key = incoming_sfx_key
	return play_sfx(
		incoming_stream,
		incoming_sfx_key,
		incoming_volume_linear,
		incoming_max_polyphony,
		incoming_pitch_jitter,
		incoming_min_interval
	)

## Requests to stop all currently playing SFX for a specific key.[br][br]
## "incoming_sfx_key" : The key to stop. Attempts to translate it from an [AudioStream][br]
## "fade_time" : If > 0, fades out each SFX before stopping.
func stop_sfx_key(incoming_stream : AudioStream, fade_time : float = 0.0) -> void:
	# Abort if no stream.
	if !incoming_stream : return
	
	var incoming_sfx_key : String = ""
	if incoming_stream.resource_path != "" : incoming_sfx_key = incoming_stream.resource_path
	else : incoming_sfx_key = "%s:%s" % [incoming_stream.get_class(), str(incoming_stream.get_instance_id())]
	
	stop_sfx_key_path(incoming_sfx_key, fade_time)

## Requests to stop all currently playing SFX for a specific key.[br][br]
## "incoming_sfx_key" : The [String] key to stop.[br]
## "fade_time" : If > 0, fades out each SFX before stopping.
func stop_sfx_key_path(incoming_sfx_key : String, fade_time : float = 0.0) -> void:
	# Abort if either the key is empty or doesn't exist in the active player pool.
	if incoming_sfx_key.is_empty() : return
	if !sfx_active_players_by_key.has(incoming_sfx_key) : return

	# Finds the list of players that are actively playing the sfx of the key.
	#	If for some reason there's nothing playing, just erase the key and abort.
	var active_list : Array[AudioStreamPlayer] = sfx_active_players_by_key[incoming_sfx_key] as Array[AudioStreamPlayer]
	if active_list.size() <= 0:
		sfx_active_players_by_key.erase(incoming_sfx_key)
		return

	# Go through the list in reverse to stop the newest player first.
	for player_index in range(active_list.size() - 1, -1, -1):
		var each_player : AudioStreamPlayer = active_list[player_index]
		if !each_player: continue
		
		# Remove from tracking immediately to avoid awaits hanging.
		active_list.remove_at(player_index)
		
		# If no fade requested, just hard cut, otherwise fade it.
		if fade_time <= 0.0:
			each_player.stop()
			_release_sfx_player(each_player)
		else: _stop_sfx_player_with_fade(each_player, fade_time)
	
	# Ensures there's nothing left in the list, then erases the key.
	if active_list.size() <= 0 : sfx_active_players_by_key.erase(incoming_sfx_key)

## Requests to stop only the oldest (earliest started) SFX voice for a key.[br][br]
## "incoming_sfx_key" : The key to stop.[br]
## "fade_time" : If > 0, fades out the SFX before stopping.
func stop_sfx_key_one(incoming_sfx_key : String, fade_time : float = 0.0) -> void:
	# Abort if either the key is empty or doesn't exist in the active player pool.
	if incoming_sfx_key.is_empty() : return
	if !sfx_active_players_by_key.has(incoming_sfx_key) : return
	
	# Finds the list of players that are actively playing the sfx of the key.
	#	If for some reason there's nothing playing, just erase the key and abort.
	var active_list : Array[AudioStreamPlayer] = sfx_active_players_by_key[incoming_sfx_key] as Array[AudioStreamPlayer]
	if active_list.size() <= 0:
		sfx_active_players_by_key.erase(incoming_sfx_key)
		return
	
	# Finds the oldest player with the key, then fades out if requested, otherwise hard cut.
	var oldest_player : AudioStreamPlayer = active_list.pop_front()
	if oldest_player:
		if fade_time <= 0.0:
			oldest_player.stop()
			_release_sfx_player(oldest_player)
		else : _stop_sfx_player_with_fade(oldest_player, fade_time)
	
	# Recompute remaining player volume if still active, otherwise erase the key.
	if active_list.size() <= 0 : sfx_active_players_by_key.erase(incoming_sfx_key)
	else : _recompute_sfx_polyphony_volume(incoming_sfx_key)

## Requests to stop ALL currently playing SFX.[br][br]
## "fade_time" : If > 0, fades out each SFX accordingly before stopping.
func stop_all_sfx(fade_time : float = 0.0) -> void:
	# Copy keys first to safely manipulate keys.
	var keys_copy : Array = sfx_active_players_by_key.keys()
	
	# Goes through the list and clears each key.
	for each_key in keys_copy : stop_sfx_key_path(each_key, fade_time)
	
	# Clears the time tracker.
	sfx_last_play_time_by_key.clear()

## Returns true if any SFX player is currently active for this key.
func is_sfx_key_playing(incoming_sfx_key : String) -> bool:
	if incoming_sfx_key.is_empty() : return false
	if !sfx_active_players_by_key.has(incoming_sfx_key) : return false
	var active_list : Array[AudioStreamPlayer] = sfx_active_players_by_key[incoming_sfx_key] as Array[AudioStreamPlayer]
	return active_list.size() > 0

## Pulls an available AudioStreamPlayer from the pool, or returns null if none are free.
func _get_sfx_player_from_pool() -> AudioStreamPlayer:
	if sfx_players_pool.size() <= 0 : return null
	return sfx_players_pool.pop_back()

## Returns an AudioStreamPlayer to the pool.
func _release_sfx_player(incoming_player : AudioStreamPlayer) -> void:
	if !incoming_player: return
	
	# Triggers the signal for await purposes.
	_complete_audio_player(incoming_player)
	
	# Resets values.
	incoming_player.stream = null
	incoming_player.pitch_scale = 1.0
	incoming_player.volume_db = 0.0
	incoming_player.set_meta(META_KEY, "")
	incoming_player.set_meta(META_BASE_VOLUME, 1.0)
	incoming_player.set_meta(META_FINISH_DETECTION, null)
	
	# Returns the reset player to the pool.
	sfx_players_pool.append(incoming_player)

## Recomputes per-voice volume for the given key to avoid having the sound get too loud.
func _recompute_sfx_polyphony_volume(incoming_sfx_key : String) -> void:
	# Checks to see if the key exists as an active player. If not, abort.
	if !sfx_active_players_by_key.has(incoming_sfx_key) : return
	var active_list : Array[AudioStreamPlayer] = sfx_active_players_by_key[incoming_sfx_key] as Array[AudioStreamPlayer]
	var active_count : int = active_list.size()
	if active_count <= 0 : return
	
	# Finds the corrected db according to how many players with the same keys are actively playing.
	# corrected_db should be a negative, as corrected_linear should be less than 1.
	var corrected_linear : float = 1.0 / sqrt(float(active_count))
	var corrected_db : float = linear_to_db(max(0.0001, corrected_linear))
	
	# Checks if each player has metadata of META_BASE_VOLUME. If so, adjust accordingly.
	for each_player in active_list:
		if !each_player : continue
		var base_linear : float = 1.0
		if each_player.has_meta(META_BASE_VOLUME):
			base_linear = clamp(float(each_player.get_meta(META_BASE_VOLUME)), 0.0, 1.0)
		var base_db : float = linear_to_db(max(0.0001, base_linear))
		each_player.volume_db = base_db + corrected_db

## Cleans up on finished signal and recomputes volumes for remaining voices of that key.
func _on_sfx_player_finished(incoming_player : AudioStreamPlayer, incoming_sfx_key : String) -> void:
	# Triggers the custom finished signal.
	_complete_audio_player(incoming_player)
	
	# Checks to see if there are any other active players with the same key.
	#	If so, recalculate their individual volumes for polyphony purposes.
	#	Otherwise, delete that key from the sfx_active_players_by_key dictionary.
	if sfx_active_players_by_key.has(incoming_sfx_key):
		var active_list : Array[AudioStreamPlayer] = sfx_active_players_by_key[incoming_sfx_key] as Array[AudioStreamPlayer]
		active_list.erase(incoming_player)
		if active_list.size() <= 0 : sfx_active_players_by_key.erase(incoming_sfx_key)
		else : _recompute_sfx_polyphony_volume(incoming_sfx_key)
	
	# Returns the player to the available pool. 
	_release_sfx_player(incoming_player)

## Fades a specific SFX player out, then stops and releases it.
func _stop_sfx_player_with_fade(incoming_player : AudioStreamPlayer, fade_time : float) -> void:
	if !incoming_player: return
	
	# We do NOT rely on .finished here because stop() doesn't emit finished.
	# Fade time can overlap with other fades, so it makes a unique tween.
	var fade_tween : Tween = create_tween()
	fade_tween.tween_property(incoming_player, "volume_db", MIN_FADE_DB, fade_time)
	fade_tween.tween_callback(func() -> void:
		if incoming_player:
			incoming_player.stop()
			_release_sfx_player(incoming_player)
			)

# ---- Dialogue Methods
## Initializes the Dialogue pool and connects them to the correct bus.
func _setup_dialogue(incoming_pool_size : int = DEFAULT_DIALOGUE_POOL_SIZE) -> void:
	dialogue_rng.randomize()
	dialogue_players_pool.clear()
	dialogue_active_players_by_key.clear()
	dialogue_last_play_time_by_key.clear()
	
	# Initializes each AudioStreamPlayer and assigns them to sfx_players_pool.
	var pool_size : int = max(1, incoming_pool_size)
	for i in range(pool_size):
		var each_player : AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(each_player)
		each_player.bus = BUS_DIALOGUE
		each_player.volume_db = 0.0
		dialogue_players_pool.append(each_player)

## Attempts to play the requested audio as a SFX. Returns a signal for await usage.[br][br]
## "incoming_stream_path" : The [AudioStream] to the requested audio track.[br]
## "incoming_sfx_key" : Any [String] name to use as an indicator of what it is.[br]
## "incoming_volume_linear" : An independant volume multiplier (0..1).[br]
## "incoming_max_polyphony" : Max simultaneous players for this key, if exceeded, steals oldest player.[br]
## "incoming_pitch_jitter" : Random pitch variance to reduce phase stacking.[br]
## "incoming_min_interval" : Prevents multiples of the same key from playing until this variable in seconds.[br]
## "incoming_base_pitch_scale" : The default pitch scale of the dialogue.[br]
func play_dialogue(
	incoming_stream : AudioStream,
	incoming_dialogue_key : String = "",
	incoming_volume_linear : float = 1.0,
	incoming_max_polyphony : int = DEFAULT_DIALOGUE_POLYPHONY,
	incoming_pitch_jitter : float = DEFAULT_DIALOGUE_PITCH_JITTER,
	incoming_min_interval : float = DEFAULT_DIALOGUE_MIN_INTERVAL,
	incoming_base_pitch_scale : float = 1.0
) -> Signal:
	# Sets up the detection class to enable await functionality.
	var finish_detection : FinishDetection = FinishDetection.new()
	
	# Abort if path itself is empty or if the path does not point to a valid AudioStream.
	if !incoming_stream:
		finish_detection.complete()
		return finish_detection.finished
	
	# If key is empty, attempt to use resource_path, otherwise fall back to "class:id"
	if incoming_dialogue_key.is_empty():
		if incoming_stream.resource_path != "" : incoming_dialogue_key = incoming_stream.resource_path
		else : incoming_dialogue_key = "%s:%s" % [incoming_stream.get_class(), str(incoming_stream.get_instance_id())]
	
	# Sends the key name to FinishDetection.
	finish_detection.sfx_key = incoming_dialogue_key
	
	# Disallows playing if it hasn't been long enough since the last time the key has been played.
	var now_time : float = float(Time.get_ticks_msec()) * 0.001
	if incoming_min_interval > 0.0:
		if dialogue_last_play_time_by_key.has(incoming_dialogue_key):
			var last_time : float = float(dialogue_last_play_time_by_key[incoming_dialogue_key])
			if now_time - last_time < incoming_min_interval:
				finish_detection.complete()
				return finish_detection.finished
	dialogue_last_play_time_by_key[incoming_dialogue_key] = now_time
	
	# Ensure array exists for this key.
	if !dialogue_active_players_by_key.has(incoming_dialogue_key):
		dialogue_active_players_by_key[incoming_dialogue_key] = [] as Array[AudioStreamPlayer]
	
	# Once validated, set the incoming AudioStream to the valid player.
	var active_list : Array[AudioStreamPlayer] = dialogue_active_players_by_key[incoming_dialogue_key] as Array[AudioStreamPlayer]
	
	# Enforce per-key max polyphony by stealing the oldest.
	var max_polyphony : int = max(1, incoming_max_polyphony)
	while active_list.size() >= max_polyphony:
		var stolen_player : AudioStreamPlayer = active_list.pop_front()
		if stolen_player:
			stolen_player.stop()
			_release_dialogue_player(stolen_player)
	
	# Attempts to acquire an available player from dialogue_players_pool.
	var dialogue_player : AudioStreamPlayer = _get_dialogue_player_from_pool()
	if !dialogue_player:
		# If there are no available players from the pool, attempt to steal from
		#	 oldest of this key. If it still can't just abort.
		if active_list.size() > 0:
			var forced_player : AudioStreamPlayer = active_list.pop_front()
			if forced_player:
				forced_player.stop()
				_release_dialogue_player(forced_player)
				dialogue_player = _get_dialogue_player_from_pool()
		if !dialogue_player:
			finish_detection.complete()
			return finish_detection.finished
	
	# Assign stream.
	dialogue_player.stream = incoming_stream
	
	# Changes the pitch by incoming_pitch_jitter to reduce phase stacking.
	dialogue_player.pitch_scale = max(0.01, incoming_base_pitch_scale)
	if incoming_pitch_jitter > 0.0:
		dialogue_player.pitch_scale *= 1.0 + dialogue_rng.randf_range(-incoming_pitch_jitter, incoming_pitch_jitter)
		
	# Store volume multiplier as metadata so it can recompute on polyphony changes.
	dialogue_player.set_meta(META_KEY, incoming_dialogue_key)
	dialogue_player.set_meta(META_BASE_VOLUME, clamp(incoming_volume_linear, 0.0, 1.0))
	dialogue_player.set_meta(META_FINISH_DETECTION, finish_detection)
	
	# Binds the player to a cleanup function.
	if dialogue_player.finished.is_connected(_on_dialogue_player_finished):
		dialogue_player.finished.disconnect(_on_dialogue_player_finished)
	dialogue_player.finished.connect(_on_dialogue_player_finished.bind(dialogue_player, incoming_dialogue_key))
	
	# Appends and recompute per-voice volume.
	active_list.append(dialogue_player)
	_recompute_dialogue_polyphony_volume(incoming_dialogue_key)
	
	# Once all preperations are complete, play the SFX.
	dialogue_player.play()
	return finish_detection.finished

## Pulls an available AudioStreamPlayer from the pool, or returns null if none are free.
func _get_dialogue_player_from_pool() -> AudioStreamPlayer:
	if dialogue_players_pool.size() <= 0 : return null
	return dialogue_players_pool.pop_back()

## Returns an AudioStreamPlayer to the pool.
func _release_dialogue_player(incoming_player : AudioStreamPlayer) -> void:
	if !incoming_player: return
	
	# Triggers the signal for await purposes.
	_complete_audio_player(incoming_player)
	
	# Resets values.
	incoming_player.stream = null
	incoming_player.pitch_scale = 1.0
	incoming_player.volume_db = 0.0
	incoming_player.set_meta(META_KEY, "")
	incoming_player.set_meta(META_BASE_VOLUME, 1.0)
	incoming_player.set_meta(META_FINISH_DETECTION, null)
	
	# Returns the reset player to the pool.
	dialogue_players_pool.append(incoming_player)

## Recomputes per-voice volume for the given key to avoid having the sound get too loud.
func _recompute_dialogue_polyphony_volume(incoming_dialogue_key : String) -> void:
	# Checks to see if the key exists as an active player. If not, abort.
	if !dialogue_active_players_by_key.has(incoming_dialogue_key) : return
	var active_list : Array[AudioStreamPlayer] = dialogue_active_players_by_key[incoming_dialogue_key] as Array[AudioStreamPlayer]
	var active_count : int = active_list.size()
	if active_count <= 0 : return
	# Finds the corrected db according to how many players with the same keys are actively playing.
	# corrected_db should be a negative, as corrected_linear should be less than 1.
	var corrected_linear : float = 1.0 / sqrt(float(active_count))
	var corrected_db : float = linear_to_db(max(0.0001, corrected_linear))
	
	# Checks if each player has metadata of META_BASE_VOLUME. If so, adjust accordingly.
	for each_player in active_list:
		if !each_player : continue
		var base_linear : float = 1.0
		if each_player.has_meta(META_BASE_VOLUME):
			base_linear = clamp(float(each_player.get_meta(META_BASE_VOLUME)), 0.0, 1.0)
		var base_db : float = linear_to_db(max(0.0001, base_linear))
		each_player.volume_db = base_db + corrected_db

## Cleans up on finished signal and recomputes volumes for remaining voices of that key.
func _on_dialogue_player_finished(incoming_player : AudioStreamPlayer, incoming_dialogue_key : String) -> void:
	# Triggers the custom finished signal.
	_complete_audio_player(incoming_player)
	
	# Checks to see if there are any other active players with the same key.
	# If so, recalculate their individual volumes for polyphony purposes.
	# Otherwise, delete that key from the dialogue_active_players_by_key
	if dialogue_active_players_by_key.has(incoming_dialogue_key):
		var active_list : Array[AudioStreamPlayer] = dialogue_active_players_by_key[incoming_dialogue_key] as Array[AudioStreamPlayer]
		active_list.erase(incoming_player)
		if active_list.size() <= 0 : dialogue_active_players_by_key.erase(incoming_dialogue_key)
		else : _recompute_dialogue_polyphony_volume(incoming_dialogue_key)
	
	# Returns the player to the available pool.
	_release_dialogue_player(incoming_player)
