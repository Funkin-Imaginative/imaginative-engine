package imaginative.sprites;

enum abstract DanceOnType(String) { // temp location?
	var STEP = 'step';
	var BEAT = 'beat';
	var MEASURE = 'measure';
}

/* @:build(imaginative.backend.macro.ForwardMacro.buildList('_conductor', [
	'curStep', 'curBeat', 'curMeasure',
	'curStepExact', 'curBeatExact', 'curMeasureExact',
	'stepsPerBeat', 'beatsPerMeasure', 'stepsPerMeasure',
	'stepLength', 'beatLength', 'measureLength'
])) */
class BeatSprite extends BaseSprite implements IConductorReactive {
	/**
	 * When the sprite should be dancing.
	 */
	public var danceEvery:DanceOnType;
	/**
	 * The amount many of "danceEvery" that must pass for the sprite to dance.
	 */
	public var danceInterval:Int;

	/**
	 * If true, the sprite will not dance, **period**.
	 */
	public var preventDance:Bool = false;

	/**
	 * Sets up how the sprite should dance.
	 * @param every When the sprite should be dancing.
	 * @param interval The amount many of "every" that must pass for the sprite to dance.
	 * @return The sprite itself.
	 */
	inline public function setupDance(every:DanceOnType = BEAT, ?interval:Int):BeatSprite {
		danceEvery = every;
		danceInterval = interval ?? switch (every) {
			case STEP: 4;
			case BEAT: 2;
			case MEASURE: 1;
		}
		return this;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (!debugMode && animationContext != IsDancing)
			tryDance();
	}

	/**
	 * Attempts to trigger the sprite to dance.
	 */
	public function tryDance():Void {
		switch (animationContext) {
			case IsDancing:
				dance();
			case NoDancing | NoSinging:
				if (animation.name == null)
					dance();
			default:
				if (animation.name == null || animation.finished)
					dance();
		}
	}
	/**
	 * Triggers the sprite to dance.
	 */
	public function dance():Void {
		if (preventDance) return;
		playAnimation('idle', IsDancing);
	}

	/* function _stepHit(target:Conductor):Void {
		stepHit(target.curStep, target);
	}
	function _beatHit(target:Conductor):Void {
		beatHit(target.curBeat, target);
	}
	function _measureHit(target:Conductor):Void {
		measureHit(target.curMeasure, target);
	} */
}