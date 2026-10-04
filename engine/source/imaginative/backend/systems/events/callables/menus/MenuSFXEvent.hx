package imaginative.backend.systems.events.callables.menus;

class MenuSFXEvent extends CallableEvent {
	/**
	 * If true the menu sound effect will play.
	 */
	@:hidden public var playSFX:Bool = true;
	/**
	 * The volume of the sound effect.
	 */
	@:hidden public var sfxVolume:Float = 0.7;

	// gets extended, so I gotta do this 💀
	override function _recycle():Void {
		super._recycle();
		playSFX = true;
		sfxVolume = 0.7;
	}

	override function toString():String
		return 'MenuSFXEvent(playSFX: $playSFX, sfxVolume: $sfxVolume)';
}