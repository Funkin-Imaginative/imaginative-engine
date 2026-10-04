package imaginative.backend.systems.events.callables.menus;

class MenuBackgroundEvent extends CallableEvent {
	/**
	 * The color the background should be.
	 */
	public var color:FlxColor = FlxColor.YELLOW;
	/**
	 * If true, when inputting the colors "YELLOW", "BLUE", "MAGENTA" or "GRAY", it will use the specific shades used in the original menu art.
	 */
	public var funkinColor:Bool = true;
	/**
	 * The mod path type.
	 */
	public var imagePathType:ModType = ALL;

	override function toString():String
		return 'MenuBackgroundEvent(color: ${color.toWebString()}, funkinColor: $funkinColor, imagePathType: ${imagePathType.toString().toUpperCase()})';
}