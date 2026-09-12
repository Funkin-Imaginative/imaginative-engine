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
	public final id:String;
	/**
	 * If true, then when this state is created, scripts will be initalized.
	 */
	public final allowScripts:Bool;

	/**
	 * The states conductor instance.
	 */
	@:isVar public var conductor(get, set):Conductor;
	@:noCompletion public var parentConductor(default, null):Conductor;
	@:noCompletion function get_conductor():Conductor return Conductor.menu;
	@:noCompletion function set_conductor(value:Conductor):Conductor return get_conductor();
	// is overrideable ^^^

	/**
	 * The parent of the state, ***if*** it's a substate, otherwise, this is null.
	 */
	public var parent:GameState;

	/**
	 * If true, then this state instance is a substate.
	 */
	public var isSubState(get, never):Bool;
	@:noCompletion inline function get_isSubState():Bool
		return FlxG.state != this;

	/**
	 * If true, then if this is a substate, then the parent state will be paused.
	 */
	public var freezeParent:Bool = false;

	public function new(allowScripts:Bool = true, ?id:String) {
		super();
		this.allowScripts = #if Scripting.States allowScripts #else false #end;
		this.id = id ?? flixel.util.FlxStringUtil.getClassName(this, true);
		persistentUpdate = true;
	}

	public var stateScripts:Null<ScriptGroup> = null;
	function loadScripting():Void { // in-case you wanna override this or smth
		if (!allowScripts) return;
		add(stateScripts = new ScriptGroup(this));
		for (script in Script.multiCreate('data/states/$id'))
			stateScripts.add(script);
		ArrayUtil.clearLast();
		stateScripts.load();
	}

	/**
	 * Calls a function throughout the state scripts.
	 * @param callback The function name.
	 * @param arguments The function arguments.
	 * @param def If the function return is null, it returns this.
	 * @return The functions return value.
	 */
	inline public function scriptCall<R>(callback:String, ?arguments:Array<Any>, ?def:ScriptRetCall<R>):Null<R> {
		if (allowScripts && stateScripts != null)
			return stateScripts.call(callback, arguments, def);
		return def.call(stateScripts);
	}
	/**
	 * Runs an event call throughout the state scripts.
	 * @param callback The function name.
	 * @param event The event to call.
	 * @param parentOverride What the parent should temporally be when called.
	 * @return The event that was called.
	 */
	inline public function eventCall<E:CallableEvent>(callback:String, event:E, ?parentOverride:Any):E {
		if (allowScripts && stateScripts != null)
			return stateScripts.event(callback, event, parentOverride);
		return event;
	}

	public var stateCamera:FlxCamera;

	function preCreate():Void {
		loadScripting();
		scriptCall('onPreCreate');
		FlxG.cameras.reset(camera = stateCamera = new FlxCamera());
		stateCamera.bgColor = isSubState ? FlxColor.TRANSPARENT : FlxColor.BLACK;
	}
	override function create():Void {
		FlxG.watch.addFunction('State', () -> {
			var lol = flixel.util.FlxStringUtil.getClassName(this, true);
			var result = id != lol ? '$id ($lol)' : id;
			#if Scripting.States result += ' (${allowScripts ? 'SCRIPTABLE' : 'NO SCRIPTING'})'; #end
			return result;
		});

		FlxG.watch.addFunction('Conductor', () -> conductor.id);
		FlxG.watch.addFunction('Song/Composer', () -> '${conductor.metadata.name} - ${conductor.metadata.composer}');
		FlxG.watch.addFunction('Time/Length', () -> '${flixel.util.FlxStringUtil.formatTime(songTime / 1000)} / ${flixel.util.FlxStringUtil.formatTime(songLength / 1000, true)}');
		FlxG.watch.addFunction('Bpm/Signature', () -> '$currentBPM - $beatsPerMeasure / $stepsPerBeat');
		FlxG.watch.addFunction('Step/Beat/Measure', () -> '$curStep - $curBeat - $curMeasure');

		super.create();
		scriptCall('onCreate');
		Conductor.reactors.push(this);
		if (!isSubState) FlxG.signals.postStateSwitch.addOnce(createPost);
	}
	function createPost():Void
		scriptCall('onCreatePost');

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

	function preUpdate(delta:Float):Void
		scriptCall('onPreUpdate', [delta]);
	override function update(delta:Float):Void {
		super.update(delta);
		scriptCall('onUpdate', [delta]);
	}
	function updatePost(delta:Float):Void
		scriptCall('onUpdatePost');

	override function draw():Void {
		var event = eventCall('onDraw', CallableEvent.recycle());
		if (event.cancelled) return;
		super.draw(); scriptCall('onDrawPost');
	}

	override function openSubState(sub:FlxSubState):Void {
		scriptCall('uponOpeningSubstate', [sub]);
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
	override function closeSubState():Void {
		scriptCall('uponClosingSubstate', [subState]);
		super.closeSubState();
	}
	override function resetSubState():Void {
		scriptCall('uponResetingSubstate');
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
		var event = eventCall('onClose', CallableEvent.recycle());
		if (event.cancelled) return;
		if (freezeParent) {
			parent.persistentUpdate = true;
			if (parent.conductor != conductor)
				parent.conductor.resume();
		}
		super.close();
		scriptCall('onClosePost');
	}

	function onReset():Void
		scriptCall('uponResetingState');

	function _stepHit(target:Conductor):Void {
		stepHit(target.curStep, parentConductor = target);
		forEach(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			@:privateAccess reactor._stepHit(target);
		}, true);
		scriptCall('onStepHit', [target.curStep, parentConductor]);
	}
	function _beatHit(target:Conductor):Void {
		beatHit(target.curBeat, parentConductor = target);
		forEach(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			@:privateAccess reactor._beatHit(target);
		}, true);
		scriptCall('onBeatHit', [target.curBeat, parentConductor]);
	}
	function _measureHit(target:Conductor):Void {
		measureHit(target.curMeasure, parentConductor = target);
		forEach(member -> {
			if (!(member is IConductorReactive)) return;
			var reactor:IConductorReactive = cast member;
			@:privateAccess reactor._measureHit(target);
		}, true);
		scriptCall('onMeasureHit', [target.curMeasure, parentConductor]);
	}

	function stepHit(step:Int, target:Conductor):Void {}
	function beatHit(beat:Int, target:Conductor):Void {}
	function measureHit(measure:Int, target:Conductor):Void {}

	/* override function startOutro(onOutroComplete:() -> Void):Void {
		onOutroComplete();
	} */

	override function destroy():Void {
		if (Conductor.reactors.contains(this))
			Conductor.reactors.remove(this);
		super.destroy();
	}
}