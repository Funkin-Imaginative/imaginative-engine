package imaginative.backend.states;

import flixel.FlxCamera;
import flixel.FlxSubState;

@:build(imaginative.backend.macro.ForwardMacro.buildMap('conductor', [['time', 'songTime'], ['length', 'songLength']]))
@:build(imaginative.backend.macro.ForwardMacro.buildList('conductor', [
	'initialBPM', 'currentBPM',
	'curStep', 'curBeat', 'curMeasure',
	'curStepExact', 'curBeatExact', 'curMeasureExact',
	'stepsPerBeat', 'beatsPerMeasure', 'stepsPerMeasure',
	'stepLength', 'beatLength', 'measureLength'
]))
class GameState extends FlxSubState implements IConductorReactive {
	/**
	 * The id of the state, basically just it's class name at times.
	 */
	public var id:String;

	/**
	 * The states conductor instance.
	 */
	@:isVar public var conductor(get, set):Conductor;
	@:noCompletion public var parentConductor(default, null):Conductor;
	function get_conductor():Conductor return Conductor.menu;
	function set_conductor(value:Conductor):Conductor return get_conductor();
	// is overrideable ^^

	/**
	 * The parent of the state, ***if*** it's a substate, otherwise, this is null.
	 */
	public var parent:GameState;

	/**
	 * If true, then this state instance is a substate.
	 */
	public var isSubState(get, never):Bool;
	inline function get_isSubState():Bool
		return FlxG.state != this;

	/**
	 * If true, then if this is a substate, then the parent state will be paused.
	 */
	public var freezeParent:Bool;

	public function new(?id:String, freezeParent:Bool = false) {
		super();
		this.id = id ?? {
			var lol = Type.getClassName(Type.getClass(this));
			lol.getSlice('.', lol.getSliceCount('.') - 1);
		}
		persistentUpdate = true;
		this.freezeParent = freezeParent;
	}

	public var stateCamera:FlxCamera;

	function preCreate():Void {
		cameras = [stateCamera = new FlxCamera()];
		FlxG.cameras.add(stateCamera);
		stateCamera.bgColor = FlxColor.TRANSPARENT;
	}
	override function create():Void {
		super.create();
		Conductor.reactors.push(this);
		if (!isSubState) FlxG.signals.postStateSwitch.addOnce(createPost);
	}
	function createPost():Void {}

	override function tryUpdate(delta:Float):Void {
		if (persistentUpdate || subState == null) {
			preUpdate(delta);
			update(delta);
			updatePost(delta);
		}
		if (_requestSubStateReset) {
			_requestSubStateReset = false;
			resetSubState();
		}
		if (subState != null)
			subState.tryUpdate(delta);
	}

	function preUpdate(delta:Float):Void {}
	override function update(delta:Float):Void {
		super.update(delta);
	}
	function updatePost(delta:Float):Void {}

	override function openSubState(sub:FlxSubState):Void {
		if (sub is GameState) {
			var state:GameState = cast sub;
			state.parent = this;
			if (state.freezeParent) {
				if (state.conductor != conductor)
					conductor.pause();
				state.parent.persistentUpdate = false;
			}
		}
		super.openSubState(sub);
	}
	override function resetSubState():Void {
		// Close the old state (if there is an old state)
		if (subState != null) {
			if (subState.closeCallback != null)
				subState.closeCallback();
			if (_subStateClosed != null)
				_subStateClosed.dispatch(subState);

			if (destroySubStates)
				subState.destroy();
		}

		// Assign the requested state (or set it to null)
		subState = _requestedSubState;
		_requestedSubState = null;

		if (subState != null) {
			// Reset the input so things like "justPressed" won't interfere
			if (!persistentUpdate)
				@:privateAccess FlxG.inputs.onStateSwitch();

			subState._parentState = this;
			if (subState is GameState)
				cast(subState, GameState).parent = this;

			if (!subState._created) {
				subState._created = true;
				if (subState is GameState)
					cast(subState, GameState).preCreate();
				subState.create();
				if (subState is GameState)
					cast(subState, GameState).createPost();
			}
			if (subState.openCallback != null)
				subState.openCallback();
			if (_subStateOpened != null)
				_subStateOpened.dispatch(subState);
		}
	}

	override function close():Void {
		if (freezeParent) {
			parent.persistentUpdate = true;
			if (parent.conductor != conductor)
				parent.conductor.resume();
		}
		super.close();
	}

	function onReset():Void {}

	function _stepHit(target:Conductor):Void {
		stepHit(target.curStep, parentConductor = target);
		forEach(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			@:privateAccess reactor._stepHit(target);
		}, true);
	}
	function _beatHit(target:Conductor):Void {
		beatHit(target.curBeat, parentConductor = target);
		forEach(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			@:privateAccess reactor._beatHit(target);
		}, true);
	}
	function _measureHit(target:Conductor):Void {
		measureHit(target.curMeasure, parentConductor = target);
		forEach(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			@:privateAccess reactor._measureHit(target);
		}, true);
	}

	function stepHit(step:Int, target:Conductor):Void {}
	function beatHit(beat:Int, target:Conductor):Void {}
	function measureHit(measure:Int, target:Conductor):Void {}

	override function startOutro(onOutroComplete:Void -> Void):Void {
		onOutroComplete();
	}

	override function destroy():Void {
		if (Conductor.reactors.contains(this))
			Conductor.reactors.remove(this);
		super.destroy();
	}
}