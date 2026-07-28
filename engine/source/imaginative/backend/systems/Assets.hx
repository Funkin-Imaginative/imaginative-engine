package imaginative.backend.systems;

import sys.io.File;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import moonchart.backend.Util as MoonchartUtil;
import openfl.display.BitmapData;
import openfl.media.Sound;
import imaginative.backend.data.TextureType;
#if Animate_Atlas
import animate.FlxAnimateAssets;
import animate.FlxAnimateFrames;
#end

enum abstract PersistenceType(String) {
	/**
	 * States that the asset cannot be removed, even if persistant assets are told to be cleared.
	 */
	var IsIndestructible = 'indestructible';
	/**
	 * States that the asset cannot be removed, unless told to be.
	 */
	var IsPersistent = 'persistent';
	/**
	 * A normal asset.
	 */
	var IsVulnerable = 'vulnerable';
}
enum abstract CacheType(Null<Bool>) {
	/**
	 * States that the asset should be ignored when asked to cache.
	 */
	var IgnoreCache = false;
	/**
	 * States that the asset should be **re**cached.
	 */
	var OverrideCache = null;
	/**
	 * States that the asset should be cached.
	 */
	var CacheAsset = true;
}

// TODO: Account for lime and openfl shit.
class Assets {
	static var content:Map<String, Dynamic> = new Map<String, Dynamic>();
	static var persistenceList:Map<String, PersistenceType> = new Map<String, PersistenceType>();

	inline public static function addContent(path:String, data:Dynamic, cacheType:CacheType, persistenceType:PersistenceType):Void {
		var wasCached:Bool = false;
		switch (cacheType) {
			case IgnoreCache:
				// do nothing lol
			case OverrideCache:
				content.set(path, data);
				wasCached = true;
			case CacheAsset:
				if (!content.exists(path))
					content.set(path, data);
				wasCached = true;
		}
		if (wasCached)
			persistenceList.set(path, persistenceType);
	}
	inline public static function getContent(path:String):Dynamic return content.get(path);
	inline public static function contentExists(path:String):Bool return content.exists(path);
	inline public static function removeContent(path:String, ignorePersistent:Bool = false):Void {
		if (persistenceList.exists(path)) {
			var persistenceType:PersistenceType = persistenceList.get(path);
			switch (persistenceType) {
				case IsIndestructible:
					// do nothing lol
				case IsPersistent:
					if (ignorePersistent) {
						content.remove(path);
						persistenceList.remove(path);
					}
				case IsVulnerable:
					content.remove(path);
					persistenceList.remove(path);
			}
		}
	}

	@:unreflective inline static function init():Void {
		FlxG.bitmap.add(FlxG.assets.getBitmapData('flixel/images/logo/default.png'), 'FlixelLogo').persist = true;
		FlxG.assets.getSound('flixel/sounds/beep.ogg', true);

		inline function _readFolder(path:String, recursive:Bool):Array<String> {
			var data = Paths.readFolder('root:$path', recursive);
			var result:Array<String> = [for (lol in data) lol.format()];
			data.resize(0);
			return result;
		}

		MoonchartUtil.readFolder = (path:String) -> _readFolder(path, false);
		MoonchartUtil.isFolder = (path:String) -> Paths.folderExists('root:$path');
		MoonchartUtil.getText = (path:String) -> text('root:$path', true);

		#if Animate_Atlas
		FlxAnimateAssets.exists = (path:String, type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType) -> Paths.fileExists('root:$path');
		FlxAnimateAssets.getText = MoonchartUtil.getText;
		FlxAnimateAssets.getBitmapData = (path:String) -> image('root:$path', true).bitmap;
		FlxAnimateAssets.list = (path:String, ?type:flixel.system.frontEnds.AssetFrontEnd.FlxAssetType, ?library:String, includeSubDirectories:Bool = false) -> _readFolder(path, includeSubDirectories);
		#end
	}

	/**
	 * Parses a text file and returns its contents.
	 *
	 * **Doesn't** apply the extension for you.
	 * @param path The mod path.
	 * @param cacheType The cache type.
	 * @param displayWarning If true, a warning message will appear.
	 * @return Raw text.
	 */
	inline public static function text(path:ModPath, cacheType:CacheType = IgnoreCache, displayWarning:Bool = false):String {
		var finalPath:String = path.format();
		if (cacheType == CacheAsset && contentExists(finalPath)) return getContent(path);
		var asset:String = '';
		try {
			asset = path.isFile ? File.getContent(finalPath) : '';
			if (!asset.isBlank()) addContent(finalPath, asset, cacheType, IsVulnerable);
			else if (displayWarning) trace('Couldn\'t find "$finalPath".');
		} catch(error:haxe.Exception)
			if (displayWarning) trace('An error occurred when parsing the file. (path: "$finalPath", error: "${error.message}")');
		return asset.ifBlankReplace('');
	}

