package imaginative.backend.scripting;

import flixel.group.FlxGroup;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;

// TODO: Give ScriptRetCall its own file.
/**
 * The callback for script group default defines.
 * @param V The current value that has been determined by the loop.
 * @param ScriptInstance The current script from within the loop.
 * @param V The returned value of the current script.
 * @return The final value that has been determined.
 */
typedef TScriptRetCall<V> = (?V, ScriptInstance, ?V) -> V;
/**
 * Wrapper for `TScriptRetCall`.
 */
abstract ScriptRetCall<V>(TScriptRetCall<V>) from TScriptRetCall<V> to TScriptRetCall<V> {
	@:from inline public static function fromV<V>(value:V):ScriptRetCall<V>
		return cast value;

	inline public function call(?cur:V, script:ScriptInstance, ?ret:V):V {
		if (this == null) return ret ?? cur;
		if (!Reflect.isFunction(this)) return cast ret ?? cast this ?? cast cur;
		return this(cur, script, ret);
	}
}

/**
 * Handles multiple scripts at once.
 */
class ScriptGroup extends Script {
	/**
	 * Gets dispatched when the "event" function is called.
	 * @param String The function name that was called.
	 * @param CallableEvent The event that was called.
	 * @param Dynamic The script parent.
	 */
	public final onEventCall:FlxTypedSignal<(String, CallableEvent, Dynamic) -> Void> = new FlxTypedSignal<(String, CallableEvent, Dynamic) -> Void>();

	// script related variables
	@:noCompletion override function get_type():ScriptType
		return TypeGroup;

	@:unreflective @:noCompletion var _parent:Dynamic = null;
	@:noCompletion override function get_parent():Dynamic return _parent;
	@:noCompletion override function set_parent(value:Dynamic):Dynamic {
		_parent = value;
		forEach(script -> script.parent = value);
		return value;
	}

	// group related variables
	public final group:FlxTypedGroup<Script>;
	public final members:Array<ScriptInstance>;

	public var length(get, never):Int;
	@:noCompletion inline function get_length():Int
		return members.length;

	public var maxSize(get, set):Int;
	@:noCompletion inline function get_maxSize():Int return group.maxSize;
	@:noCompletion inline function set_maxSize(value:Int):Int return group.maxSize = value;

	public function new(?parent:Dynamic, maxSize:Int = 0) {
		group = new FlxTypedGroup<Script>(maxSize);
		members = group.members; // it's a class so... bleh
		group.memberAdded.add(script -> script.parent = this.parent);
		group.memberRemoved.add(script -> script.parent = null);
		this.parent = parent;
		super(null);
	}

	// script related functions
	@:noCompletion override function setup():Void {}
	/**
	 * Once ran the groups members initialize and are able to do things!
	 */
	override function load():Void {
		if (initialized) return;
		initialized = true;
		forEach(script -> script.load());
	}

	/**
	 * Sets a variable throughout the group.
	 * @param variable The variable name.
	 * @param value The new value.
	 */
	override function set(variable:String, value:Any):Void
		if (!terminated) forEach(script -> script.set(variable, value));
	/**
	 * Gets a variable within the group.
	 * @param variable The variable name.
	 * @param def If the variable is null, it returns this.
	 * @return The variables value.
	 */
	override function get<V>(variable:String, ?def:V):Null<V> {
		if (terminated) return def;
		var lol:ScriptRetCall<V> = def;
		var value:V = null;
		forEach(script -> value = lol.call(value, script, script.get(variable)));
		return value;
	}

	/**
	 * Calls a function throughout the group.
	 * @param callback The function name.
	 * @param arguments The function arguments.
	 * @param def If the function return is null, it returns this.
	 * @return The functions return value.
	 */
	override function call<R>(callback:String, ?arguments:Array<Any>, ?def:ScriptRetCall<R>):Null<R> {
		if (terminated || !initialized)
			return def.call(this);
		var value:R = null;
		forEach(script -> value = def.call(value, script, script.call(callback, arguments)));
		return value;
	}
	/**
	 * Runs an event call throughout the group.
	 * @param callback The function name.
	 * @param event The event to call.
	 * @param parentOverride What the parent should temporally be when called.
	 * @return The event that was called.
	 */
	override function event<E:CallableEvent>(callback:String, event:E, ?parentOverride:Any):E {
		if (terminated || !initialized) return event;
		onEventCall.dispatch(callback, event, parentOverride ?? parent);
		forEach(script -> {
			if (event.cancelled && event.breakLoop) return;
			script.event(callback, event, parentOverride);
		});
		return event;
	}

	@:unreflective @:noCompletion override function _call(callback:String, arguments:Array<Any>):Any {
		throw 'Why tf are you calling this? ScriptGroup doesn\'t need it!';
	}

	@:noCompletion override function terminate():Void
		forEach(instance -> instance.getScript(script -> script.terminate()));

	// group related functions
	inline public function add(script:ScriptInstance):ScriptInstance
		return group.add(cast script);
	inline public function insert(position:Int, script:ScriptInstance):ScriptInstance
		return group.insert(position, cast script);
	inline public function remove(script:ScriptInstance):ScriptInstance
		return group.remove(cast script, true);

	@:noCompletion inline public function iterator() {
		members.sort((a, b) -> return FlxSort.byValues(FlxSort.DESCENDING, a.priorityIndex, b.priorityIndex));
		return members.iterator();
	}
	@:noCompletion inline public function keyValueIterator() {
		members.sort((a, b) -> return FlxSort.byValues(FlxSort.DESCENDING, a.priorityIndex, b.priorityIndex));
		return members.keyValueIterator();
	}

	/**
	 * For loops through all scripts within the group.
	 * @param func The function to run on each loop.
	 * @param recurse If true, if a script group gets called upon, then it will run it's "forEach" function.
	 */
	public function forEach(func:ScriptInstance -> Void, recurse:Bool = true):Void {
		for (instance in this) {
			if (instance == null) continue; // jic
			// siphons out dead scripts
			if ((instance.type.isLang && instance.terminated) || instance.type == TypeUnknown) {
				instance.destroy();
				remove(instance);
				continue;
			}
			if (recurse && instance.isGroup)
				instance.getGroup(group -> group.forEach(func));
			else func(instance);
		}
	}
	/**
	 * Same as "forEach" but you can specify the coding language!
	 * @param type The script type.
	 * @param func The function to run on each loop.
	 * @param recurse If true, if a script group gets called upon, then it will run it's "forEach" function.
	 */
	inline public function forEachOfType(type:ScriptType, func:ScriptInstance -> Void, recurse:Bool = true):Void {
		if (!type.isLang) throw 'Invalid type detected. (type: "$type")';
		function typeFunc(instance:ScriptInstance):Void {
			if (recurse && instance.isGroup)
				typeFunc(instance);
			else if (instance.type == type)
				func(instance);
		}
		forEach(typeFunc, recurse);
	}

	override function destroy():Void {
		onEventCall.destroy();
		terminate(); super.terminate();
		super.destroy();
	}
}