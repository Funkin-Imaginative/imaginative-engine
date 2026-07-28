package imaginative.backend.macro;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;
using haxe.macro.ExprTools;

class Macro {
	inline static function init():Void {
		var classPath:String = Std.string(Macro).replace('Class<', '').replace('>', '');
		Compiler.addMetadata('@:build($classPath.buildOntoFlxBasic())', 'flixel.FlxBasic');
		Compiler.addMetadata('@:build($classPath.buildOntoFlxObject())', 'flixel.FlxObject');
		Compiler.addMetadata('@:build($classPath.buildOntoFlxSprite())', 'flixel.FlxSprite');
		Compiler.addMetadata('@:build($classPath.buildOntoFlxSpriteGroup())', 'flixel.group.FlxTypedSpriteGroup');
		Compiler.include('moonchart', true, ['moonchart.backend.*']); // force include no matter what
	}

	inline static macro function buildOntoFlxBasic():Array<Field> {
		var classFields = Context.getBuildFields();
		var tempClass = macro class TempClass {
			/**
			 * Extra data that can be stored.
			 */
			public final extra:Map<String, Dynamic> = new Map<String, Dynamic>();
		}
		return classFields.concat(tempClass.fields);
	}
	inline static macro function buildOntoFlxObject():Array<Field> {
		var classFields = Context.getBuildFields();
		var tempClass = macro class TempClass {
			/**
			 * If true, the object will always be considered to be on screen.
			 */
			public var forceIsOnScreen:Bool = false;

			/**
			 * Centers this `FlxObject` on the screen, either by the x axis, y axis, or both.
			 *
			 * @param   axes   On what axes to center the object (e.g. `X`, `Y`, `XY`) - default is both.
			 * @param  camera  The camera to use for centering. If `null`, the default camera is used.
			 * @return  This FlxObject for chaining
			 */
			public function screenCenter(axes:FlxAxes = XY, ?camera:FlxCamera):FlxObject {
				camera ??= getDefaultCamera();
				if (axes.x) x = (camera.width - width) / 2 - (camera.scroll.x * -scrollFactor.x);
				if (axes.y) y = (camera.height - height) / 2 - (camera.scroll.y * -scrollFactor.y);
				return this;
			}
		}

		var onScreenFunc = classFields.filter(field -> return field.name == 'isOnScreen')[0];
		switch (onScreenFunc.kind) {
			case FFun(f):
				var initExpr:Expr = f.expr;
				f.expr = macro {
					if (forceIsOnScreen)
						return true;
					$initExpr;
				}
				onScreenFunc.kind = FFun(f);
			default:
		}

		var newScreenCenterFunc = tempClass.fields.filter(field -> return field.name == 'screenCenter')[0];
		tempClass.fields.remove(newScreenCenterFunc);
		var screenCenterFunc = classFields.filter(field -> return field.name == 'screenCenter')[0];
		screenCenterFunc.name = newScreenCenterFunc.name;
		screenCenterFunc.doc = newScreenCenterFunc.doc;
		screenCenterFunc.access = newScreenCenterFunc.access;
		screenCenterFunc.kind = newScreenCenterFunc.kind;
		screenCenterFunc.meta = newScreenCenterFunc.meta;

		return classFields.concat(tempClass.fields);
	}
	inline static macro function buildOntoFlxSprite():Array<Field> {
		var classFields = Context.getBuildFields();

		// I hate that I hate to do this twice.
		var onScreenFunc = classFields.filter(field -> return field.name == 'isOnScreen')[0];
		switch (onScreenFunc.kind) {
			case FFun(f):
				var initExpr:Expr = f.expr;
				f.expr = macro {
					if (forceIsOnScreen)
						return true;
					$initExpr;
				}
				onScreenFunc.kind = FFun(f);
			default:
		}

		return classFields;
	}

	inline static macro function buildOntoFlxSpriteGroup():Array<Field> {
		var classFields = Context.getBuildFields();
		var tempClass = macro class TempClass {
			/**
			 * Iterates through every member and index.
			 */
			public inline function keyValueIterator() {
				return members.keyValueIterator();
			}
		}
		return classFields.concat(tempClass.fields);
	}
}
#end