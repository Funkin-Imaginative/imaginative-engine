package imaginative.backend.systems;

import flixel.FlxCamera;
import flixel.sound.FlxSound;
import flixel.sound.FlxSoundGroup;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import imaginative.backend.states.GameState;

@:allow(imaginative.backend.systems.Conductor)
interface IConductorReactive {
	var parentConductor(default, null):Conductor;

	private function _stepHit(target:Conductor):Void;
	private function _beatHit(target:Conductor):Void;
	private function _measureHit(target:Conductor):Void;

	@:noCompletion private function stepHit(step:Int, target:Conductor):Void;
	@:noCompletion private function beatHit(beat:Int, target:Conductor):Void;
	@:noCompletion private function measureHit(measure:Int, target:Conductor):Void;
}

typedef MusicMeta = {
	/**
	 * The song id / folder name.
	 */
	var id:ModPath;
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
	 * The time the song should loop from **(in steps)**.
	 *
	 * Note: Only works if the conductor has "canLoop" enabled.
	 */
	var ?loopPoint:Float;
	/**
	 * How long the song is **(in steps)**.
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

	extern inline static function init():Void {
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
	public final onLoop:FlxTypedSignal<() -> Void> = new FlxTypedSignal<() -> Void>();
	/**
	 * Dispatches whenever the song ends.
	 */
	public final onComplete:FlxTypedSignal<() -> Void> = new FlxTypedSignal<() -> Void>();

	/**
	 * If true, when the audio ends, it will loop.
	 */
	public var canLoop:Bool;
	/**
	 * The time the song should loop from **(in steps)**.
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
	 * How long the song is **(in steps)**.
	 */
	public var endTime:Null<Float>;

	/**
	 * The length of the song **(in milliseconds)**.
	 */
	public var length(get, never):Float;
	inline function get_length():Float {
		if (endTime == null) return longestAudio?.length ?? 0;
		return getTime(endTime, STEPS, MILLISECONDS);
	}

	/**
	 * The metadata for the current song.
	 */
	public var metadata:MusicMeta = {id: 'No Metadata', name: 'No Metadata', composer: 'No Metadata'}

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
	inline public function resume():Void
		play(time, volume);

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
		curStepExact = curBeatExact = curMeasureExact = 0;
		stepLength = beatLength = measureLength = 0;
		stepsPerBeat = beatsPerMeasure = 4;
		initialBPM = currentBPM = _bpm = 100;
		checkpoints.clear();
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
		if (meta == null) return {id: 'Failed Parse', name: id, composer: 'Failed Parse'}
		meta.id = new ModPath(id, path.type, path.moduleId);
		meta.name.ifBlankReplace(id);
		meta.composer ??= 'Unknown';
		return meta;
	}
	extern inline function _onLoad():Void {
		endTime = metadata.length;
		loopTime = metadata.loopPoint;
		if (metadata.checkpoints != null && !metadata.checkpoints.empty()) {
			metadata.checkpoints.sort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time));
			metadata.checkpoints[0].time = 0;
			checkpoints.merge(metadata.checkpoints);
		}
		if (checkpoints.empty()) {
			trace('No checkpoints detected for "${metadata.name}", double check your shit.');
			checkpoints.push(new CheckpointMeta(100));
		}
		_bpm = initialBPM = checkpoints[0].bpm;
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
		longestAudio ??= group.sounds[0] ?? null;
		for (sound in group.sounds) {
			// idea from psych
			if (time > 0 && time < sound.length) {
				if (force || Math.abs(time - sound.time) > 25) {
					sound.play(true, time);
					_printResyncMessage = true;
				}
			} else if (sound.playing)
				sound.pause();
			if (longestAudio.length < sound.length)
				longestAudio = sound;
		}
		if (_printResyncMessage)
			trace(force ? 'Forced Conductor "$id" to resync.' : 'Conductor "$id" resynced all tracks to it\'s time.');
	}
	@:unreflective var longestAudio:FlxSound;

	var _prev_checkpoint:CheckpointMeta;
	var _current_checkpoint:CheckpointMeta;
	var processAnyway:Bool = false; var _delta:Float = 0;
	override function update(delta:Float):Void {
		super.update(delta);
		if (!playing) if (!processAnyway) return;

		if (playing) {
			// copied persnake's FlxRhythmConductor code, lol
			final prevTime:Float = time;
			time += delta * 1000;
			frameTime = frameTime + delta * 1000;
			_delta = time - prevTime;
			resyncTracks();
		}

		if (_current_checkpoint != null) _prev_checkpoint = _current_checkpoint;
		_current_checkpoint = getCheckpointFromTime(time);
		_bpm = _current_checkpoint.bpm;

		var info = getInfoFromTime(time);
		stepLength = info.stepLength;
		curStepExact = info.curStepExact;
		if (curStep != info.curStep) {
			curStep = info.curStep;
			if (playing) {
				onStepHit.dispatch(curStep);
				for (reactor in reactors)
					if (reactor is FlxCamera) {
						if (FlxG.cameras.list.contains(cast reactor))
							reactor._stepHit(this);
					} else if (reactor is GameState) {
						var state:GameState = cast reactor;
						if (state.conductor == this && (state.persistentUpdate || state.subState == null))
							reactor._stepHit(this);
					} else reactor._stepHit(this);
			}
		}
		beatLength = info.beatLength;
		curBeatExact = info.curBeatExact;
		if (curBeat != info.curBeat) {
			curBeat = info.curBeat;
			if (playing) {
				onBeatHit.dispatch(curBeat);
				for (reactor in reactors)
					if (reactor is FlxCamera) {
						if (FlxG.cameras.list.contains(cast reactor))
							reactor._beatHit(this);
					} else if (reactor is GameState) {
						var state:GameState = cast reactor;
						if (state.conductor == this && (state.persistentUpdate || state.subState == null))
							reactor._beatHit(this);
					} else reactor._beatHit(this);
			}
		}
		measureLength = info.measureLength;
		curMeasureExact = info.curMeasureExact;
		if (curMeasure != info.curMeasure) {
			curMeasure = info.curMeasure;
			if (playing) {
				onMeasureHit.dispatch(curMeasure);
				for (reactor in reactors)
					if (reactor is FlxCamera) {
						if (FlxG.cameras.list.contains(cast reactor))
							reactor._measureHit(this);
					} else if (reactor is GameState) {
						var state:GameState = cast reactor;
						if (state.conductor == this && (state.persistentUpdate || state.subState == null))
							reactor._measureHit(this);
					} else reactor._measureHit(this);
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

	extern inline function onConductorComplete():Void {
		if (canLoop) {
			play(getTime(loopTime, STEPS, MILLISECONDS), volume);
			trace('Conductor "$id" has looped.');
		} else {
			pause();
			trace('Conductor "$id" has finished playing.');
		}
	}

	public function getTime(time:Float, from:BeatTimes, to:BeatTimes):Float {
		if (from == to) throw '"from" and "to" must be different.';
		return switch (from) {
			case MILLISECONDS:
				var info = getInfoFromTime(time);
				switch (to) {
					case MILLISECONDS: throw 'heheheha';
					case STEPS: info.curStepExact;
					case BEATS: info.curBeatExact;
					case MEASURES: info.curMeasureExact;
				}
			case STEPS:
				switch (to) {
					case MILLISECONDS: getTime(time, BEATS, MILLISECONDS) / stepsPerBeat;
					case STEPS: throw 'heheheha';
					case BEATS: getTime(getTime(time, STEPS, MILLISECONDS), MILLISECONDS, BEATS);
					case MEASURES: getTime(getTime(time, STEPS, MILLISECONDS), MILLISECONDS, MEASURES);
				}
			case BEATS:
				switch (to) {
					case MILLISECONDS: (time * 60000) / currentBPM;
					case STEPS: getTime(getTime(time, BEATS, MILLISECONDS), MILLISECONDS, STEPS);
					case BEATS: throw 'heheheha';
					case MEASURES: getTime(getTime(time, BEATS, MILLISECONDS), MILLISECONDS, MEASURES);
				}
			case MEASURES:
				switch (to) {
					case MILLISECONDS: getTime(time, BEATS, MILLISECONDS) / beatsPerMeasure;
					case STEPS: getTime(getTime(time, MEASURES, MILLISECONDS), MILLISECONDS, STEPS);
					case BEATS: getTime(getTime(time, MEASURES, MILLISECONDS), MILLISECONDS, BEATS);
					case MEASURES: throw 'heheheha';
				}
		}
	}

	/**
	 * Gets checkpoint metadata from a specific song time **(in milliseconds)**.
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
	 * Gets music beat information from a specific song time **(in milliseconds)**.
	 * @param time The song time.
	 * @return The beat information.
	 */
	public function getInfoFromTime(time:Float):BeatInfo {
		var checkpoint:CheckpointMeta = getCheckpointFromTime(time);
		var beat_length:Float = 60 / checkpoint.bpm * 1000;
		var step_length:Float = beat_length / checkpoint.stepsPerBeat;

		var stepExact = step_from_time(time) + ((time - checkpoint.time) / step_length);
		var beatExact = stepExact / checkpoint.stepsPerBeat;
		var measureExact = beatExact / checkpoint.beatsPerMeasure;

		return {
			curStep: Math.floor(stepExact),
			curBeat: Math.floor(beatExact),
			curMeasure: Math.floor(measureExact),

			curStepExact: stepExact,
			curBeatExact: beatExact,
			curMeasureExact: measureExact,

			stepLength: step_length,
			beatLength: beat_length,
			measureLength: beat_length * checkpoint.beatsPerMeasure
		}
	}
	extern inline function step_from_time(time:Float):Float {
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

enum abstract BeatTimes(String) {
	var MILLISECONDS = 'milliseconds';

	var STEPS = 'steps';
	var BEATS = 'beats';
	var MEASURES = 'measures';
}

/**
 * Music beat information.
 */
typedef BeatInfo = {
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