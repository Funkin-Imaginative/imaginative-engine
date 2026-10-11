package imaginative.backend.input;

import flixel.input.mouse.FlxMouse;

// TODO: Make this more it's own thing later on.
// @:build(flixel.system.macros.FlxMacroUtil.deprecateOverride('justMoved', 'isMoving is more accurate.'))
class GameMouse extends FlxMouse {
	/**
	 * Check to see if the mouse is moving.
	 */
	public var isMoving(get, never):Bool;
	@:noCompletion inline function get_isMoving():Bool {
		var x:Float = FlxG.stage.application.window.x + FlxG.stage.mouseX;
		var y:Float = FlxG.stage.application.window.y + FlxG.stage.mouseY;
		var moving:Bool = (x != _lastScreenX || y != _lastScreenY);

		_lastScreenX = x;
		_lastScreenY = y;
		return moving;
	}

	var _lastScreenX:Float = 0;
	var _lastScreenY:Float = 0;
}