package imaginative.backend.systems;

import sys.FileSystem;
import imaginative.backend.data.StringedArray;
import imaginative.backend.data.TextureType;

/**
 * A helper class for stating where paths should start from.
 */
enum abstract ModType(String) {
	// Base Paths
	/**
	 * The root of the engine.
	 */
	var ROOT = 'root';
	/**
	 * The fallback mod.
	 */
	var FALLBACK = 'fallback';
	/**
	 * The "UpFront" mod.
	 */
	var MASTER = 'master';
	/**
	 * The "LowerEnd" mods.
	 */
	var MODULE = 'module';

	// Grouped Filters
	/**
	 * "FALLBACK", "MASTER" and "MODULE".
	 */
	var ALL = 'all';
	/**
	 * "FALLBACK" and "MASTER.
	 */
	var TOP = 'top';
	/**
	 * "MASTER" and "MODULE".
	 */
	var MODS = 'mods';
	/**
	 * "FALLBACK" and "MODULE".
	 *
	 * __*Current name is a placeholder.*__
	 */
	var NORM = 'norm';

	/**
	 * Checks if the incoming type is the wanted type.
	 * @param wanted The wanted type.
	 * @param incoming The incoming type.
	 * @return If true, the incoming is the wanted type.
	 */
	inline public static function pathCheck(wanted:ModType, ?incoming:ModType):Bool {
		return switch (wanted) {
			#if Modding // remember Modding.masterIsFallback
			case FALLBACK: incoming == null || incoming == FALLBACK || incoming == TOP || incoming == NORM || incoming == ALL;
			case MASTER: incoming == MASTER || incoming == TOP || incoming == MODS || incoming == ALL;
			case MODULE: incoming == MODULE || incoming == MODS || incoming == NORM || incoming == ALL;
			#end
			default: false;
		}
	}

	@:from inline public static function fromString(value:String):ModType {
		return switch (value.toLowerCase().trim()) {
			// Base Paths
			case 'root' | 'none': ROOT;
			case 'fallback' | 'main': FALLBACK;
			case 'master' | 'upfront': MASTER;
			case 'module' | 'lowerend': MODULE;
			// Grouped Filters
			case 'all': ALL;
			case 'top': TOP;
			case 'mods': MODS;
			case 'norm': NORM;
			default: ALL;
		}
	}
	@:to inline public function toString():String
		return this.toLowerCase().trim();
}

/**
 * For less array usage internally.
 */
private typedef TModPath = {
	var moduleId:Null<String>;
	var type:ModType;
	var path:String;
}
/**
 * A helper class for flitering paths within the engine.
 ```haxe
 Paths.image('master:gameplay/popups/funkin/killer')
 Paths.json('[norm:pico-mixes]:data/sprites/characters/nene')
 Paths.json('[pico-mixes]:data/sprites/characters/darnell')
 ```
 */
