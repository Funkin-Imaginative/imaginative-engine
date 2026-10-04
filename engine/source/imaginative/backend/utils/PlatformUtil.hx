package imaginative.backend.utils;

class PlatformUtil {
	/**
	 * Opens a URL in your browser.
	 * @param url The url.
	 */
	inline public static function openURL(url:String):Void {
		#if linux // taken from cne
		var temp = ArrayUtil.recycle(); temp.push(url);
		// generally `xdg-open` should work in every distro
		var cmd = Sys.command('xdg-open', temp);
		// run old command JUST IN CASE it fails, which it shouldn't
		if (cmd != 0) cmd = Sys.command('/usr/bin/xdg-open', temp);
		temp.put();
		#else
		FlxG.openURL(url);
		#end
		_log('[PlatformUtil.openURL] Opening url. (link: $url)', DebugMessage);
	}
}