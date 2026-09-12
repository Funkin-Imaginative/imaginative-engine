package imaginative.backend.scripting.types;

#if Scripting.Haxe
import hxscript.Config as HxConfig;
import hxscript.Environment;

private class HxScript extends hxscript.Script {
	var _parent:HaxeScript;
	public function new(parent:HaxeScript, string:String, name:String = 'hscript', ?environment:Environment) {
		_parent = parent;
		super(string, name, environment);
		interp.parent = null;
	}
	override function call(variable:String, ?args:Array<Dynamic>):Any {
		if (interp == null) throw 'Interpreter is uninitialized';
		var fun = (variables.get(variable) ?? interp.getLocal(variable));
		if (!Reflect.isFunction(fun)) return null;
		return Reflect.callMethod(interp, fun, args ?? []);
	}

	extern inline function addImport(cls:Class<Any>, ?as:String):Void
		interp.imports.set(as ?? flixel.util.FlxStringUtil.getClassName(cls, true), cls);
	extern inline function addUsing(cls:Class<Any>):Void
		if (!interp.usings.contains(cls))
			interp.usings.push(cls);
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
}

/**
 * The haxe language script class.
 */
@:allow(imaginative.backend.scripting.Script)
class HaxeScript extends Script {
	extern inline static function init():Void {
		trace('Initializing Haxe Scripting');
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
		internal_script = new HxScript(this, Assets.text(filePath.toString()), filePath.format(), new Environment());
		internal_script.onParsingError = error -> trace(error);
		internal_script.onProgramError = error -> trace(error);
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