abstract ModPath(String) {
	/**
	 * Util variable.
	 */
	var self(get, never):TModPath;
	inline function get_self():TModPath
		return toTypedef();

	/**
	 * If true, this path exists.
	 */
	public var exists(get, never):Bool;
	inline function get_exists():Bool
		return Paths.pathExists(abstract);

	/**
	 * If true, this is a file.
	 */
	public var isFile(get, never):Bool;
	inline function get_isFile():Bool
		return Paths.fileExists(abstract);
	/**
	 * If true, this is a folder.
	 */
	public var isDirectory(get, never):Bool;
	inline function get_isDirectory():Bool
		return Paths.folderExists(abstract);

	/**
	 * The module id. **Can be null.**
	 */
	public var moduleId(get, set):Null<String>;
	inline function get_moduleId():Null<String>
		return self.moduleId;
	inline function set_moduleId(?value:String):Null<String> {
		this = new ModPath(path, type, value);
		return value;
	}

	/**
	 * The path type.
	 */
	public var type(get, set):ModType;
	inline function get_type():ModType
		return self.type;
	inline function set_type(value:ModType):ModType {
		this = new ModPath(path, value, moduleId);
		return value;
	}
	/**
	 * The mod path.
	 */
	public var path(get, set):String;
	inline function get_path():String
		return FilePath.removeTrailingSlashes(self.path);
	inline function set_path(value:String):String {
		this = new ModPath(value, type, moduleId);
		return value;
	}

	/**
	 * The file extension of the mod path. **Can be null.**
	 */
	public var extension(get, set):Null<String>;
	inline function get_extension():Null<String>
		return FilePath.extension(path).ifBlankReplace();
	inline function set_extension(?value:String):Null<String>
		return path = '${FilePath.withoutExtension(path)}${value.isBlank() ? '' : '.$value'}';

	/**
	 * @param path The mod path.
	 * @param type The path type.
	 * @param moduleId Optional module id.
	 */
	inline public function new(path:String, type:ModType = ALL, ?moduleId:String) {
		path = FilePath.removeTrailingSlashes(path);
		if (!moduleId.isBlank()) {
			if (type != ALL)
				this = '[$type:$moduleId]:$path';
			else this = '[$moduleId]:$path';
		} else {
			if (type != ALL)
				this = '$type:$path';
			else this = path;
		}
	}

	/**
	 * Sets the file extension of the mod path.
	 *
	 * Literally *just for **chaining***.
	 * @param ext The new extension.
	 * @return The abstract itself.
	 */
	inline public function applyExt(?ext:String):ModPath {
		extension = ext;
		return abstract;
	}

	/**
	 * Formats the info in the abstract into the final path.
	 * @return The finalized path.
	 */
	inline public function format():String
		return Paths.applyRoot(path, type, moduleId);

	@:op(A += B) inline public function appendPath(addition:ModPath):ModPath {
		var ext:String = addition.extension.ifBlankReplace(abstract.extension);
		var path:Bool = FilePath.withoutExtension(abstract.path).isBlank() || FilePath.withoutExtension(addition.path).isBlank();
		return this = new ModPath(FilePath.withoutExtension(abstract.path) + (path ? '' : '/') + FilePath.withoutExtension(addition.path) + (ext.isBlank() ? '' : '.$ext'), addition.type, addition.moduleId.ifBlankReplace(abstract.moduleId.ifBlankReplace()));
	}
	@:op(A + B) inline public static function mergePath(a:ModPath, b:ModPath):ModPath
		return a.appendPath(b);

	@:from inline public static function fromTypedef(value:TModPath):ModPath {
		return new ModPath(value.path, value.type, value.moduleId.ifBlankReplace());
	}
	@:to inline public function toTypedef():TModPath
		return resolve(this);

	@:from inline public static function fromString(value:String):ModPath
		return resolve(value);
	@:to inline public function toString():String {
		if (!moduleId.isBlank()) {
			if (type == ALL)
				return '[$moduleId]:$path';
			return '[$type:$moduleId]:$path';
		}
		if (type == ALL) // keep?
			return path;
		return '$type:$path';
	}

	// FlxAssets fix
	@:to inline public function toFlxGraphicAsset():flixel.system.FlxAssets.FlxGraphicAsset return format();
	@:to inline public function toFlxSoundAsset():flixel.system.FlxAssets.FlxSoundAsset return format();
	@:to inline public function toFlxXmlAsset():flixel.system.FlxAssets.FlxXmlAsset return format();
	@:to inline public function toFlxAsepriteJsonAsset():flixel.system.FlxAssets.FlxAsepriteJsonAsset return format();

	static function resolve(path:String):TModPath {
		if (path.isBlank()) // checks if null as well
			return {moduleId: null, type: ALL, path: ''}
		if (path.contains(':')) {
			try { // jic
				var parts = path.trimSplit(':');
				if (parts[0].startsWith('[')) {
					if (parts[0].endsWith(']')) {
						var result:TModPath = {moduleId: null, type: parts[0].substr(1).substr(0, -1).trim().ifBlankReplace(ALL), path: FilePath.removeTrailingSlashes(parts[1])}
						parts.clear();
						return result;
					}
					if (parts[1].endsWith(']')) {
						var result:TModPath = {moduleId: parts[1].substr(0, -1).trim(), type: parts[0].substr(1).trim().ifBlankReplace(ALL), path: FilePath.removeTrailingSlashes(parts[2])}
						parts.clear();
						return result;
					}
				}
				var result:TModPath = {moduleId: null, type: parts[0].trim().ifBlankReplace(ALL), path: FilePath.removeTrailingSlashes(parts[1])}
				parts.clear();
				return result;
			} catch(error:haxe.Exception)
				trace(error);
		}
		return {moduleId: null, type: ALL, path: FilePath.removeTrailingSlashes(path)}
	}
}

