package imaginative.backend.scripting.types;

@:allow(imaginative.backend.scripting.Script)
@:allow(imaginative.backend.systems.Conductor)
class GlobalScript {
	public static var scripts:ScriptGroup;

	extern inline static function init():Void {
		trace('Initializing Global Scripting');

		FlxG.signals.focusLost.add(() -> call('onFocusLost'));
		FlxG.signals.focusGained.add(() -> call('onFocusGained'));

		FlxG.signals.gameResized.add((width:Int, height:Int) -> call('onGameResized', [width, height]));

		FlxG.signals.preDraw.add(() -> call('onDraw'));
		FlxG.signals.postDraw.add(() -> call('onDrawPost'));

		FlxG.signals.preUpdate.add(() -> call('onUpdate', [FlxG.delta]));
		FlxG.signals.postUpdate.add(() -> call('onUpdatePost', [FlxG.delta]));

		FlxG.signals.preStateSwitch.add(() -> call('onPreStateSwitch'));
		FlxG.signals.postStateSwitch.add(() -> call('onStateSwitch'));

		FlxG.signals.preStateCreate.add(state -> call('onPreCreate', [state]));

		loadScripting(); // temp location, will run somewhere else at a later date
	}

	static function loadScripting():Void {
		if (scripts != null) {
			trace('Destroying Global Scripts');
			scripts.destroy();
			scripts = null;
		}
		if (scripts == null) {
			trace('Creating Global Scripts');
			scripts = new ScriptGroup(GlobalScript);
			var folderPath:ModPath = Paths.script(new ModPath('data/global', TOP));
			if (folderPath.isFile)
				scripts.add(Script.create(folderPath));
			else for (data in Paths.readFolder(folderPath, Script.exts, true))
					for (script in Script.multiCreate(data.toString()))
						scripts.add(script);
			scripts.load();
		}
	}

	/**
	 * Calls a function throughout the group.
	 * @param callback The function name.
	 * @param arguments The function arguments.
	 * @param def If the function return is null, it returns this.
	 * @return The functions return value.
	 */
	inline public static function call<R>(callback:String, ?arguments:Array<Any>, ?def:ScriptRetCall<R>):Null<R> {
		if (scripts != null)
			return scripts.call(callback, arguments, def);
		return def.call(scripts);
	}
	/**
	 * Runs an event call throughout the state scripts.
	 * @param callback The function name.
	 * @param event The event to call.
	 * @param parentOverride What the parent should temporally be when called.
	 * @return The event that was called.
	 */
	inline public static function event<E:CallableEvent>(callback:String, event:E, ?parentOverride:Any):E {
		if (scripts != null)
			return scripts.event(callback, event, parentOverride);
		return event;
	}

	inline static function _stepHit(target:Conductor):Void {
		if (scripts != null)
			scripts.set('curStep', target.curStep);
		call('onStepHit', [target.curStep, target]);
	}
	inline static function _beatHit(target:Conductor):Void {
		if (scripts != null)
			scripts.set('curBeat', target.curBeat);
		call('onBeatHit', [target.curBeat, target]);
	}
	inline static function _measureHit(target:Conductor):Void {
		if (scripts != null)
			scripts.set('curMeasure', target.curMeasure);
		call('onMeasureHit', [target.curMeasure, target]);
	}
}