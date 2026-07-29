package imaginative.backend.states;

/* @:build(imaginative.backend.macro.ForwardMacro.buildMap('conductor', ['time' => 'songTime', 'length' => 'songLength'], false))
@:build(imaginative.backend.macro.ForwardMacro.buildList('conductor', [
	'initialBPM', 'currentBPM',
	'curStep', 'curBeat', 'curMeasure',
	'curStepExact', 'curBeatExact', 'curMeasureExact',
	'stepsPerBeat', 'beatsPerMeasure', 'stepsPerMeasure',
	'stepLength', 'beatLength', 'measureLength'
], false)) */
class GameState extends flixel.FlxSubState implements IConductorReactive {
	@:noCompletion public var parentConductor(default, null):Conductor;
	/**
	 * The states conductor instance.
	 */
	@:isVar public var conductor(get, set):Conductor;
	function get_conductor():Conductor return Conductor.menu;
	function set_conductor(value:Conductor):Conductor return get_conductor();
	// is overrideable ^^

	public function new() {
		super();
		persistentUpdate = true;
	}

	override function create():Void {
		super.create();
		Conductor.reactors.push(this);
	}

	@:noCompletion function _stepHit(target:Conductor):Void {
		stepHit(target.curStep, parentConductor = target);
		forEach(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			@:privateAccess reactor._stepHit(target);
		}, true);
	}
	@:noCompletion function _beatHit(target:Conductor):Void {
		beatHit(target.curBeat, parentConductor = target);
		forEach(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			@:privateAccess reactor._beatHit(target);
		}, true);
	}
	@:noCompletion function _measureHit(target:Conductor):Void {
		measureHit(target.curMeasure, parentConductor = target);
		forEach(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			@:privateAccess reactor._measureHit(target);
		}, true);
	}

	@:noCompletion function stepHit(step:Int, target:Conductor):Void {}
	@:noCompletion function beatHit(beat:Int, target:Conductor):Void {}
	@:noCompletion function measureHit(measure:Int, target:Conductor):Void {}

	override function destroy():Void {
		Conductor.reactors.remove(this);
		super.destroy();
	}
}