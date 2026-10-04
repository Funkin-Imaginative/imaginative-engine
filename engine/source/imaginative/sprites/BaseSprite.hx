package imaginative.sprites;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import imaginative.backend.data.TextureType;
import imaginative.backend.systems.events.callables.sprites.*;

/**
 * Tells you what a sprites current animation is supposed to mean.
 *
 * Idea from Codename Engine.
 */
enum abstract AnimationContext(String) {
	/**
	 * States that the sprite animation is related to dancing.
	 */
	var IsDancing = 'dancing';

	/**
	 * States that the sprite animation is related to singing.
	 */
	var IsSinging = 'singing';
	/**
	 * States that the sprite animation is related to missing a note.
	 */
	var HasMissed = 'missed';

	/**
	 * States that the sprite animation can't go back to dancing.
	 */
	var NoDancing = 'no-dancing';
	/**
	 * States that the sprite animation can't go back to singing.
	 */
	var NoSinging = 'no-singing';

	/**
	 * States that the sprite animation is unclear.
	 */
	var Unclear = null;

	extern inline public function debugString():String {
		return switch (abstract) {
			case IsDancing: 'IsDancing';
			case IsSinging: 'IsSinging';
			case HasMissed: 'HasMissed';
			case NoDancing: 'NoDancing';
			case NoSinging: 'NoSinging';
			case Unclear: 'Unclear';
		}
	}
}