final class FileModPath {
	var _path:FilePath;

	/**
	 * The full path.
	 */
	public var path(get, never):String;
	inline function get_path():String {
		return (directory.isBlank() ? '' : directory + (_path.backslash ? '\\' : '/')) + file + (extension.isBlank() ? '' : '.' + extension);
	}

	/**
	 * The directory. **Can be null.**
	 */
	public var directory(get, set):Null<String>;
	inline function get_directory():Null<String> return _path.dir;
	inline function set_directory(?value:String):Null<String> return _path.dir = value;
	/**
	 * The file name.
	 */
	public var file(get, set):String;
	inline function get_file():String return _path.file;
	inline function set_file(value:String):String return _path.file = value;
	/**
	 * The extension of the file. **Can be null.**
	 */
	public var extension(get, set):Null<String>;
	inline function get_extension():Null<String> return _path.ext;
	inline function set_extension(?value:String):Null<String> return _path.ext = value;

	/**
	 * The mod type.
	 */
	public var modType:ModType;
	/**
	 * The module id. **Can be null.**
	 */
	public var moduleId:Null<String>;

	public function new(fullPath:String, modType:ModType = ROOT, ?moduleId:String) {
		this.modType = modType;
		this.moduleId = moduleId;
		_path = new FilePath(fullPath);
	}

	inline public static function fromModPath(path:ModPath):FileModPath
		return new FileModPath(path.path, path.type, path.moduleId);

	/**
	 * Formats the info in the class into the final path.
	 * @return The finalized path.
	 */
	inline public function format():ModPath return toString().format();
	inline public function toString():ModPath return new ModPath(path, modType, moduleId);
}
/**
 * A helper class for getting directories.
 */
class Paths {
	/**
	 * Finalizes a mod path.
	 * @param path The mod path.
	 * @param type The path type.
	 * @param moduleId Optional module id.
	 * @return The finalized path.
	 */
	public static function applyRoot(path:String, type:ModType = ALL, ?moduleId:String):String {
		var result:String = '';
		var check:ModPath = '';

		#if Modding
		if (result.isBlank() && ModType.pathCheck(MODULE, type))
			if (pathExists(check = new Modpath(moduleId.isBlank() ? Modding.getModsRoot(path) : 'modules/$moduleId/$path', ROOT)))
				result = check.path;
		// trace('MODULE: $result');
		if (result.isBlank() && ModType.pathCheck(MASTER, type))
			if (pathExists(check = new ModPath('mods/${Modding.masterMod}/$path', ROOT)))
				result = check.path;
		// trace('MASTER: $result');
		if (result.isBlank() && ModType.pathCheck(FALLBACK, type))
			if (pathExists(check = new ModPath('mods/${Game.fallbackMod}/$path', ROOT)))
				result = check.path;
		// trace('FALLBACK: $result');
		#end
		if (result.isBlank() && type == ROOT)
			if (pathExists(check = new ModPath('$path', ROOT)))
				result = check.path;
		// trace('ROOT: $result');
		if (result.isBlank())
			if (pathExists(check = new ModPath('assets/$path', ROOT)))
				result = check.path;
		// trace('RESULT: $result');

		return result.ifBlankReplace(path.ifBlankReplace('./'));
	}

	/**
	 * @param path The mod path.
	 * @param exts The extensions to filter through.
	 * @return The flitered path.
	 */
	public static function file(path:ModPath, exts:StringedArray = ''):ModPath {
		if (exts.length == 0) return path;
		var ogExt:String = path.extension;
		var result:ModPath = '';
		for (ext in exts)
			if (fileExists(result = path.applyExt(ext))) break;
			else result = path.applyExt(ogExt); // jic
		return result;
	}

