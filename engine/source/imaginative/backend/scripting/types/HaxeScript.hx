package imaginative.backend.scripting.types;

#if Scripting.Haxe
import hxscript.Environment;

private class HxScript extends hxscript.Script {
	var _parent:HaxeScript;
	public function new(parent:HaxeScript, string:String, name:String = 'hscript', ?environment:Environment) {
		_parent = parent;
		super(string, name, environment);
	}
	override function call(variable:String, ?args:Array<Dynamic>):Any {
		if (interp == null) throw 'Interpreter is uninitialized';
		var fun = (variables.get(variable) ?? interp.getLocal(variable));
		if (!Reflect.isFunction(fun)) return null;
		return Reflect.callMethod(interp, fun, args ?? []);
	}
	override function setDefaults():Void {
		interp.setDefaults();
		@:privateAccess _parent.setDefaults();
	}
}

class HaxeScript extends Script {
	extern inline static function _init():Void {
		trace('Initializing Haxe Scripting');
		hxscript.Config.strictAccess = true;
	}

	public static final exts:Array<String> = ['hx'];

	@:noCompletion override function get_type():ScriptType
		return TypeHaxe;

	@:noCompletion override function get_parent():Dynamic
		return internal_script.interp.parent;
	@:noCompletion override function set_parent(value:Dynamic):Dynamic {
		set('this', value);
		return internal_script.interp.parent = value;
	}

	@:allow(imaginative.backend.scripting.Script)
	function new(filePath:ModPath, ?rawCode:String) {
		super(filePath, rawCode);
	}

	var internal_script:HxScript;
	override function setup():Void {
		internal_script = new HxScript(this, Assets.text(filePath.toString()), filePath.format(), new Environment());
		internal_script.onParsingError = error -> trace(error);
		internal_script.onProgramError = error -> trace(error);
	}

	extern inline function addImport(cls:Class<Any>, ?as:String):Void
		internal_script.interp.imports.set(as ?? flixel.util.FlxStringUtil.getClassName(cls, true), cls);
	extern inline function addUsing(cls:Class<Any>):Void
		if (!internal_script.interp.usings.contains(cls))
			internal_script.interp.usings.push(cls);
	extern inline function setDefaults():Void {
		set('_script_', this);
		addUsing(Lambda);
		addUsing(ArrayUtil);
		addUsing(MathUtil);
		addUsing(StringUtil);
	}

	override function init():Void {
		if (initialized) return;
		internal_script.start();
		initialized = true;
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