class BaseSprite extends #if Animate_Atlas animate.FlxAnimate #else flixel.FlxSprite #end {
	/**
	 * If true, a *lot*, of automated shit won't work.
	 */
	public var debugMode:Bool = false;

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
	public function loadImage(path:ModPath, width:Int = 0, height:Int = 0, displayWarning:Bool = false, ?infos:haxe.PosInfos):BaseSprite {
		var _path:ModPath = Paths.image(path);
		if (_path.isFile)
			try {
				loadGraphic(Assets.image(path), !(width < 1 || height < 1), width, height);
			} catch(error:haxe.Exception)
				if (displayWarning) log('The image failed to load. (path: "${_path.format()}", error: "${error.message}")', ErrorMessage, infos);
		return this;
	}
	/**
	 * Loads sheet data for the sprite to use.
	 * @param path The mod path.
	 * @param type The wanted texture type.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The sprite itself.
	 */
	public function loadSheet(path:ModPath, type:TextureType = IsUnknown, displayWarning:Bool = false, ?infos:haxe.PosInfos):BaseSprite {
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
							log('The spritesheet failed to load, using whole image. (path: "${_path.format()}", type: "$_type", error: "${error.message}")', WarningMessage, infos);
						loadImage(path, displayWarning);
					} catch(error:haxe.Exception)
						if (displayWarning) log('The spritesheet failed to load. (path: "${_path.format()}", type: "$_type", error: "${error.message}")', ErrorMessage, infos);
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
	public function loadAtlas(path:ModPath, ?settings:animate.FlxAnimateFrames.FlxAnimateSettings, displayWarning:Bool = false, ?infos:haxe.PosInfos):BaseSprite {
		var _atlas_path:ModPath = Paths.spritesheet(path, IsAnimateAtlas);
		if (_atlas_path.isFile) {
			try {
				frames = Assets.frames(path, IsAnimateAtlas, settings);
			} catch(error:haxe.Exception)
				try {
					if (displayWarning)
						log('The atlas failed to load, using first spritemap image. (path: "${_atlas_path.format()}", type: "$IsAnimateAtlas", error: "${error.message}")', WarningMessage, infos);
					loadImage(_atlas_path + 'Animation/spritemap1');
				} catch(error:haxe.Exception)
					if (displayWarning) log('The atlas failed to load. (path: "${_atlas_path.format()}", type: "$IsAnimateAtlas", error: "${error.message}")', ErrorMessage, infos);
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
	public function loadTexture(path:ModPath, #if Animate_Atlas ?settings:animate.FlxAnimateFrames.FlxAnimateSettings, #end displayWarning:Bool = false, ?infos:haxe.PosInfos):BaseSprite {
		var _path:ModPath = Paths.image(path);
		var _sheet_path:ModPath = Paths.spritesheet(path);
		var type:TextureType = TextureType.getTypeFromExt(_sheet_path, true);
		if (_path.isFile) {
			try {
				if (_sheet_path.extension != 'png' && _sheet_path.isFile #if Animate_Atlas && type != IsAnimateAtlas #end) loadSheet(path, type, displayWarning);
				#if Animate_Atlas else if (_sheet_path.isFile && type == IsAnimateAtlas) loadAtlas(path, settings, displayWarning); #end
				else loadImage(path, displayWarning);
			} catch(error:haxe.Exception) {
				try {
					if (displayWarning)
						log('The asset failed to load, using whole image. (path: "${_path.format()}", type: "$type", error: "${error.message}")', WarningMessage, infos);
					loadImage(path, displayWarning);
				} catch(error:haxe.Exception)
					if (displayWarning) log('The asset failed to load. (path: "${_path.format()}", type: "$type", error: "${error.message}")', ErrorMessage, infos);
			}
		}
		return this;
	}

	public var scripts:ScriptGroup;
	var scriptsLoaded(default, null):Bool = false;
	function loadScripting(?paths:Array<ModPath>):Void {
		if (!scriptsLoaded) {
			scripts = new ScriptGroup(this);
			scriptsLoaded = true;
		}

		var locations:Array<ModPath> = ['top:global']; // recycle an array?
		if (!paths.isBlank()) locations.merge(paths);
		paths.putWeak();

		for (sprite in locations)
			for (script in Script.multiCreate('data/sprites' + sprite))
				scripts.add(script);

		locations.put();
		scripts.load();
	}

	public function new(x:Float = 0, y:Float = 0, ?sprite:ModPath, ?scripts:Array<ModPath> #if Animate_Atlas, ?settings:animate.FlxAnimateFrames.FlxAnimateSettings #end) {
		super(x, y);
		loadScripting(scripts);
		_create(); this.scripts.call('onCreate');

		if (sprite != null) loadTexture(sprite, #if Animate_Atlas settings, #end true);

		_createPost(); this.scripts.call('onCreatePost');
	}
	// FOR INTERNAL USE ONLY!! Override these to ensure script call order.
	function _create():Void {}
	function _createPost():Void {
		animation.onFinish.add(name -> {
			if (!debugMode && animation.exists('$name-loop'))
				playAnimation('$name-loop');
		});
	}

	override function update(delta:Float):Void {
		_preUpdate(delta);
		super.update(delta);
		_update(delta);
		_updatePost(delta);
	}
	// FOR INTERNAL USE ONLY!! Override these to ensure script call order.
	function _preUpdate(delta:Float):Void {
		scripts.call('onPreUpdate', [delta]);
	}
	function _update(delta:Float):Void {
		scripts.call('onUpdate', [delta]);
	}
	function _updatePost(delta:Float):Void {
		scripts.call('onUpdatePost', [delta]);
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
	public function addAnimation(name:String, tag:String, ?indices:Array<Int>, ?offset:FlxPoint, fps:Float = 24, loop:Bool = false, flipX:Bool = false, flipY:Bool = false):Void {
		name = name.trim();
		if (indices.isBlank())
			animation.addByPrefix(name, tag, fps, loop, flipX, flipY);
		else animation.addByIndices(name, tag, indices, '', fps, loop, flipX, flipY);

		if (offset != null) {
			animation.getByName(name).offset.copyFrom(offset);
			offset.putWeak();
		}
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
	public function addSlicedAnimation(name:String, frames:Array<Int>, ?offset:FlxPoint, fps:Float = 24, loop:Bool = false, flipX:Bool = false, flipY:Bool = false):Void {
		name = name.trim();
		animation.add(name, frames, fps, loop, flipX, flipY);

		if (offset != null) {
			animation.getByName(name).offset.copyFrom(offset);
			offset.putWeak();
		}
	}
	#if Animate_Atlas
	/**
	 * Adds an animation from an animate atlas.
	 * @param name The name of the animation.
	 * @param tag The name of the animation internally.
	 * @param label Whether the animation to add is from a labeled frame.
	 * @param indices Specific frames for the animation to use, *optional*.
	 * @param offset The offset for the animation.
	 * @param fps The framerate of the animation.
	 * @param loop If true, the animation will repeat when finished.
	 * @param flipX If true, the animation will flipped on the X axis.
	 * @param flipY If true, the animation will flipped on the Y axis.
	 */
	public function addAtlasAnimation(name:String, tag:String, label:Bool = false, ?indices:Array<Int>, ?offset:FlxPoint, fps:Float = 24, loop:Bool = false, flipX:Bool = false, flipY:Bool = false):Void {
		name = name.trim();
		if (label)
			if (indices.isBlank())
				anim.addByFrameLabel(name, tag, fps, loop, flipX, flipY);
			else anim.addByFrameLabelIndices(name, tag, indices, fps, loop, flipX, flipY);
		else
			if (indices.isBlank())
				anim.addBySymbol(name, tag, fps, loop, flipX, flipY);
			else anim.addBySymbolIndices(name, tag, indices, fps, loop, flipX, flipY);

		if (offset != null) {
			animation.getByName(name).offset.copyFrom(offset);
			offset.putWeak();
		}
	}
	#end

	/**
	 * The general animation suffix.
	 *
	 * Note: Appends to the current animation name.
	 */
	public var animationSuffix(default, set):Null<String>;
	@:noCompletion inline function set_animationSuffix(?value:String):Null<String>
		return animationSuffix = value.isBlank() ? null : value.trim();

	function getSuffixViaContext(context:AnimationContext):Null<String> {
		return switch (context) {
			default: animationSuffix;
		}
	}

	/**
	 * Plays an animation.
	 * @param name The animation name.
	 * @param force If true, it forces the animation to play.
	 * @param context The animation context.
	 * @param reverse If true, the animation will play in reverse.
	 * @param frame The frame for the animation to start at.
	 */
	public function playAnimation(name:String, force:Bool = true, context:AnimationContext = Unclear, reverse:Bool = false, frame:Int = 0):Void {
		var event = scripts.event('uponPlayAnimation', PlayAnimationEvent.recycle(name, force, context, reverse, frame));
		if (event.name.isBlank()) {
			_log('[BaseSprite.playAnimation] The animation name can\'t be blank!', DebugMessage);
			return;
		}
		var suffixes:Array<String> = event.name.trimSplit('-').prune(string -> !string.isBlank());
		var contextualSuffix:Null<String> = getSuffixViaContext(event.context);
		if (!contextualSuffix.isBlank()) suffixes.push(contextualSuffix);
		while (!suffixes.isBlank()) {
			var _name:String = suffixes.join('-'); suffixes.pop();
			if (animation.exists(_name)) {
				animation.play(_name, event.force, event.reverse, event.frame);
				animationContext = event.context;
				break;
			}
			if (debugMode || !event.doSuffixChecks)
				break;
		}
		suffixes.put();
	}

	var _scaledFrameOffset:FlxPoint;
	override function initVars():Void {
		super.initVars();
		_scaledFrameOffset = new FlxPoint();
	}

	override function getGraphicBounds(?rect:FlxRect):FlxRect {
		rect ??= FlxRect.get();
		rect.set(x, y);
		if (pixelPerfectPosition)
			rect.floor();

		_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
		rect.x += origin.x - offset.x - _scaledOrigin.x;
		rect.y += origin.y - offset.y - _scaledOrigin.y;
		rect.setSize(frameWidth * scale.x, frameHeight * scale.y);

		if (angle % 360 != 0) {
			_scaledFrameOffset.set(animation.offset.x * scale.x, animation.offset.x * scale.y);
			_cne_FlxRect_getRotatedBounds(rect, angle, _scaledOrigin, rect, _scaledFrameOffset);
		}
		return rect;
	}
	override function getScreenBounds(?rect:FlxRect, ?camera:flixel.FlxCamera):FlxRect {
		rect ??= FlxRect.get();
		camera ??= getDefaultCamera();
		rect.setPosition(x, y);
		if (pixelPerfectPosition) rect.round();

		_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
		rect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x;
		rect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y;

		if (isPixelPerfectRender(camera)) rect.round();
		rect.setSize(frameWidth * Math.abs(scale.x), frameHeight * Math.abs(scale.y));
		_scaledFrameOffset.set(animation.offset.x * scale.x, animation.offset.x * scale.y);
		return _cne_FlxRect_getRotatedBounds(rect, angle, _scaledOrigin, rect, _scaledFrameOffset);
	}

	override function destroy():Void {
		scripts.destroy();
		_scaledFrameOffset.put();
		super.destroy();
	}

	@:noCompletion extern inline static function _cne_FlxRect_getRotatedBounds(parent:FlxRect, degrees:Float, ?origin:FlxPoint, ?newRect:FlxRect, ?innerOffset:FlxPoint):FlxRect {
		origin ??= FlxPoint.weak();
		newRect ??= FlxRect.get();
		innerOffset ??= FlxPoint.weak();

		degrees = degrees % 360;
		if (degrees == 0) {
			newRect.set(parent.x - innerOffset.x, parent.y - innerOffset.y, parent.width, parent.height);
			origin.putWeak();
			innerOffset.putWeak();
			return newRect;
		}

		if (degrees < 0)
			degrees += 360;

		var radians = flixel.math.FlxAngle.TO_RAD * degrees;
		var cos = Math.cos(radians);
		var sin = Math.sin(radians);

		var left = -origin.x - innerOffset.x;
		var top = -origin.y - innerOffset.y;
		var right = -origin.x + parent.width - innerOffset.x;
		var bottom = -origin.y + parent.height - innerOffset.y;
		if (degrees < 90) {
			newRect.x = parent.x + origin.x + cos * left - sin * bottom;
			newRect.y = parent.y + origin.y + sin * left + cos * top;
		} else if (degrees < 180) {
			newRect.x = parent.x + origin.x + cos * right - sin * bottom;
			newRect.y = parent.y + origin.y + sin * left + cos * bottom;
		} else if (degrees < 270) {
			newRect.x = parent.x + origin.x + cos * right - sin * top;
			newRect.y = parent.y + origin.y + sin * right + cos * bottom;
		} else {
			newRect.x = parent.x + origin.x + cos * left - sin * top;
			newRect.y = parent.y + origin.y + sin * right + cos * top;
		}
		// temp var, in case input rect is the output rect
		var newHeight = Math.abs(cos * parent.height) + Math.abs(sin * parent.width);
		newRect.width = Math.abs(cos * parent.width) + Math.abs(sin * parent.height);
		newRect.height = newHeight;

		origin.putWeak();
		innerOffset.putWeak();
		return newRect;
	}
}