	/**
	 * Gets the path of a font file from "`../fonts`".
	 *
	 * **Can automatically apply the extension.**
	 * @param path The mod path.
	 * @return The desired path.
	 */
	inline public static function font(path:ModPath):ModPath {
		var check:ModPath = file('fonts' + path, new StringedArray(',', 'ttf', 'otf'));
		if (!check.isFile) check = 'fonts' + path;
		return check;
	}

	/**
	 * Applies the "txt" extension.
	 * @param path The mod path.
	 * @return The desired file type.
	 */
	inline public static function txt(path:ModPath):ModPath
		return path.applyExt('txt');
	/**
	 * Applies the "xml" extension.
	 * @param path The mod path.
	 * @return The desired file type.
	 */
	inline public static function xml(path:ModPath):ModPath
		return path.applyExt('xml');
	/**
	 * Applies the "json" extension.
	 * @param path The mod path.
	 * @return The desired file type.
	 */
	inline public static function json(path:ModPath):ModPath
		return path.applyExt('json');

	/**
	 * Gets the path of a level json from "`../data/levels`".
	 *
	 * **Automatically applies the extension.**
	 * @param path The mod path.
	 * @return The desired path.
	 */
	inline public static function level(path:ModPath):ModPath
		return json('data/levels' + path);
	/**
	 * Gets the path of a chart file from "`../data/songs/`".
	 *
	 * **Automatically applies the extension.**
	 * @param song The song id.
	 * @param difficulty The difficulty key.
	 * @param variant The variation key. **Can be null.**
	 * @return The desired path.
	 */
	inline public static function song(song:ModPath, difficulty:String, ?variant:String):ModPath
		return json('data/songs' + song + '${variant.isBlank() ? '' : 'variations/$variant/'}charts/$difficulty');

	/**
	 * Gets the path of a sprite json from "`../data/sprites`".
	 *
	 * **Automatically applies the extension.**
	 * @param path The mod path.
	 * @return The desired path.
	 */
	inline public static function sprite(path:ModPath):ModPath
		return json('data/sprites' + path);
	/**
	 * Gets the path of a character json from "`../data/sprites/characters`".
	 *
	 * **Automatically applies the extension.**
	 * @param path The mod path.
	 * @return The desired path.
	 */
	inline public static function character(path:ModPath):ModPath
		return sprite('characters' + path);
	/**
	 * Gets the path of an icon json from "`../data/sprites/icons`".
	 *
	 * **Automatically applies the extension.**
	 * @param path The mod path.
	 * @return The desired path.
	 */
	inline public static function icon(path:ModPath):ModPath
		return sprite('icons' + path);

	/**
	 * Gets the path of an image file from "`../images`".
	 * @param path The mod path.
	 * @return The desired file type.
	 */
	inline public static function image(path:ModPath):ModPath
		return 'images' + path.applyExt('png');

	/**
	 * Gets the path of an images sheet extention.
	 * @param path The mod path.
	 * @param type The wanted texture type.
	 * @return The desired path.
	 */
	inline public static function spritesheet(path:ModPath, type:TextureType = IsUnknown):ModPath
		return #if Animate_Atlas type == IsAnimateAtlas ? json(image(path + 'Animation')) : #end file(image(path), type == IsUnknown ? TextureType.exts : ',' + TextureType.getExtFromType(type));

	/**
	 * Gets the path of an audio file.
	 *
	 * **Automatically applies the extension.**
	 * @param path The mod path.
	 * @return The desired path.
	 */
	inline public static function audio(path:ModPath):ModPath
		return file(path, new StringedArray(',', 'wav', 'ogg', 'mp3'));

