package imaginative.backend.systems;

import flixel.FlxCamera;
import flixel.sound.FlxSound;
import flixel.sound.FlxSoundGroup;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import imaginative.backend.states.GameState;

@:allow(imaginative.backend.systems.Conductor)
@:autoBuild(imaginative.backend.macro.ConductorReactiveMacro.build())
interface IConductorReactive {
	// private var _conductor_(default, null):Conductor;

	function _stepHit(target:Conductor):Void;
	function _beatHit(target:Conductor):Void;
	function _measureHit(target:Conductor):Void;

	function stepHit(step:Int, target:Conductor):Void;
	function beatHit(beat:Int, target:Conductor):Void;
	function measureHit(measure:Int, target:Conductor):Void;
}

typedef MusicMeta = {
	/**
	 * The song id / folder name.
	 */
	var ?id:ModPath;
	/**
	 * The display name of the song.
	 */
	var name:String;
	/**
	 * The person (or people) who composed the song.
	 */
	var composer:String;
	/**
	 * The list of time changes in the song.
	 */
	var ?checkpoints:Array<CheckpointMeta>;
	/**
	 * The time the song should loop from **(in steps, milliseconds for now)**.
	 *
	 * Note: Only works if the conductor has "canLoop" enabled.
	 */
	var ?loopPoint:Float;
	/**
	 * How long the song is **(in steps, milliseconds for now)**.
	 */
	var ?length:Float;
}

typedef RawCheckpointMeta = {
	/**
	 * The time of the change **(in milliseconds, do steps maybe?)**.
	 */
	var time:Float;
	/**
	 * The BPM of the change.
	 */
	var bpm:Float;
	/**
	 * The time signature of the change.
	 */
	var signature:Array<Int>;
}
@:forward abstract CheckpointMeta(RawCheckpointMeta) from RawCheckpointMeta {
	/**
	 * The time signature *numerator*.
	 */
	public var beatsPerMeasure(get, set):Int;
	inline function get_beatsPerMeasure():Int return this.signature[0];
	inline function set_beatsPerMeasure(value:Int):Int
		return this.signature[0] = value;
	/**
	 * The time signature *denominator*.
	 */
	public var stepsPerBeat(get, set):Int;
	inline function get_stepsPerBeat():Int return this.signature[1];
	inline function set_stepsPerBeat(value:Int):Int
		return this.signature[1] = value;

	public var stepsPerMeasure(get, never):Int;
	inline function get_stepsPerMeasure():Int
		return beatsPerMeasure * stepsPerBeat;

	public function new(bpm:Float, time:Float = 0, ?signature:Array<Int>) {
		this = {
			time: time,
			bpm: bpm,
			signature: signature ?? [4, 4]
		}
	}
}

class Conductor extends flixel.FlxBasic {
	/**
	 * The conductor for menu music.
	 */
	public static var menu(default, null):Conductor;
	/**
	 * The conductor for songs in PlayState.
	 */
	public static var song(default, null):Conductor;
	/**
	 * The conductor for cutscene audio.
	 */
	public static var cutscene(default, null):Conductor;
	/**
	 * The conductor for the chart editor.
	 */
	public static var charter(default, null):Conductor;

	@:unreflective inline static function init():Void {
		menu = new Conductor('Menu', true);
		song = new Conductor('Song');
		cutscene = new Conductor('Cutscene', true);
		charter = new Conductor('Charter');
	}

	/**
	 * The conductor id.
	 *
	 * This is completely optional and is only used in the debug console.
	 */
	public final id:String;

	/**
	 * Dispatches whenever the song starts.
	 */
	public final onLoad:FlxTypedSignal<MusicMeta -> Void> = new FlxTypedSignal<MusicMeta -> Void>();
	/**
	 * Dispatches whenever the song loops.
	 */
	public final onLoop:FlxTypedSignal<Void -> Void> = new FlxTypedSignal<Void -> Void>();
	/**
	 * Dispatches whenever the song ends.
	 */
	public final onComplete:FlxTypedSignal<Void -> Void> = new FlxTypedSignal<Void -> Void>();

	/**
	 * If true, when the audio ends, it will loop.
	 */
	public var canLoop:Bool;
	/**
	 * The time the song should loop from **(in steps, milliseconds for now)**.
	 *
	 * Note: Only works if the conductor has "canLoop" enabled.
	 */
	public var loopTime:Float = 0;

	var group:FlxSoundGroup;

	/**
	 * Whether the conductor is playing or not.
	 */
	public var playing(default, null):Bool = false;

