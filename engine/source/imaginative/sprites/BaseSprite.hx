package imaginative.sprites;

import flixel.math.FlxPoint;
import imaginative.backend.data.TextureType;

/**
 * Tells you what a sprites current animation is supposed to mean.
 *
 * Idea from Codename Engine.
 */
enum abstract AnimationContext(String) from String to String {
	/**
	 * States that the sprite animation is related to dancing.
	 */
	var IsDancing;

	/**
	 * States that the sprite animation is related to singing.
	 */
	var IsSinging;
	/**
	 * States that the sprite animation is related to missing a note.
	 */
	var HasMissed;

	/**
	 * States that the sprite animation can't go back to dancing.
	 */
	var NoDancing;
	/**
	 * States that the sprite animation can't go back to singing.
	 */
	var NoSinging;

	/**
	 * States that the sprite animation is unclear.
	 */
	var Unclear;
}

typedef AnimationMapEntry = {
	var offset:FlxPoint;
	var extra:Map<String, Dynamic>;
}

class BaseSprite extends #if Animate_Atlas animate.FlxAnimate #else flixel.FlxSprite #end {
	/**
	 * If true, a *lot*, of automated shit won't work.
	 */
	public var debugMode:Bool = false;

	/**
	 * The list of mapped animations this sprite has.
	 */
	public var animations:Map<String, AnimationMapEntry> = new Map<String, AnimationMapEntry>();
	/**
	 * The context of the current animation.
	 */
	public var animationContext:AnimationContext = Unclear;

	/**
	 * Loads a graphic texture for the sprite to use.
	 * @param path The mod path.
	 * @param width The image grid width.
	 * @param height The image gird height.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The sprite itself.
	 */
	public function loadImage(path:ModPath, width:Int = 0, height:Int = 0, displayWarning:Bool = false):BaseSprite {
		var _path:ModPath = Paths.image(path);
		if (_path.isFile)
			try {
				loadGraphic(Assets.image(path), !(width < 1 || height < 1), width, height);
			} catch(error:haxe.Exception)
				if (displayWarning) trace('The image failed to load. (path: "${_path.format()}", error: "${error.message}")');
		return this;
	}
	/**
	 * Loads sheet data for the sprite to use.
	 * @param path The mod path.
	 * @param type The wanted texture type.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The sprite itself.
	 */
	public function loadSheet(path:ModPath, type:TextureType = IsUnknown, displayWarning:Bool = false):BaseSprite {
		var _path:ModPath = Paths.image(path);
		var _sheet_path:ModPath = Paths.spritesheet(path);
		var _type:TextureType = type == IsUnknown ? TextureType.getTypeFromExt(_sheet_path, true) : type;
		if (_path.isFile)
			if (_sheet_path.isFile)
				try {
					frames = Assets.frames(path, _type);
				} catch(error:haxe.Exception)
					try {
						if (displayWarning)
							trace('The spritesheet failed to load, using whole image. (path: "${_path.format()}", type: "$_type", error: "${error.message}")');
						loadImage(path, displayWarning);
					} catch(error:haxe.Exception)
						if (displayWarning) trace('The spritesheet failed to load. (path: "${_path.format()}", type: "$_type", error: "${error.message}")');
			else loadImage(path, displayWarning);
		return this;
	}
	#if Animate_Atlas
	/**
	 * Loads an animate atlas for the sprite to use.
	 * @param path The mod path.
	 * @param settings The animate atlas settings.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The sprite itself.
	 */
	public function loadAtlas(path:ModPath, ?settings:animate.FlxAnimateFrames.FlxAnimateSettings, displayWarning:Bool = false):BaseSprite {
		var _atlas_path:ModPath = Paths.spritesheet(path, IsAnimateAtlas);
		if (_atlas_path.isFile) {
			try {
				frames = Assets.frames(path, IsAnimateAtlas, settings);
			} catch(error:haxe.Exception)
				try {
					if (displayWarning)
						trace('The atlas failed to load, using first spritemap image. (path: "${_atlas_path.format()}", type: "$IsAnimateAtlas", error: "${error.message}")');
					loadImage(_atlas_path + 'Animation/spritemap1');
				} catch(error:haxe.Exception)
					if (displayWarning) trace('The atlas failed to load. (path: "${_atlas_path.format()}", type: "$IsAnimateAtlas", error: "${error.message}")');
		}
		return this;
	}
	/**
	 * Loads a sheet, atlas or graphic for the sprite to use based on checks.
	 * @param path The mod path.
	 * @param settings The animate atlas settings.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The sprite itself.
	 */
	#else
	/**
	 * Loads a sheet or graphic for the sprite to use based on checks.
	 * @param path The mod path.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The sprite itself.
	 */
	#end
	public function loadTexture(path:ModPath, #if Animate_Atlas ?settings:animate.FlxAnimateFrames.FlxAnimateSettings, #end displayWarning:Bool = false):BaseSprite {
		var _path:ModPath = Paths.image(path);
		var _sheet_path:ModPath = Paths.spritesheet(path);
		var type:TextureType = TextureType.getTypeFromExt(_sheet_path, true);
		if (_path.isFile) {
			try {
				if (_sheet_path.extension != 'png' && _sheet_path.isFile && type != IsAnimateAtlas) loadSheet(path, type, displayWarning);
				#if Animate_Atlas else if (_sheet_path.isFile && type == IsAnimateAtlas) loadAtlas(path, settings, displayWarning); #end
				else loadImage(path, displayWarning);
			} catch(error:haxe.Exception) {
				try {
					if (displayWarning)
						trace('The asset failed to load, using whole image. (path: "${_path.format()}", type: "$type", error: "${error.message}")');
					loadImage(path, displayWarning);
				} catch(error:haxe.Exception)
					if (displayWarning) trace('The asset failed to load. (path: "${_path.format()}", type: "$type", error: "${error.message}")');
			}
		}
		return this;
	}

	public function new(x:Float = 0, y:Float = 0, ?sprite:ModPath) {
		super(x, y);
		if (sprite != null)
			loadTexture(sprite, true);
	}

	/**
	 * Adds an animation from a spritesheet.
	 * @param name The name of the animation.
	 * @param tag The name of the animation internally.
	 * @param indices Specific frames for the animation to use, *optional*.
	 * @param offset The offset for the animation.
	 * @param fps The framerate of the animation.
	 * @param loop If true, the animation will repeat when finished.
	 * @param flipX If true, the animation will flipped on the X axis.
	 * @param flipY If true, the animation will flipped on the Y axis.
	 */
	inline public function addAnimation(name:String, tag:String, ?indices:Array<Int>, ?offset:FlxPoint, fps:Float = 24, loop:Bool = false, flipX:Bool = false, flipY:Bool = false):Void {
		if (indices == null || indices.empty())
			animation.addByPrefix(name, tag, fps, loop, flipX, flipY);
		else animation.addByIndices(name, tag, indices, '', fps, loop, flipX, flipY);
		animations.set(name, {offset: offset ?? new FlxPoint(), extra: new Map<String, Dynamic>()});
	}
	/**
	 * Adds an animation from a sliced image.
	 * @param name The name of the animation.
	 * @param frames Specific frames for the animation to use.
	 * @param offset The offset for the animation.
	 * @param fps The framerate of the animation.
	 * @param loop If true, the animation will repeat when finished.
	 * @param flipX If true, the animation will flipped on the X axis.
	 * @param flipY If true, the animation will flipped on the Y axis.
	 */
	inline public function addSlicedAnimation(name:String, frames:Array<Int>, ?offset:FlxPoint, fps:Float = 24, loop:Bool = false, flipX:Bool = false, flipY:Bool = false):Void {
		animation.add(name, frames, fps, loop, flipX, flipY);
		animations.set(name, {offset: offset ?? new FlxPoint(), extra: new Map<String, Dynamic>()});
	}
	#if Animate_Atlas
	/**
	 * Adds an animation from an animate atlas.
	 * @param name The name of the animation.
	 * @param tag The name of the animation internally.
	 * @param label Wether the animation to add is from a labeled frame.
	 * @param indices Specific frames for the animation to use, *optional*.
	 * @param offset The offset for the animation.
	 * @param fps The framerate of the animation.
	 * @param loop If true, the animation will repeat when finished.
	 * @param flipX If true, the animation will flipped on the X axis.
	 * @param flipY If true, the animation will flipped on the Y axis.
	 */
	inline public function addAtlasAnimation(name:String, tag:String, label:Bool = false, ?indices:Array<Int>, ?offset:FlxPoint, fps:Float = 24, loop:Bool = false, flipX:Bool = false, flipY:Bool = false):Void {
		if (label)
			if (indices == null || indices.empty())
				anim.addByFrameLabel(name, tag, fps, loop, flipX, flipY);
			else anim.addByFrameLabelIndices(name, tag, indices, fps, loop, flipX, flipY);
		else
			if (indices == null || indices.empty())
				anim.addBySymbol(name, tag, fps, loop, flipX, flipY);
			else anim.addBySymbolIndices(name, tag, indices, fps, loop, flipX, flipY);
		animations.set(name, {offset: offset ?? new FlxPoint(), extra: new Map<String, Dynamic>()});
	}
	#end

	/**
	 * Plays an animation.
	 * @param name The animation name.
	 * @param force If true, it forces the animation to play.
	 * @param context The animation context.
	 * @param reverse If true, the animation will play in reverse.
	 * @param frame The frame for the animation to start at.
	 */
	public function playAnimation(name:String, force:Bool = true, context:AnimationContext = Unclear, reverse:Bool = false, frame:Int = 0):Void {
		var suffixes = name.trimSplit('-');
		while (!suffixes.empty()) {
			var _name:String = suffixes.join('-'); suffixes.pop();
			if (animation.exists(_name)) {
				animation.play(_name, force, reverse, frame);
				if (animations.exists(_name))
					offset.copyFrom(animations.get(_name).offset);
				break;
			}
			if (debugMode) break;
		}
		suffixes.resize(0);
	}

	override function initVars():Void {
		super.initVars();
	}

	override function destroy():Void {
		super.destroy();
	}
}