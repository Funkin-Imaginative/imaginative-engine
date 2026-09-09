package imaginative.backend.data;

/**
 * The texture type of a sprite.
 */
enum abstract TextureType(String) {
	public static final exts:Array<String> = ['xml', 'txt', 'json'];

	/**
	 * States that this sprite uses the sparrow sheet method.
	 */
	var IsSparrow = 'sparrow';
	/**
	 * States that this sprite uses the packer sheet method.
	 */
	var IsPacker = 'packer';
	/**
	 * States that this sprite uses the single image grid system method.
	 */
	var IsGraphic = 'graphic';
	/**
	 * States that this sprite uses the aseprite sheet method.
	 */
	var IsAseprite = 'aseprite';
	#if Animate_Atlas
	/**
	 * States that this sprite uses the animate atlas method.
	 */
	var IsAnimateAtlas = 'animate_atlas';
	#end
	/**
	 * States that this sprite method is unknown.
	 */
	var IsUnknown = 'unknown';

	/**
	 * Gets the file extension from texture type.
	 * @param type The texture type.
	 * @return The file extension.
	 */
	inline public static function getExtFromType(type:TextureType):String {
		return switch (type) {
			case IsSparrow: 'xml';
			case IsPacker: 'txt';
			case IsAseprite: 'json';
			case IsGraphic: 'png';
			#if Animate_Atlas case IsAnimateAtlas: ''; #end
			default: cast IsUnknown;
		}
	}
	/**
	 * Gets the method based on file extension.
	 * @param path The mod path.
	 * @param defaultIsUnknown If default should be recognized as unknown instead of a graphic.
	 * @return The TextureType.
	 */
	inline public static function getTypeFromExt(path:ModPath, defaultIsUnknown:Bool = false):TextureType {
		#if Animate_Atlas
		if (path.path.endsWith('/Animation.json')) return IsAnimateAtlas;
		if (Paths.json(Paths.image(path)).path.endsWith('/Animation.json')) return IsAnimateAtlas;
		#end
		return switch (path.extension) {
			case 'xml': IsSparrow;
			case 'txt': IsPacker;
			case 'json': IsAseprite;
			case 'png': IsGraphic;
			#if Animate_Atlas case null: IsAnimateAtlas; #end
			default: defaultIsUnknown ? IsUnknown : IsGraphic;
		}
	}
}