	/**
	 * The volume of the conductor.
	 */
	public var volume(get, set):Float;
	inline function get_volume():Float return group.volume;
	inline function set_volume(value:Float):Float return group.volume = value;
	/**
	 * Whether the conductor is muted or not.
	 */
	public var muted(get, set):Bool;
	inline function get_muted():Bool return group.muted;
	inline function set_muted(value:Bool):Bool return group.muted = value;

	/**
	 * How fast the song should play.
	 */
	public var rate(default, set):Float;
	inline function set_rate(value:Float):Float {
		for (sound in group.sounds)
			sound.pitch = value;
		return rate = value;
	}

	/**
	 * The current song time **(in milliseconds)**.
	 */
	public var time:Float = 0;
	var prevTime:Float = 0;
	/**
	 * Basically just "time" but for note positioning.
	 */
	public var frameTime(default, null):Float = 0;
	/**
	 * How long the song is **(in steps, milliseconds for now)**.
	 */
	public var endTime:Null<Float>;

	/**
	 * The length of the song **(in milliseconds)**.
	 */
	public var length(get, never):Float;
	inline function get_length():Float
		return endTime ?? longestAudio?.length ?? 0;

	/**
	 * The metadata for the current song.
	 */
	public var metadata:MusicMeta = {name: 'No Metadata', composer: 'No Metadata'}

	final checkpoints:Array<CheckpointMeta> = [];

	/**
	 * Dispatches whenever a bpm change has passed.
	 * @param CheckpointMeta The checkpoint meta information.
	 */
	public final onBPMChange:FlxTypedSignal<CheckpointMeta -> Void> = new FlxTypedSignal<CheckpointMeta -> Void>();

	/**
	 * The initial *beats-per-minute*.
	 */
	public var initialBPM(default, null):Float = 100;
	/**
	 * The current *beats-per-minute*.
	 */
	public var currentBPM(default, null):Float = 100;
	@:unreflective var _bpm:Float = 100;

	/**
	 * Dispatches whenever a step has passed.
	 * @param Int The dispatched step.
	 */
	public final onStepHit:FlxTypedSignal<Int -> Void> = new FlxTypedSignal<Int -> Void>();
	/**
	 * Dispatches whenever a beat has passed.
	 * @param Int The dispatched beat.
	 */
	public final onBeatHit:FlxTypedSignal<Int -> Void> = new FlxTypedSignal<Int -> Void>();
	/**
	 * Dispatches whenever a measure has passed.
	 * @param Int The dispatched measure.
	 */
	public final onMeasureHit:FlxTypedSignal<Int -> Void> = new FlxTypedSignal<Int -> Void>();

	/**
	 * The amount of steps into the song.
	 */
	public var curStep(default, null):Int = 0;
	/**
	 * The amount of beats into the song.
	 */
	public var curBeat(default, null):Int = 0;
	/**
	 * The amount of measures into the song.
	 */
	public var curMeasure(default, null):Int = 0;

	/**
	 * The **exact** "curStep" of the song.
	 */
	public var curStepExact(default, null):Float = 0;
	/**
	 * The **exact** "curBeat" of the song.
	 */
	public var curBeatExact(default, null):Float = 0;
	/**
	 * The **exact** "curMeasure" of the song.
	 */
	public var curMeasureExact(default, null):Float = 0;

	/**
	 * The current amount of *steps-per-beat* (time signature **denominator**).
	 */
	public var stepsPerBeat(default, null):Int = 4;
	/**
	 * The current amount of *beats-per-measure* (time signature **numerator**).
	 */
	public var beatsPerMeasure(default, null):Int = 4;
	/**
	 * The current amount of *steps-per-measure*.
	 */
	public var stepsPerMeasure(get, never):Int;
	inline function get_stepsPerMeasure():Int
		return beatsPerMeasure * stepsPerBeat;

	/**
	 * The length of a step **(in milliseconds)**.
	 */
	public var stepLength(default, null):Float = 0;
	/**
	 * The length of a beat **(in milliseconds)**.
	 */
	public var beatLength(default, null):Float = 0;
	/**
	 * The length of a measure **(in milliseconds)**.
	 */
	public var measureLength(default, null):Float = 0;

	public function new(id:String, canLoop:Bool = false) {
		super();

		this.id = id;
		this.canLoop = canLoop;
		group = new FlxSoundGroup();
		muted = false;
		rate = 1;

		FlxG.plugins.addPlugin(this);
		FlxG.signals.focusGained.add(onFocus);
		FlxG.signals.focusLost.add(onFocusLost);

		/* onLoad.add(meta -> trace('Loaded song "${meta.name}" on Conductor "$id".'));
		onBPMChange.add(checkpoint -> trace('BPM changed to "${checkpoint.bpm}" on Conductor "$id".'));
		onStepHit.add(step -> trace('Passed step "$step" on Conductor "$id".'));
		onBeatHit.add(beat -> trace('Passed beat "$beat" on Conductor "$id".'));
		onMeasureHit.add(measure -> trace('Passed measure "$measure" on Conductor "$id".')); */
	}

