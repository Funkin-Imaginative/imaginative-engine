package imaginative.backend.macro;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using StringTools;
using haxe.macro.ExprTools;

class Macro {
	inline static function init():Void {
		var classPath:String = Std.string(Macro).replace('Class<', '').replace('>', '');
		Compiler.addMetadata('@:build($classPath.buildOntoFlxG())', 'flixel.FlxG');

		Compiler.addMetadata('@:build($classPath.buildOntoFlxBasic())', 'flixel.FlxBasic');
		Compiler.addMetadata('@:build($classPath.buildOntoFlxObject())', 'flixel.FlxObject');
		Compiler.addMetadata('@:build($classPath.buildOntoFlxSprite())', 'flixel.FlxSprite');
		Compiler.addMetadata('@:build($classPath.buildOntoFlxSpriteGroup())', 'flixel.group.FlxTypedSpriteGroup');

		Compiler.addMetadata('@:build($classPath.buildOntoFlxAnimation())', 'flixel.animation.FlxAnimation');
		Compiler.addMetadata('@:build($classPath.buildOntoFlxAnimationController())', 'flixel.animation.FlxAnimationController');

		Compiler.include('moonchart', true, ['moonchart.backend.*']); // force include no matter what
	}

	inline static macro function buildOntoFlxG():Array<Field> {
		var classFields = Context.getBuildFields();
		var tempClass = macro class TempClass {
			/**
			 * Represents the amount of time in seconds that passed since last frame.
			 */
			public static var delta(get, never):Float;
			inline static function get_delta():Float return elapsed;

			/**
			 * Useful when the timestep is NOT fixed (i.e. variable),
			 * to prevent jerky movement or erratic behavior at very low fps.
			 * Essentially locks the framerate to a minimum value - any slower and you'll get
			 * slowdown instead of frameskip; default is 1/10th of a second.
			 */
			public static var maxDelta(get, never):Float;
			inline static function get_maxDelta():Float return maxElapsed;
		}
		return classFields.concat(tempClass.fields);
	}

	inline static macro function buildOntoFlxBasic():Array<Field> {
		var classFields = Context.getBuildFields();
		var tempClass = macro class TempClass {
			/**
			 * Extra data that can be stored.
			 */
			public var extra(default, null):Map<String, Dynamic> = new Map<String, Dynamic>();
		}

		var onDestroyFunc = classFields.find(field -> field.name == 'new');
		switch (onDestroyFunc.kind) {
			case FFun(f):
				var initExpr:Expr = f.expr;
				f.expr = macro {
					extra.clear();
					extra = null;
					$initExpr;
				}
				onDestroyFunc.kind = FFun(f);
			default:
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

		var onScreenFunc = classFields.find(field -> field.name == 'isOnScreen');
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

		var newScreenCenterFunc = tempClass.fields.find(field -> field.name == 'screenCenter');
		tempClass.fields.remove(newScreenCenterFunc);
		var screenCenterFunc = classFields.find(field -> field.name == 'screenCenter');
		screenCenterFunc.name = newScreenCenterFunc.name;
		screenCenterFunc.doc = newScreenCenterFunc.doc;
		screenCenterFunc.access = newScreenCenterFunc.access;
		screenCenterFunc.kind = newScreenCenterFunc.kind;
		screenCenterFunc.meta = newScreenCenterFunc.meta;

		return classFields.concat(tempClass.fields);
	}
	inline static macro function buildOntoFlxSprite():Array<Field> {
		var classFields = Context.getBuildFields();
		var tempClass = macro class TempClass {
			/**
			 * Helper function to set the graphic's dimensions by using `scale`, but unlike setGraphicSize, the sprites original aspect ratio is kept! It might make sense to call `updateHitbox()` afterwards!
			 *
			 * @param   width    How wide the graphic should be.
			 * @param   height   How high the graphic should be.
			 * @param   fill     Wether it should fill to bounds.
			 * @param   maxScale The max possible scale.
			 */
			public function setGraphicScale(width:Float = 0, height:Float = 0, fill:Bool = true, maxScale:Float = 0):Void {
				var prevWidth = this.width; var prevHeight = this.height;
				setGraphicSize(width, height);
				updateHitbox();
				var nScale = (fill ? Math.max : Math.min)(scale.x, scale.y);
				if (maxScale > 0 && nScale > maxScale) nScale = maxScale;
				setSize(prevWidth, prevHeight);
				scale.set(nScale, nScale);
			}
		}

		// I hate that I hate to do this twice.
		var onScreenFunc = classFields.find(field -> field.name == 'isOnScreen');
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

		return classFields.concat(tempClass.fields);
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

	inline static macro function buildOntoFlxAnimation():Array<Field> {
		var classFields = Context.getBuildFields();
		var tempClass = macro class TempClass {
			/**
			 * The position offset for the animation.
			 */
			public var offset(default, null):flixel.math.FlxPoint;

			/**
			 * Extra data that can be stored.
			 */
			public var extra(default, null):Map<String, Dynamic> = new Map<String, Dynamic>();
		}

		var newConstructor = classFields.find(field -> field.name == 'new');
		switch (newConstructor.kind) {
			case FFun(f):
				var initExpr:Expr = f.expr;
				f.expr = macro {
					$initExpr;
					offset = new flixel.math.FlxPoint();
				}
				newConstructor.kind = FFun(f);
			default:
		}
		var onDestroyFunc = classFields.find(field -> field.name == 'new');
		switch (onDestroyFunc.kind) {
			case FFun(f):
				var initExpr:Expr = f.expr;
				f.expr = macro {
					extra.clear();
					extra = null;
					$initExpr;
					offset.put();
				}
				onDestroyFunc.kind = FFun(f);
			default:
		}

		return classFields.concat(tempClass.fields);
	}
	inline static macro function buildOntoFlxAnimationController():Array<Field> {
		var classFields = Context.getBuildFields();
		var tempClass = macro class TempClass {

			/**
			 * The position offset for the animation.
			 */
			public var offset(get, never):flixel.math.FlxPoint;
			@:noCompletion inline function get_offset() return curAnim != null ? curAnim.offset : _offset;
			@:noCompletion var _offset = new flixel.math.FlxPoint();

			/**
			 * Extra data that can be stored.
			 */
			public var extra(default, null):Map<String, Dynamic> = new Map<String, Dynamic>();
		}

		var onDestroyFunc = classFields.find(field -> field.name == 'new');
		switch (onDestroyFunc.kind) {
			case FFun(f):
				var initExpr:Expr = f.expr;
				f.expr = macro {
					extra.clear();
					extra = null;
					$initExpr;
					_offset.put();
				}
				onDestroyFunc.kind = FFun(f);
			default:
		}

		return classFields.concat(tempClass.fields);
	}
}