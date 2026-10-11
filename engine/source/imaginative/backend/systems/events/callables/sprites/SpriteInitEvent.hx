package imaginative.backend.systems.events.callables.sprites;

class SpriteInitEvent extends CallableEvent {
	/**
	 * The asset this sprite should load.
	 */
	@:hidden public var spriteAsset:ModPath = '';

	/**
	 * The paths for the scripts that will be loaded for this sprite.
	 */
	@:hidden public var scriptPaths:Array<ModPath> = ArrayUtil.recycle();
	/**
	 * The root path for scripts.
	 *
	 * __NOTE:__ You *must* apply this **manually** to your script paths.
	 */
	public var _rootPath:String;

	#if Animate_Atlas
	/**
	 * The animate atlas settings.
	 */
	@:hidden public var atlasSettings:animate.FlxAnimateFrames.FlxAnimateSettings = null;
	#end

	override function _recycle():Void {
		super._recycle();
		scriptPaths.put();
	}

	override function toString():String {
		var _format = Paths.image(spriteAsset).format();
		static var _text = ''; _text = 'spriteAsset: "${_format == 'images.png' ? '' : _format.ifBlankReplace('')}", scriptPaths: ${scriptPaths.toStringAdvanced(true)}, _rootPath: "${_rootPath.ifBlankReplace('')}"';
		#if Animate_Atlas _text += ', atlasSettings: ${atlasSettings == null ? 'null' : atlasSettings.toStringAdvanced(true)}'; #end
		return 'SpriteInitEvent($_text)';
	}
}