package imaginative.backend.utils;

class PlatformUtil {
	/**
	 * Opens a URL in your browser.
	 * @param url The url.
	 */
	public static function openURL(url:String):Void {
		#if linux // taken from cne
		// generally `xdg-open` should work in every distro
		var cmd = Sys.command('xdg-open', [url]);
		// run old command JUST IN CASE it fails, which it shouldn't
		if (cmd != 0) cmd = Sys.command('/usr/bin/xdg-open', [url]);
		#else
		FlxG.openURL(url);
		#end
		trace('Opening url. (link: $url)');
	}
}