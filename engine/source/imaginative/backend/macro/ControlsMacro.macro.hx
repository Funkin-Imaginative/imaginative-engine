package imaginative.backend.macro;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using StringTools;
using haxe.macro.ExprTools;
using haxe.macro.Tools;

class ControlsMacro {
	inline static macro function build():Array<Field> {
		var classFields = Context.getBuildFields();
		var binds = new Map<String, String>();

		// stole from "flixel.system.macros.FlxMacroUtil.buildMap"
		var type = Context.getType('imaginative.backend.input.Binds');
		switch (type.follow()) {
			case TAbstract(_.get() => ab, _):
				for (f in ab.impl.get().statics.get())
					switch (f.kind) {
						case FVar(AccInline, _):
							var value = null;
							switch (f.expr().expr) {
								case TCast(Context.getTypedExpr(_) => expr, _):
									value = expr.getValue();
								default:
							}
							if (f.name.toUpperCase() == f.name)
								binds.set(f.name, value);
						default:
					}
			default:
		}

		for (key => value in binds) {
			var rename:String = value;
			var dir = '';
			if (value.startsWith('ui_')) {
				rename = value.substr(3);
				rename = rename.charAt(0).toUpperCase() + rename.substr(1);
				dir = rename.toLowerCase();
			} else {
				rename = '';
				for (i => v in value.split('_')) {
					if (i == 0) {
						rename += v;
						continue;
					}
					rename += v.charAt(0).toUpperCase() + v.substr(1);
				}
			}

			var suffixes = value.startsWith('ui_') ? ['', 'Press', 'Released'] : [''];
			for (suffix in suffixes) {
				var name = (value.startsWith('ui_') ? 'ui' : '') + rename + suffix;
				var getName = 'get_$name';
				var funcName = switch (suffix) {
					default: 'pressed';
					case 'Press': 'held';
					case 'Released': 'released';
				}
				var funcExpr = [funcName].toFieldExpr(Context.currentPos());
				// Context.info('function $getName() return $funcName("$value")', Context.currentPos());
				var tempClass = macro class TempClass {
					@:isVar public var $name(get, never):Bool;
					inline function $getName():Bool
						return $funcExpr($v{value});
				}

				for (field in tempClass.fields)
					if (field.name == name) {
						if (name.startsWith('ui'))
							field.doc = 'When you press $dir to move through ui elements.';
						else field.doc = 'When "$name" is pressed.';
					}

				classFields = classFields.concat(tempClass.fields);
			}
		}

		return classFields;
	}
}