package imaginative.backend.scripting.types;

#if Scripting.Haxe
import hxscript.Environment;

private class HxScript extends hxscript.Script {
	override function setDefaults():Void {
		super.setDefaults();
	}
}

class HaxeScript extends Script {
	extern inline static function _init():Void {}

	var internal_script:HxScript;

	public function new(filePath:ModPath, ?rawCode:String) {
		super(filePath, rawCode);
	}

	override function setup():Void {
		internal_script = new HxScript(Assets.text(filePath.toString()), filePath.format(), new Environment());
		internal_script.onParsingError = error -> trace(error);
		internal_script.onProgramError = error -> trace(error);
	}

	override function init():Void {
		if (initialized) return;
		internal_script.start();
		initialized = true;
	}

	override function set(variable:String, value:Any):Void {
		if (terminated || !initialized) return;
		internal_script.variables.set(variable, value);
	}
	override function get<V>(variable:String, ?def:V):Null<V> {
		if (terminated || !initialized) return def;
		return internal_script.variables.get(variable) ?? def;
	}

	@:noCompletion override function _call(callback:String, arguments:Array<Any>):Any
		return internal_script.call(callback, arguments);

	override function destroy():Void {
		super.destroy();
	}
}
#end