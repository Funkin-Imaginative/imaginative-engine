package imaginative.backend.scripting.types;

#if Scripting.Haxe
import hxscript.Config as HxConfig;
import hxscript.Environment;

private class HxScript extends hxscript.Script {
	public function new(string:String, name:String = 'hscript', ?environment:Environment) {
		super(string, name, environment);
		interp.parent = null;
	}
	override function call(variable:String, ?args:Array<Dynamic>):Any {
		if (interp == null) throw 'Interpreter is uninitialized';

		var func = null;
		try { func = variables.get(variable) ?? interp.getLocal(variable); }
		catch(error:haxe.Exception) return null; // _log('[HxScript] ${error.message}', ErrorMessage);

		if (!Reflect.isFunction(func)) return null;
		try {
			args ??= ArrayUtil.recycle();
			var result = Reflect.callMethod(interp, func, args);
			args.put();
			return result;
		} catch(error:haxe.Exception) log(error.message, ErrorMessage, FromHaxe, interp.posInfos());
		return null;
	}

	extern inline function addImport(cls:Class<Any>, ?as:String):Void
		interp.imports.set(as ?? cls.getClassName(false), cls);
	extern inline function addUsing(cls:Class<Any>):Void {
		if (!interp.usings.contains(cls))
			interp.usings.push(cls);
		addImport(cls);
	}
	override function setDefaults():Void {
		interp.setDefaults();
		// parser.preprocessorValues.set();

		variables.set('_script_', this);

		addUsing(Lambda);
		addUsing(ArrayUtil);
		addUsing(MathUtil);
		addUsing(StringUtil);

		addImport(FilePath, 'FilePath');
		addImport(FlxG);
		addImport(FlxEase);
		addImport(FlxTween);
		addImport(FlxTimer);
		addImport(Controls);
		addImport(Assets);
		addImport(Conductor);
		#if Modding addImport(Modding); #end
		addImport(Paths);
		addImport(PlatformUtil);
		addImport(BaseSprite);
		addImport(BeatSprite);
	}
}
private class ImagInterp extends hxscript.runtime.Interp {
	override function set_parent(value:Dynamic):Dynamic {
		if (variables != null) variables.set('this', parent = value);
		return super.set_parent(value);
	}
	override function setDefaults(wipe:Bool = true, includeConfig:Bool = true):Void @:privateAccess {
		super.setDefaults(wipe, includeConfig);
		variables.set('trace', Reflect.makeVarArgs(vars -> log(vars.toStringAdvanced(false), FromHaxe, posInfos())));
		variables.set('log', (value:Dynamic, level:LogLevel = LogMessage) -> log(value, level, FromHaxe, posInfos()));
		variables.set('_log', (value:Dynamic, level:LogLevel = DebugMessage) -> _log(value, level, FromHaxe));
	}
}

/**
 * The haxe language script class.
 */
@:allow(imaginative.backend.scripting.Script)
class HaxeScript extends Script {
	extern inline static function init():Void {
		_log('Initializing Haxe Scripting');
		HxConfig.strictAccess = true;
		HxConfig.interpClass = ImagInterp;
		HxConfig.blacklist.get(ByPackage(true)).push('hxp');
		HxConfig.blacklist.get(ByPackage(true)).push('hxhardware');
	}

	/**
	* All extension types that say that file is a script that runs on the haxe language.
	*/
	public static final exts:Array<String> = ['haxe', 'hx'];
	@:noCompletion override function get_type():ScriptType return TypeHaxe;

	@:noCompletion override function get_parent():Dynamic return internal_script.interp.parent;
	@:noCompletion override function set_parent(value:Dynamic):Dynamic return internal_script.interp.parent = value;

	var internal_script:HxScript;
	override function setup():Void {
		internal_script = new HxScript(Assets.text(filePath.toString()), filePath.format(), new Environment());
		internal_script.onParsingError = error -> _log('[HaxeScript] An error occurred trying to parse this script. (path: "${internal_script.name}", error: "${error.message}")', ErrorMessage);
		internal_script.onProgramError = error -> _log('[HaxeScript] An error occurred trying to start the program. (path: "${internal_script.name}", error: "${error.message}")', ErrorMessage);
		super.setup();
	}

	override function load():Void {
		if (initialized) return;
		internal_script.start();
		initialized = true;
		super.load();
	}

	override function set(variable:String, value:Any):Void {
		if (terminated || internal_script.variables == null) return;
		internal_script.variables.set(variable, value);
	}
	override function get<V>(variable:String, ?def:V):Null<V> {
		if (terminated || internal_script.variables == null) return def;
		return internal_script.variables.get(variable) ?? def;
	}

	@:noCompletion override function _call(callback:String, arguments:Array<Any>):Any
		return internal_script.call(callback, arguments);

	override function destroy():Void {
		super.destroy();
	}
}
#end