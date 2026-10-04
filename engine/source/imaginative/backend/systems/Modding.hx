package imaginative.backend.systems;

#if Modding
class Modding {
	/**
	 * The **current master** mod.
	 */
	public static var masterMod(default, null):Null<String> = null;
	/**
	 * The **current module** mod.
	 */
	public static var moduleMod:Null<String> = null;

	/**
	 * **Active module** mods.
	 */
	public static var moduleList:Array<String> = [];

	/**
	 * If true, the current master mod is the engines fallback mod.
	 */
	public static var masterIsFallback(get, never):Bool;
	@:noCompletion inline static function get_masterIsFallback():Bool
		return masterMod == Game.fallbackMod;

	/**
	 * Prepends lower end mod folder name.
	 * @param modPath The mod path to the item your looking for.
	 * @return The finalized path.
	 */
	public static function getModsRoot(modPath:String):String {
		var mods:Array<String> = moduleList.copy();
		if (!curMod.isBlank()) mods.push(curMod);

		for (mod in mods) {
			var asset:ModPath = new ModPath('modules/$mod/$modPath', ROOT);
			if (asset.isFile) return asset.path;
		}
		mods.put();
		return modPath;
	}

	/**
	 * Gets the path of a file from all mods under the mod type.
	 * @param path The mod path.
	 * @param includeAllActiveModules If false, it excludes module mods that isn't the current one.
	 * @return The filtered paths.
	 */
	public static function getAllInstancesOfFile(path:ModPath, includeAllActiveModules:Bool = false):Array<ModPath> {
		return ArrayUtil.recycle(); // TODO: actually write this
	}
}
#end