package imaginative.sprites;

/* @:build(imaginative.backend.macro.ForwardMacro.buildList('conductor', [
	'curStep', 'curBeat', 'curMeasure',
	'curStepExact', 'curBeatExact', 'curMeasureExact',
	'stepsPerBeat', 'beatsPerMeasure', 'stepsPerMeasure',
	'stepLength', 'beatLength', 'measureLength'
])) */
class BeatSprite extends BaseSprite implements IConductorReactive {
	/**
	 * When the sprite should be dancing.
	 */
	public var danceEvery(default, set):BeatTimes;
	inline function set_danceEvery(value:BeatTimes):BeatTimes
		return danceEvery = value.resolveForDancing();
	/**
	 * The amount many of "danceEvery" that must pass for the sprite to dance.
	 */
	public var danceInterval:Int;
	/**
	 * A multiplier for "danceInterval".
	 */
	public var danceSpeedMult:Float = 1;

	/**
	 * If true, the sprite will not dance, **period**.
	 */
	public var preventDancing:Bool = false;
	/**
	 * If true, the sprite can dance when the song time is in the negatives.
	 */
	public var danceBeforeStart:Bool = true;

	/**
	 * Sets up how the sprite should dance.
	 * @param every When the sprite should be dancing.
	 * @param interval The amount many of "every" that must pass for the sprite to dance.
	 * @return The sprite itself.
	 */
	inline public function setupDance(every:BeatTimes = BEATS, ?interval:Int):BeatSprite {
		danceEvery = every.resolveForDancing();
		danceInterval = interval ?? switch (every) {
			case MILLISECONDS: throw 'How tf did you do this??';
			case STEPS: 4;
			case BEATS: 2;
			case MEASURES: 1;
		}
		return this;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (!debugMode && !preventDancing && animationContext != IsDancing)
			if (parentConductor != null)
				tryDance(switch (danceEvery) {
					case MILLISECONDS: throw 'How tf did you do this??';
					case STEPS: parentConductor.curStep;
					case BEATS: parentConductor.curBeat;
					case MEASURES: parentConductor.curMeasure;
				});
	}

	/**
	 * The animation suffix for when dancing specially.
	 */
	public var danceSuffix(default, set):Null<String>;
	inline function set_danceSuffix(?value:String):Null<String>
		return danceSuffix = value.isBlank() ? null : value.trim();

	override function getSuffixViaContext(context:AnimationContext):Null<String> {
		return switch (context) {
			case IsDancing: danceSuffix;
			default: super.getSuffixViaContext(context);
		}
	}

	/**
	 * Attempts to trigger the sprite to dance.
	 * @param tick Current dance tick (as in *step*, *beat* and *measure*), used for handling multiple dance animations.
	 */
	public function tryDance(tick:Int):Void {
		switch (animationContext) {
			case IsDancing:
				dance(tick);
			case NoDancing | NoSinging:
				if (animation.name == null)
					dance(tick);
			default:
				if (animation.name == null || animation.finished)
					dance(tick);
		}
	}
	/**
	 * Triggers the sprite to dance.
	 * @param tick Current dance tick (as in *step*, *beat* and *measure*), used for handling multiple dance animations.
	 */
	public function dance(tick:Int):Void {
		if (preventDancing) return;
		calculateDanceSteps(danceSuffix);
		var totalSteps:Int = totalDanceSteps.get(danceSuffix) ?? 1;
		var danceStep:Int = totalSteps == 0 ? 1 : tick % totalSteps;
		var danceTag:String = danceStep < 1 ? '' : Std.string(danceStep);
		playAnimation('dance$danceTag', IsDancing);
	}
	@:unreflective final totalDanceSteps:Map<String, Int> = new Map<String, Int>();
	@:unreflective inline function calculateDanceSteps(?suffix:String):Void {
		totalDanceSteps.set(suffix, 0);
		for (anim in @:privateAccess animation._animations)
			if (anim.name.startsWith('dance') && (suffix.isBlank() || anim.name.endsWith(suffix)))
				totalDanceSteps.set(suffix, totalDanceSteps.get(suffix) + 1);
	}

	public var parentConductor(default, null):Conductor;
	@:noCompletion function _stepHit(target:Conductor):Void {
		stepHit(target.curStep, parentConductor = target);
	}
	@:noCompletion function _beatHit(target:Conductor):Void {
		beatHit(target.curBeat, parentConductor = target);
	}
	@:noCompletion function _measureHit(target:Conductor):Void {
		measureHit(target.curMeasure, parentConductor = target);
	}

	@:noCompletion function stepHit(step:Int, target:Conductor):Void
		if (danceEvery == STEPS)
			_tryDance(step);
	@:noCompletion function beatHit(beat:Int, target:Conductor):Void
		if (danceEvery == BEATS)
			_tryDance(beat);
	@:noCompletion function measureHit(measure:Int, target:Conductor):Void
		if (danceEvery == MEASURES)
			_tryDance(measure);

	@:unreflective inline function _tryDance(tick:Int):Void {
		if (!preventDancing && !(danceBeforeStart && tick < 0)) {
			var danceSpeed:Int = Math.round(danceInterval * danceSpeedMult);
			if (danceSpeed > 0 && tick % danceSpeed == 0) {
				tryDance(tick);
				if (animationContext != IsDancing && animation.name.endsWith('-loop'))
					animation.finish();
			} else if (danceSpeed < 1) trace('Current interval is below 0, please change this.');
		}
	}
}