	/**
	 * Parses a json file from a path and returns its contents.
	 * @param path The mod path.
	 * @param cacheType The cache type.
	 * @param displayWarning If true, a warning message will appear.
	 * @return A dynamic structure. **Can be null,** especially if it doesn't exist.
	 */
	inline public static function json(path:ModPath, cacheType:CacheType = IgnoreCache, displayWarning:Bool = false):Null<Dynamic> {
		var _path:ModPath = Paths.json(path);
		var finalPath:String = _path.format();
		if (cacheType == CacheAsset && contentExists(finalPath)) return getContent(path);
		var data:Dynamic = rawJson(text(_path), _path, displayWarning);
		if (data != null) addContent(finalPath, data, cacheType, IsVulnerable);
		return data;
	}
	/**
	 * Parses a json file from a raw string and returns its contents.
	 * @param contents The raw string.
	 * @param path Optional mod path, mainly for the error message.
	 * @param displayWarning If true, a warning message will appear.
	 * @return A dynamic structure. **Can be null.**
	 */
	inline public static function rawJson(contents:String, ?path:ModPath, displayWarning:Bool = false):Null<Dynamic> {
		var data:Dynamic = null;
		try {
			data = haxe.Json.parse(contents);
		} catch(error:haxe.Exception) if (displayWarning) {
			var errorPath:String = StringUtil.isBlank(path) ? '' : path.format(); // wouldn't work with using
			trace('An error occurred when parsing the json. (${errorPath.isBlank() ? '' : 'path: "$errorPath", '}error: "${error.message}")');
		}
		return data;
	}

	/**
	 * Gets the data of an image file from "`../images`".
	 * @param path The mod path.
	 * @param cacheType The cache type.
	 * @param persistenceType The persistence type.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The image data.
	 */
	public static function image(path:ModPath, cacheType:CacheType = CacheAsset, persistenceType:PersistenceType = IsVulnerable, displayWarning:Bool = false):FlxGraphic {
		var _path:ModPath = Paths.image(path);
		var finalPath:String = _path.format();

		if (!_path.isFile) {
			if (displayWarning)
				trace('Image asset couldn\'t be found, falling back to the flixel logo. (path: "$finalPath")');
			return FlxG.bitmap.get('FlixelLogo');
		}
		if (cacheType == CacheAsset && contentExists(finalPath))
			return getContent(finalPath);

		var bitmap:BitmapData = FlxG.assets.exists(finalPath, IMAGE) ? FlxG.assets.getBitmapData(finalPath) : BitmapData.fromFile(finalPath);
		var asset:FlxGraphic = FlxG.bitmap.add(bitmap, finalPath);
		addContent(finalPath, asset, cacheType, persistenceType);
		asset.incrementUseCount();
		return asset;
	}

	static function _audio(path:ModPath, beepWhenNull:Bool, streamIt:Bool, cacheType:CacheType, persistenceType:PersistenceType, displayWarning:Bool):Sound {
		var finalPath:String = path.format();

		if (!path.isFile) {
			if (beepWhenNull) {
				if (displayWarning)
					trace('Audio asset couldn\'t be found, falling back to the flixel beep sound. (path: "$finalPath")');
				return FlxG.assets.getSound('flixel/sounds/beep.ogg', true);
			}
			if (displayWarning)
				trace('Audio asset couldn\'t be found. (path: "$finalPath")');
		}
		if (cacheType == CacheAsset && contentExists(finalPath))
			return getContent(finalPath);

		var asset:Sound = FlxG.assets.exists(finalPath, SOUND) ? (streamIt && FlxG.assets.canStreamSound(finalPath) ? FlxG.assets.streamSound(finalPath) : FlxG.assets.getSound(finalPath)) : Sound.fromFile(finalPath);
		addContent(finalPath, asset, cacheType, persistenceType);
		return asset;
	}
	/**
	 * Gets the data of an audio file.
	 * @param path The mod path.
	 * @param beepWhenNull If true, returns the flixel beep noise if the chosen sound doesn't exist.
	 * @param streamIt If true, the audio will be streamed, recommended for music.
	 * @param cacheType The cache type.
	 * @param persistenceType The persistence level.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The audio data.
	 */
	inline public static function audio(path:ModPath, beepWhenNull:Bool = true, streamIt:Bool = false, cacheType:CacheType = CacheAsset, persistenceType:PersistenceType = IsVulnerable, displayWarning:Bool = false):Sound
		return _audio(Paths.audio(path), beepWhenNull, streamIt, cacheType, persistenceType, displayWarning);