	/**
	 * Plays the conductor's audio.
	 * @param startTime The starting time. **Can be negative.**
	 * @param startVolume The starting volume.
	 */
	inline public function play(startTime:Float = 0, startVolume:Float = 1):Void {
		time = startTime;
		volume = startVolume;
		playing = true;
		resyncTracks(true);
	}

	/**
	 * Pauses the conductor's audio.
	 */
	inline public function pause():Void {
		group.pause();
		playing = false;
	}
	/**
	 * Resumes the conductor's audio.
	 */
	inline public function resume():Void {
		group.resume();
		playing = true;
		resyncTracks(true);
	}

	/**
	 * Stops the conductor's audio.
	 */
	inline public function stop():Void {
		stopFade();
		for (sound in group.sounds)
			sound.stop();
		playing = false;
	}

	/**
	 * Resets the conductor.
	 */
	inline public function reset():Void {
		stop();
		for (sound in group.sounds) {
			if (sound.group != null)
				if (group.sounds.contains(sound))
					group.remove(sound);
				else if (sound.group.sounds.contains(sound))
					sound.group.remove(sound);
			sound.destroy();
		}

		frameTime = prevTime = time = 0;
		curStep = curBeat = curMeasure = 0;
		curMeasureExact = curBeatExact = curMeasureExact = 0;
		stepLength = beatLength = measureLength = 0;
		stepsPerBeat = beatsPerMeasure = 4;
		initialBPM = currentBPM = _bpm = 100;
		checkpoints.resize(0);
	}

	/**
	 * Pulled the fade code from FlxSound, lmao.
	 */
	var fadeTween:FlxTween;
	/**
	 * Fades in the conductor's audio.
	 *
	 * Note: Always starts from 0.
	 * @param duration The amount of time the fade in should take.
	 * @param to The value to tween to.
	 */
	inline public function fadeIn(duration:Float = 1, to:Float = 1, ?onComplete:FlxTween -> Void):Void {
		if (!playing)
			play();

		stopFade();
		fadeTween = FlxTween.num(0, to, duration, {onComplete: onComplete}, (value:Float) -> volume = value);
	}
	/**
	 * Fades out the conductor's audio.
	 * @param duration The amount of time the fade out should take.
	 * @param to The value to tween to.
	 */
	inline public function fadeOut(duration:Float = 1, to:Float = 0, ?onComplete:FlxTween -> Void):Void {
		stopFade();
		fadeTween = FlxTween.num(volume, to, duration, {onComplete: onComplete}, (value:Float) -> volume = value);
	}
	/**
	 * Stops the fade tween dead in it's tracks.
	 * @param returnValue Do you wish to have the conductor volume return to a different value?
	 */
	inline public function stopFade(?returnValue:Float):Void {
		if (fadeTween != null)
			fadeTween.cancel();
		if (returnValue != null)
			volume = returnValue;
	}

	/**
	 * Sets up music to play.
	 * @param music The music id.
	 * @param cacheType The cache type.
	 * @param persistenceType The persistence level.
	 */
	public function loadMusic(music:ModPath, cacheType:CacheType = CacheAsset, persistenceType:PersistenceType = IsVulnerable):Void {
		reset();
		var audio:FlxSound = FlxG.sound.create(Assets.music(music, cacheType, persistenceType, true), group).setup();
		if (@:privateAccess audio._sound != null) {
			#if FLX_PITCH audio.pitch = rate; #end
			audio.persist = true;
		} else group.remove(audio);
		metadata = getMetadata(music.path, Paths.music(music), cacheType);
		_onLoad();
	}
	/**
	 * Sets up a song to play.
	 * @param song The song id.
	 * @param variant The variation key. **Can be null.**
	 * @param reloadCache If true, it reloads the cache.
	 */
	public function loadSong(song:ModPath, ?variant:String, reloadCache:Bool = false):Void {
		reset();
		var audio:FlxSound = FlxG.sound.create(Assets.inst(song, variant, reloadCache, true), group).setup();
		if (@:privateAccess audio._sound != null) {
			#if FLX_PITCH audio.pitch = rate; #end
			audio.persist = true;
		} else group.remove(audio);
		metadata = getMetadata(song.path, Paths.inst(song, variant), reloadCache ? OverrideCache : CacheAsset);
		_onLoad();
	}

