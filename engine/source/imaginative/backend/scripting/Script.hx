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
class Script extends flixel.FlxBasic {
	extern inline static function _init():Void {
		trace('Initializing Scripting');
		#if Scripting.Haxe HaxeScript._init(); #end
		#if Scripting.Lua LuaScript._init(); #end
	}

	public static final exts:imaginative.backend.data.StringedArray = #if Scripting.Haxe HaxeScript.exts + #end #if Scripting.Lua LuaScript.exts + #end '';

	public var priorityIndex:Int = 1000;

	/**
	 * States the type of script this is.
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
	 * Creates a script from a file.
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
		return new Script(Paths.script(path, type));
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
		final script:Script = switch (language) {
			#if Scripting.Haxe case TypeHaxe: new HaxeScript(null, code); #end
			#if Scripting.Lua case TypeLua: new LuaScript(null, code); #end
			default: new Script(null, code);
		}
		onCreate(script);
		script.init();
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
	function setup():Void {}

	public var initialized(default, null):Bool = false;
	public function init():Void {}

	public function set(variable:String, value:Any):Void {}
	public function get<V>(variable:String, ?def:V):Null<V> return def;

	public function call<R>(callback:String, ?arguments:Array<Any>, ?def:ScriptRetCall<R>):Null<R> {
		if (terminated || !initialized) return def.call(this);
		return def.call(this, _call(callback, arguments));
	}
	public function event<E>(callback:String, event:E, ?parentOverride:Any):E {
		if (terminated || !initialized) return event;
		final oldParent:Any = parent;
		parent = parentOverride ?? oldParent;
		call(callback, [event]);
		parent = oldParent;
		return event;
	}

	@:noCompletion function _call(callback:String, arguments:Array<Any>):Any {
		throw 'You gotta override "_call"!';
	}

	public var terminated(default, null):Bool = false;
	public function terminate():Void terminated = true;

	override function destroy():Void {
		call('onEnd');
		terminate();
		super.destroy();
	}

	#if FLX_DEBUG
	// just so scripts don't contribute to "activeCount" and "visibleCount"
	override function update(elapsed:Float):Void {}
	override function draw():Void {}
	#end
}