	/**
	 * Gets the data of an instrumental file from "`../data/songs/`".
	 * @param song The song id.
	 * @param variant The variation key. **Can be null.**
	 * @param reloadCache If true, it reloads the cache.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The instrumental audio data.
	 */
	inline public static function inst(song:ModPath, ?variant:String, reloadCache:Bool = false, displayWarning:Bool = false):Sound
		return _audio(Paths.inst(song, variant), true, true, reloadCache ? OverrideCache : CacheAsset, IsVulnerable, displayWarning);
	/**
	 * Gets the data of a vocal file from "`../data/songs/`".
	 * @param song The song id.
	 * @param suffix The vocal suffix(es). **Can be null.**
	 * @param variant The variation key. **Can be null.**
	 * @param reloadCache If true, it reloads the cache.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The vocal audio data.
	 */
	inline public static function vocal(song:ModPath, ?suffix:String, ?variant:String, reloadCache:Bool = false, displayWarning:Bool = false):Sound
		return _audio(Paths.vocal(song, suffix, variant), false, true, reloadCache ? OverrideCache : CacheAsset, IsVulnerable, displayWarning);

	/**
	 * Gets the data of an audio file from "`../music`".
	 * @param path The mod path.
	 * @param cacheType The cache type.
	 * @param persistenceType The persistence level.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The music audio data.
	 */
	inline public static function music(path:ModPath, cacheType:CacheType = CacheAsset, persistenceType:PersistenceType = IsVulnerable, displayWarning:Bool = false):Sound
		return _audio(Paths.music(path), true, true, cacheType, persistenceType, displayWarning);
	/**
	 * Gets the data of an audio file from "`../sounds`".
	 * @param path The mod path.
	 * @param beepWhenNull If true, returns the flixel beep noise if the chosen sound doesn't exist.
	 * @param streamIt If true, the audio will be streamed, recommended for music.
	 * @param cacheType The cache type.
	 * @param persistenceType The persistence level.
	 * @param displayWarning If true, a warning message will appear.
	 * @return The sound audio data.
	 */
	inline public static function sound(path:ModPath, beepWhenNull:Bool = true, streamIt:Bool = false, cacheType:CacheType = CacheAsset, persistenceType:PersistenceType = IsVulnerable, displayWarning:Bool = false):Sound
		return _audio(Paths.sound(path), beepWhenNull, streamIt, cacheType, persistenceType, displayWarning);

	// im so funny uwu
	#if Animate_Atlas
	/**
	 * Gets the data of spritesheet from "`../images`".
	 * @param path The mod path.
	 * @param type The wanted texture type.
	 * @param settings The animate atlas settings.
	 * @return The spritesheet data.
	 */
	#else
	/**
	 * Gets the data of spritesheet from "`../images`".
	 * @param path The mod path.
	 * @param type The wanted texture type.
	 * @return The spritesheet data.
	 */
	#end
	public static function frames(path:ModPath, type:TextureType = IsUnknown #if Animate_Atlas, ?settings:FlxAnimateSettings #end):FlxAtlasFrames {
		if (type == IsUnknown) {
			if (Paths.xml(Paths.image(path)).isFile) type = IsSparrow;
			if (Paths.txt(Paths.image(path)).isFile) type = IsPacker;
			if (Paths.json(Paths.image(path)).isFile) type = IsAseprite;
			#if Animate_Atlas if (Paths.json(Paths.image(path + 'Animation')).isFile) type = IsAnimateAtlas; #end
		}
		return switch (type) {
			case IsSparrow: getSparrowFrames(path);
			case IsPacker: getPackerFrames(path);
			case IsAseprite: getAsepriteFrames(path);
			#if Animate_Atlas case IsAnimateAtlas: getAnimateAtlas(path, settings); #end
			default: getSparrowFrames(path);
		}
	}
	/**
	 * Gets the data of a sparrow sheet from "`../images`".
	 * @param path The mod path.
	 * @return The sparrow frame data.
	 */
	inline public static function getSparrowFrames(path:ModPath):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(image(path), Paths.xml(Paths.image(path)));
	/**
	 * Gets the data of a packer sheet from "`../images`".
	 * @param path The mod path.
	 * @return The packer frame data.
	 */
	inline public static function getPackerFrames(path:ModPath):FlxAtlasFrames
		return FlxAtlasFrames.fromSpriteSheetPacker(image(path), Paths.txt(Paths.image(path)));
	/**
	 * Gets the data of a aseprite sheet from "`../images`".
	 * @param path The mod path.
	 * @return The aseprite frame data.
	 */
	inline public static function getAsepriteFrames(path:ModPath):FlxAtlasFrames
		return FlxAtlasFrames.fromAseprite(image(path), Paths.json(Paths.image(path)));
	#if Animate_Atlas
	/**
	 * Gets the data of a animate atlas from "`../images`".
	 * @param path The mod path.
	 * @param settings The animate atlas settings.
	 * @return The animate atlas frame data.
	 */
	inline public static function getAnimateAtlas(path:ModPath, ?settings:FlxAnimateSettings):FlxAnimateFrames
		return FlxAnimateFrames.fromAnimate(Paths.json(Paths.image(path + 'Animation')), settings);
	#end
}