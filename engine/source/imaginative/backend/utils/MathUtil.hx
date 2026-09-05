package imaginative.backend.utils;

import flixel.math.FlxMath;

class MathUtil {
	/**
	 * Returns the linear interpolation of two numbers if ratio is between 0 and 1, and the linear extrapolation otherwise.
	 * @param a Number "A".
	 * @param b Number "B".
	 * @param ratio The amount of interpolation.
	 * @param delta The current delta, for doing accurate visuals on different framerates.
	 * @return The result.
	 */
	@:noUsing inline public static function lerp(a:Float, b:Float, ratio:Float, ?delta:Float):Float {
		return FlxMath.lerp(a, b, delta == null || Math.isNaN(delta) ? ratio : FlxMath.getElapsedLerp(ratio, delta));
	}
	/**
	 * Returns the linear interpolation of two colors if ratio is between 0 and 1, and the linear extrapolation otherwise.
	 * @param a Color "A".
	 * @param b Color "B".
	 * @param ratio The amount of interpolation.
	 * @param delta The current delta, for doing accurate visuals on different framerates.
	 * @return The result.
	 */
	@:noUsing inline public static function lerpColor(a:FlxColor, b:FlxColor, ratio:Float, effectAlpha:Bool = false, ?delta:Float):FlxColor {
		return FlxColor.fromRGBFloat(
			lerp(a.redFloat, b.redFloat, ratio, delta),
			lerp(a.greenFloat, b.greenFloat, ratio, delta),
			lerp(a.blueFloat, b.blueFloat, ratio, delta),
			effectAlpha ? lerp(a.alphaFloat, b.alphaFloat, ratio, delta) : a.alphaFloat
		);
	}
}