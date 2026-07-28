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
	/**
	 * The states conductor instance.
	 */
	@:isVar public var conductor(get, set):Conductor;
	function get_conductor():Conductor return Conductor.menu;
	function set_conductor(value:Conductor):Conductor return get_conductor();
	// is overrideable ^^

	public function new() {
		super();
	}

	override function create():Void {
		super.create();
		Conductor.reactors.push(this);
	}

	function _stepHit(target:Conductor):Void {
		stepHit(target.curStep, target);
		forEachExists(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			reactor._stepHit(target);
		}, true);
	}
	function _beatHit(target:Conductor):Void {
		beatHit(target.curBeat, target);
		forEachExists(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			reactor._beatHit(target);
		}, true);
	}
	function _measureHit(target:Conductor):Void {
		measureHit(target.curMeasure, target);
		forEachExists(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			reactor._measureHit(target);
		}, true);
	}

	override function destroy():Void {
		Conductor.reactors.remove(this);
		super.destroy();
	}
}