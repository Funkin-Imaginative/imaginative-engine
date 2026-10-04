package imaginative.backend.scripting;

#if Scripting.Haxe import imaginative.backend.scripting.types.HaxeScript; #end
#if Scripting.Lua import imaginative.backend.scripting.types.LuaScript; #end

/**
 * Different types a script can be assigned.
 */
enum abstract ScriptType(String) {
	/**
	 * The script is invalid.
	 */
	var TypeUnknown = null;

	#if Scripting.Haxe
	/**
	 * The scripting language is haxe, this is what the engine is built off of!
	 */
	var TypeHaxe = 'haxe';
	#end
	#if Scripting.Lua
	/**
	 * The scripting language is lua, not completely supported, but should work either way.
	 */
	var TypeLua = 'lua';
	#end

	/**
	 * This is a group, *not* a script.
	 */
	var TypeGroup = '_group_';

	/**
	 * States wether the type is a language.
	 */
	public var isLang(get, never):Bool;
	@:noCompletion inline function get_isLang():Bool {
		return !(abstract == TypeUnknown || abstract == TypeGroup);
	}
}

/**
 * The base script class.
 */
class Script extends flixel.FlxBasic { // I would be doing "implements IFlxDestroyable" but being able to add scripts to regular groups is nice :)
	extern inline static function init():Void {
		_log('Initializing Scripting');

		#if Scripting.Haxe
		HaxeScript.init();
		exts.merge(HaxeScript.exts);
		#end

		#if Scripting.Lua
		LuaScript.init();
		exts.merge(LuaScript.exts);
		#end

		GlobalScript.init();
	}

	/**
	 * All extension types that say that file is a script.
	 */
	public static final exts:Array<String> = [];

	/**
	 * The sort index of this script.
	 */
	public var priorityIndex:Int = 1000;

	/**
	 * States what type of script this is.
	 */
	public var type(get, never):ScriptType;
	@:noCompletion function get_type():ScriptType
		return TypeUnknown;

	/**
	 * The target object the script can effect.
	 */
	public var parent(get, set):Dynamic;
	@:noCompletion function get_parent():Dynamic return null;
	@:noCompletion function set_parent(value:Dynamic):Dynamic return null;

	/**
	 * Creates a script from a mod path.
	 * @param path The mod path.
	 * @param type The script type, just in case you wanna be specific about coding language.
	 * @return The script.
	 */
	public static function create(path:ModPath, type:ScriptType = TypeUnknown):Script {
		#if Scripting.Haxe
		if (type == TypeUnknown || type == TypeHaxe)
			return new HaxeScript(Paths.script(path, TypeHaxe));
		#end
		#if Scripting.Lua
		if (type == TypeUnknown || type == TypeLua)
			return new LuaScript(Paths.script(path, TypeLua));
		#end
		if (!Paths.script(path, type).isFile)
			_log('[Script.create] Script file doesn\'t exist. (path: "${Paths.script(path, type).format()}")', DebugMessage);
		return new Script(Paths.script(path, type));
	}
	/**
	 * Creates an array of scripts from a mod path.
	 * @param path The mod path.
	 * @param type The script type, just in case you wanna be specific about coding language.
	 * @param includeAllActiveModules If false, it excludes module mods that isn't the current one.
	 * @return The array of scripts.
	 */
	public static function multiCreate(path:ModPath, type:ScriptType = TypeUnknown, includeAllActiveModules:Bool = false):Array<Script> {
		path.applyExt();
		var results = ArrayUtil.recycle();
		#if Scripting
			#if Modding
			var _exts = switch (type) {
				#if Scripting.Haxe case TypeHaxe: HaxeScript.exts; #end
				#if Scripting.Lua case TypeLua: LuaScript.exts; #end
				default: exts;
			}
			for (ext in _exts)
				for (instance in Modding.getAllInstancesOfFile(path.applyExt(ext)))
					results.push(create(instance.applyExt(), type));
			#else
			results.push(create(path, type));
			#end
		#end
		return results;
	}

	/**
	 * Allows you to create a script instance from raw code.
	 * @param code The code for the script to contain.
	 * @param language The language the script should use.
	 * @param onCreate Called before the script is initialized.
	 * @param onLoad Called after the script is initialized.
	 * @return The script.
	 */
	public static function createFromString(code:String, language:ScriptType, onCreate:Script -> Void, onLoad:Script -> Void):Script {
		if (!language.isLang) throw 'Invalid type detected. ($language)';
		var script:Script = switch (language) {
			#if Scripting.Haxe case TypeHaxe: new HaxeScript(null, code); #end
			#if Scripting.Lua case TypeLua: new LuaScript(null, code); #end
			default: new Script(null, code);
		}
		onCreate(script);
		script.load();
		onLoad(script);
		return script;
	}

	public final filePath:FileModPath; // TODO: Have this just be a string maybe?
	/**
	 * @param filePath The path to the script file.
	 * @param rawCode The raw code, mainly used for the "createFromString" function.
	 */
	function new(filePath:ModPath, ?rawCode:String) {
		super();
		this.filePath = FileModPath.fromModPath(filePath);
		setup();
	}
	function setup():Void GlobalScript.call('onScriptCreate', [this, type]);

	/**
	 * When true the code can run.
	 */
	public var initialized(default, null):Bool = false;
	/**
	 * Once ran the script initializes and is able to do things!
	 */
	public function load():Void
		if (type.isLang) call('onLoad');

	/**
	 * Sets a variable within the script.
	 * @param variable The variable name.
	 * @param value The new value.
	 */
	public function set(variable:String, value:Any):Void {}
	/**
	 * Gets a variable within the script.
	 * @param variable The variable name.
	 * @param def If the variable is null, it returns this.
	 * @return The variables value.
	 */
	public function get<V>(variable:String, ?def:V):Null<V> return def;

	/**
	 * Calls a function within the script.
	 * @param callback The function name.
	 * @param arguments The function arguments.
	 * @param def If the function return is null, it returns this.
	 * @return The functions return value.
	 */
	public function call<R>(callback:String, ?arguments:Array<Any>, ?def:ScriptRetCall<R>):Null<R> {
		if (terminated || !initialized) return def.call(this);
		return def.call(this, _call(callback, arguments));
	}
	/**
	 * Runs an event call within the script.
	 * @param callback The function name.
	 * @param event The event to call.
	 * @param parentOverride What the parent should temporally be when called.
	 * @return The event that was called.
	 */
	public function event<E:CallableEvent>(callback:String, event:E, ?parentOverride:Any):E {
		if (terminated || !initialized) return event;
		var oldParent:Any = parent;
		parent = parentOverride ?? oldParent;
		call(callback, [event]);
		parent = oldParent;
		return event;
	}

	@:noCompletion function _call(callback:String, arguments:Array<Any>):Any
		throw 'This function needs to overridden.';

	/**
	 * When true the code will no longer run.
	 */
	public var terminated(default, null):Bool = false;
	/**
	 * Once ran the script is killed off and will no longer work.
	 */
	public function terminate():Void terminated = true;

	override function destroy():Void {
		call('onEnd');
		terminate();
		super.destroy();
		GlobalScript.call('onScriptDestroy', [this, type]);
	}

	#if FLX_DEBUG
	// just so scripts don't contribute to "activeCount" and "visibleCount"
	override function update(delta:Float):Void {}
	override function draw():Void {}
	#end
}