	/**
	 * Gets the path of an instrumental file from "`../data/songs/`".
	 *
	 * **Automatically applies the extension.**
	 * @param song The song id.
	 * @param variant The variation key. **Can be null.**
	 * @return The desired path.
	 */
	inline public static function inst(song:ModPath, ?variant:String):ModPath
		return audio('data/songs' + song + '${variant.isBlank() ? '' : 'variations/$variant/'}audio/Inst');
	/**
	 * Gets the path of a vocal file from "`../data/songs/`".
	 *
	 * **Automatically applies the extension.**
	 * @param song The song id.
	 * @param suffix The vocal suffix(es). **Can be null.**
	 * @param variant The variation key. **Can be null.**
	 * @return The desired path.
	 */
	inline public static function vocal(song:ModPath, ?suffix:String, ?variant:String):ModPath {
		var suffixes:StringedArray = '-' + suffix.ifBlankReplace('');
		var result:String = suffixes.length == 0 ? '' : suffixes;
		return audio('data/songs' + song + '${variant.isBlank() ? '' : 'variations/$variant/'}audio/Voices$result');
	}

	/**
	 * Gets the path of an audio file from "`../music`".
	 *
	 * **Automatically applies the extension.**
	 * @param path The mod path.
	 * @return The desired path.
	 */
	inline public static function music(path:ModPath):ModPath
		return audio('music' + path + 'audio');
	/**
	 * Gets the path of an audio file from "`../sounds`".
	 *
	 * **Automatically applies the extension.**
	 * @param path The mod path.
	 * @return The desired path.
	 */
	inline public static function sound(path:ModPath):ModPath
		return audio('sounds' + path);

	/**
	 * Gets the path of a video file.
	 *
	 * **Automatically applies the extension.**
	 * @param path The mod path.
	 * @return The desired path.
	 */
	inline public static function video(path:ModPath):ModPath
		return file(path, new StringedArray(',' ,'mp4', 'mov', 'webm'));
	/**
	 * Gets the path of a video file from "`../data/songs`" or "`../videos`".
	 *
	 * **Automatically applies the extension.**
	 * @param path The mod path.
	 * @return The desired path.
	 */
	inline public static function cutscene(path:ModPath):ModPath {
		var check:ModPath = video('data/songs' + 'current-song-id-and-shit' + path);
		if (!check.isFile) check = video('videos' + path);
		return check;
	}

	/**
	 * Reads a folder and returns it's paths.
	 * @param path The folder mod path.
	 * @param setExts Specified extensions, *optional*.
	 * @param recursive If true, it can scan subfolders. *Ignores "setExts".*
	 * @return The path data.
	 */
	public static function readFolder(path:ModPath, setExts:StringedArray = '', recursive:Bool = false):Array<FileModPath> {
		var files:Array<FileModPath> = [];
		if (path.isDirectory)
			for (item in FileSystem.readDirectory(path.format())) {
				var data:FileModPath = new FileModPath(FilePath.addTrailingSlash(path.path) + item, path.type, path.moduleId);
				if (setExts.length == 0 || setExts.contains(data.extension)) files.push(data);
				if (recursive && data.toString().isDirectory) files.merge(readFolder(data.toString(), setExts, true), true);
			}
		files.arraySort((a, b) -> {
			var a = a.path.toLowerCase();
			var b = b.path.toLowerCase();
			if (a < b) return -1;
			if (a > b) return 1;
			return 0;
		});
		return files;
	}

	/**
	 * Checks if the path exists.
	 * @param path The mod path.
	 * @return If true, the path exists.
	 */
	inline public static function pathExists(path:ModPath):Bool
		return FileSystem.exists(path.type == ROOT ? '${path.path.ifBlankReplace('./')}' : path.format());
	/**
	 * Checks if the file exists.
	 * @param path The mod path.
	 * @return If true, the file exists.
	 */
	inline public static function fileExists(path:ModPath):Bool {
		return FlxG.assets.exists(path.format()) || (!folderExists(path) && pathExists(path));
	}
	/**
	 * Checks if the folder exists.
	 * @param path The mod path.
	 * @return If true, the folder exists.
	 */
	inline public static function folderExists(path:ModPath):Bool
		return FileSystem.isDirectory(path.type == ROOT ? '${path.path.ifBlankReplace('./')}' : path.format());

	/**
	 * Checks if an image as a sheet extention.
	 * @param path The mod path.
	 * @return If true,
	 */
	inline public static function spritesheetExists(path:ModPath):Bool
		return image(path).isFile && spritesheet(path).isFile;
}