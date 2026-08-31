package imaginative.sprites;

import flixel.group.FlxSpriteGroup;

class MenuSprite extends FlxSpriteGroup {
	/**
	 * Menu art line art colors.
	 */
	public static final lineArtColors:Map<FlxColor, FlxColor> = [
		FlxColor.YELLOW => 0xFFDD7928,
		FlxColor.BLUE => 0xFF2847DD,
		FlxColor.MAGENTA => 0xFFDD28A7,
		FlxColor.GRAY => 0xFF8E8E8E
	];
	/**
	 * Background art colors.
	 */
	public static final blankBgColors:Map<FlxColor, FlxColor> = [
		FlxColor.YELLOW => 0xFFFDE871,
		FlxColor.BLUE => 0xFF9271FD,
		FlxColor.MAGENTA => 0xFFFD719B,
		FlxColor.GRAY => 0xFFE1E1E1
	];

	/**
	 * Background of the sprite.
	 */
	public var blankBg:BaseSprite;
	/**
	 * Line art of the sprite.
	 */
	public var lineArt:BaseSprite;

	/**
	 * @param x The x position.
	 * @param y The y position.
	 * @param color FlxColor input.
	 * @param funkinColor If true, when using FlxColor "YELLOW", "BLUE", "MAGENTA" or "GRAY", it will use the menuBG color instead.
	 * @param imagePathType The mod path type.
	 */
	public function new(x:Float = 0, y:Float = 0, color:FlxColor = FlxColor.YELLOW, funkinColor:Bool = true, imagePathType:ModType = ALL) {
		super(x, y);

		lineArt = new BaseSprite().loadImage('$imagePathType:menus/bgs/menuArt');
		blankBg = cast new BaseSprite().makeGraphic(Math.floor(lineArt.width), Math.floor(lineArt.height));

		changeColor(color, funkinColor);

		add(blankBg);
		add(lineArt);
	}

	/**
	 * Changes the color of the sprite.
	 * @param color The new color.
	 * @param funkinColor If true, depending on the inputted color, it will look like the original funkin bg bg colors.
	 * @return FlxColor
	 */
	public function changeColor(color:FlxColor = FlxColor.YELLOW, funkinColor:Bool = true):FlxColor {
		lineArt.color = (funkinColor && lineArtColors.exists(color)) ? lineArtColors.get(color) : color - 0xFF646464;
		return blankBg.color = (funkinColor && blankBgColors.exists(color)) ? blankBgColors.get(color) : color;
	}

	/**
	 * Scales the sprite.
	 * @param x New x scale.
	 * @param y New y scale.
	 * @param updateHitbox If true, it updates the hitbox.
	 */
	public function updateScale(x:Float = 1, ?y:Float, updateHitbox:Bool = true):Void {
		for (obj in [blankBg, lineArt]) {
			obj.scale.set(x, y ?? x);
			if (updateHitbox) obj.updateHitbox();
		}
	}
	/**
	 * Scales the graphic size.
	 * @param width New width size.
	 * @param height New height size.
	 * @param updateHitbox If true, it updates the hitbox.
	 */
	public function updateSize(width:Int = 0, height:Int = 0, updateHitbox:Bool = true):Void {
		for (obj in [blankBg, lineArt]) {
			obj.setGraphicSize(width, height);
			if (updateHitbox) obj.updateHitbox();
		}
	}
	/**
	 * Scales the graphic size, but makes sure its unstretched.
	 * @param width New width size.
	 * @param height New height size.
	 * @param fill Whenever the sprite should fill instead of shrinking (true).
	 * @param maxScale Maximum scale (0 / none).
	 * @param updateHitbox If true, it updates the hitbox.
	 */
	public function updateSizeBounded(width:Int = 0, height:Int = 0, fill:Bool = true, maxScale:Float = 0, updateHitbox:Bool = true):Void {
		for (obj in [blankBg, lineArt]) {
			obj.setGraphicScale(width, height, fill, maxScale);
			if (updateHitbox) obj.updateHitbox();
		}
	}
}