	inline static function getMetadata(id:String, path:ModPath, cacheType:CacheType):MusicMeta {
		var meta:MusicMeta = Assets.json(path, cacheType, true);
		if (meta == null) return {name: 'Failed Parse', composer: 'Failed Parse'}
		meta.id = new ModPath(id, path.type, path.moduleId);
		meta.composer ??= 'Unknown';
		return meta;
	}
	@:unreflective inline function _onLoad():Void {
		endTime = metadata.length;
		loopTime = metadata.loopPoint;
		if (metadata.checkpoints != null && !metadata.checkpoints.empty()) {
			metadata.checkpoints.sort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time));
			metadata.checkpoints[0].time = 0;
			checkpoints.merge(metadata.checkpoints);
		}
		_bpm = initialBPM = checkpoints.empty() ? 100 : checkpoints[0].bpm;
		onLoad.dispatch(metadata);
	}

	@:unreflective static var _printResyncMessage:Bool = false;
	/**
	 * Resyncs all sounds to the conductor time when called.
	 * @param force If true, it will *force* a resync.
	 */
	public function resyncTracks(force:Bool = false):Void {
		if (!playing) if (!force) return;
		_printResyncMessage = false;
		for (sound in group.sounds) {
			// idea from psych
			if (time > 0 && time < sound.length) {
				if (force || Math.abs(time - sound.time) > 25) {
					sound.play(true, time);
					_printResyncMessage = true;
				}
			} else if (sound.playing)
				sound.pause();
			longestAudio ??= group.sounds[0];
			if (longestAudio.length < sound.length)
				longestAudio = sound;
		}
		if (_printResyncMessage)
			trace(force ? 'Forced Conductor resync on "$id".' : 'Conductor "$id" resynced all tracks to it\'s time.');
		endTime ??= longestAudio.length;
	}
	@:unreflective var longestAudio:FlxSound;

	var _prev_checkpoint:CheckpointMeta;
	var _current_checkpoint:CheckpointMeta;
	var processAnyway:Bool = false; var _elapsed:Float = 0;
	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (!playing) if (!processAnyway) return;

		if (playing) {
			// copied persnake's FlxRhythmConductor code, lol
			final prevTime:Float = time;
			time += elapsed * 1000;
			frameTime = frameTime + elapsed * 1000;
			_elapsed = time - prevTime;
			resyncTracks();
		}

		if (_current_checkpoint != null) _prev_checkpoint = _current_checkpoint;
		_current_checkpoint = getCheckpointFromTime(time);
		_bpm = _current_checkpoint.bpm;

		var info = getInfoFromTime(time);
		stepLength = info.stepLength;
		curStepExact = info.curStepExact;
		if (curStep != info.curStep)
			for (i in curStep...info.curStep + 1) {
				onStepHit.dispatch(curStep = i);
				for (reactor in reactors)
					switch (Type.typeof(reactor)) {
						case TClass(FlxCamera):
							if (FlxG.cameras.list.contains(cast reactor))
								reactor._stepHit(this);
						case TClass(GameState):
							if (cast(reactor, GameState).conductor == this)
								reactor._stepHit(this);
						default: reactor._stepHit(this);
					}
			}
		beatLength = info.beatLength;
		curBeatExact = info.curBeatExact;
		if (curBeat != info.curBeat)
			for (i in curBeat...info.curBeat + 1) {
				onBeatHit.dispatch(curBeat = i);
				for (reactor in reactors)
					switch (Type.typeof(reactor)) {
						case TClass(FlxCamera):
							if (FlxG.cameras.list.contains(cast reactor))
								reactor._beatHit(this);
						case TClass(GameState):
							if (cast(reactor, GameState).conductor == this)
								reactor._beatHit(this);
						default: reactor._beatHit(this);
					}
			}
		measureLength = info.measureLength;
		curMeasureExact = info.curMeasureExact;
		if (curMeasure != info.curMeasure)
			for (i in curMeasure...info.curMeasure + 1) {
				onMeasureHit.dispatch(curMeasure = i);
				for (reactor in reactors)
					switch (Type.typeof(reactor)) {
						case TClass(FlxCamera):
							if (FlxG.cameras.list.contains(cast reactor))
								reactor._measureHit(this);
						case TClass(GameState):
							if (cast(reactor, GameState).conductor == this)
								reactor._measureHit(this);
						default: reactor._measureHit(this);
					}
			}

		if (_prev_checkpoint == null) onBPMChange.dispatch(_current_checkpoint);
		else if (_prev_checkpoint.bpm != _current_checkpoint.bpm)
			onBPMChange.dispatch(_current_checkpoint);

		if (time >= length) onConductorComplete();
		if (time != prevTime) frameTime = prevTime = time;
	}
	@:allow(imaginative.backend.states.GameState)
	@:unreflective static final reactors:Array<IConductorReactive> = [];

	@:unreflective inline function onConductorComplete():Void {
		if (canLoop) {
			play(loopTime, volume);
			trace('Conductor "$id" has looped.');
		} else {
			// pause();
			trace('Conductor "$id" has finished playing.');
		}
	}

	/**
	 * Gets checkpoint metadata from a specific song time **(in milliseconds).**
	 * @param time The song time.
	 * @return The checkpoint metadata.
	 */
	public function getCheckpointFromTime(time:Float):CheckpointMeta {
		if (checkpoints.length == 1) return checkpoints[0];
		var change:CheckpointMeta = new CheckpointMeta(_bpm, time);
		for (checkpoint in checkpoints) {
			if (time < checkpoint.time) continue;
			change = checkpoint;
		}
		return change;
	}
	/**
	 * Gets time related info from a specific song time  **(in milliseconds).**
	 * @param time The song time.
	 * @return The time information.
	 */
	public function getInfoFromTime(time:Float):TimeInfo {
		var checkpoint:CheckpointMeta = getCheckpointFromTime(time);
		var beatLength:Float = 60 / checkpoint.bpm * 1000;
		var stepLength:Float = beatLength / checkpoint.stepsPerBeat;

		var curStepExact = step_from_time(time) + ((time - checkpoint.time) / stepLength);
		var curBeatExact = curStepExact / checkpoint.stepsPerBeat;
		var curMeasureExact = curBeatExact / checkpoint.beatsPerMeasure;

		return {
			curStep: Math.floor(curStepExact),
			curBeat: Math.floor(curBeatExact),
			curMeasure: Math.floor(curMeasureExact),

			curStepExact: curStepExact,
			curBeatExact: curBeatExact,
			curMeasureExact: curMeasureExact,

			stepLength: stepLength,
			beatLength: beatLength,
			measureLength: beatLength * checkpoint.beatsPerMeasure
		}
	}
	@:unreflective inline function step_from_time(time:Float):Float {
		if (checkpoints.empty()) return 0;
		var step:Float = 0;
		var trackedBpm = initialBPM;
		var lastTime:Float = 0;
		for (checkpoint in checkpoints) {
			var newTime:Float = checkpoint.time + 0; // offset
			if (time >= newTime) {
				var stepLength:Float = (60000 / trackedBpm) / checkpoint.stepsPerBeat;
				step += (newTime - lastTime) / stepLength;
				lastTime = newTime;
				trackedBpm = checkpoint.bpm;
			} else break;
		}
		return step;
	}

	/**
	 * An internal variable that states if the song was playing before lost focus kicked in.
	 */
	@:unreflective var _wasPlaying:Bool = false;
	inline function onFocus():Void {
		if (FlxG.autoPause)
			if (_wasPlaying)
				resume();
	}
	inline function onFocusLost():Void {
		if (FlxG.autoPause) {
			_wasPlaying = playing;
			pause();
		}
	}

	override public function destroy():Void {
		reset();
		FlxG.signals.focusGained.remove(onFocus);
		FlxG.signals.focusLost.remove(onFocusLost);
		FlxG.plugins.remove(this);
		onLoad.destroy();
		onLoop.destroy();
		onComplete.destroy();
		onBPMChange.destroy();
		onStepHit.destroy();
		onBeatHit.destroy();
		onMeasureHit.destroy();
		super.destroy();
	}
}

typedef TimeInfo = {
	/**
	 * The amount of steps into the song.
	 */
	var curStep:Int;
	/**
	 * The amount of beats into the song.
	 */
	var curBeat:Int;
	/**
	 * The amount of measure into the song.
	 */
	var curMeasure:Int;

	/**
	 * The **exact** "curStep" of the song.
	 */
	var curStepExact:Float;
	/**
	 * The **exact** "curBeat" of the song.
	 */
	var curBeatExact:Float;
	/**
	 * The **exact** "curMeasure" of the song.
	 */
	var curMeasureExact:Float;

	/**
	 * The length of a step **(in milliseconds)**.
	 */
	var stepLength:Float;
	/**
	 * The length of a beat **(in milliseconds)**.
	 */
	var beatLength:Float;
	/**
	 * The length of a measure **(in milliseconds)**.
	 */
	var measureLength:Float;
}