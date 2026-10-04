package imaginative.backend.systems;

import haxe.Log;
import haxe.PosInfos;

// Make this work more like FlxColor in the future.
enum abstract AnsiColor(String) from String to String {
	var RESET = '\033[0m';
	var WHITE = '\033[38;2;255;255;255m';
	var GRAY = '\033[38;2;128;128;128m';
	var BLACK = '\033[38;2;0;0;0m';

	var GREEN = '\033[38;2;0;128;0m';
	var LIME = '\033[38;2;0;255;0m';
	var YELLOW = '\033[38;2;255;255;0m';
	var ORANGE = '\033[38;2;255;165;0m';
	var RED = '\033[38;2;255;0;0m';
	var PURPLE = '\033[38;2;128;0;128m';
	var BLUE = '\033[38;2;0;0;255m';
	var BROWN = '\033[38;2;139;69;19m';
	var PINK = '\033[38;2;255;192;203m';
	var MAGENTA = '\033[38;2;255;0;255m';
	var CYAN = '\033[38;2;0;255;255m';

	public static final colorList:Map<String, AnsiColor> = flixel.system.macros.FlxMacroUtil.buildMap('imaginative.backend.systems.AnsiColor');

	extern inline public static function format(input:String):String {
		for (name => color in colorList) {
			var temp = ArrayUtil.recycle();
			temp.push(name); temp.push(name.toLowerCase());
			for (name in temp) {
				input = input.replace('#$name', color);
				input = input.replace('$' + name, color);
				input = input.replace('<$name>', color);
			}
			temp.put();
		}
		return input;
	}
}

enum abstract LogLevel(String) {
	var ErrorMessage = 'error';
	var WarningMessage = 'warning';
	var SystemMessage = 'system';
	var DebugMessage = 'debug';
	var LogMessage = 'log';
}

/**
 * An internal enum used for stating where a trace came from.
 */
private enum LogFrom {
	FromSource;
	#if Scripting.Haxe FromHaxe; #end
	#if Scripting.Lua FromLua; #end
	FromUnknown;
}

class Logs {
	static var errorColor:AnsiColor = RED;
	static var warningColor:AnsiColor = YELLOW;
	static var systemColor:AnsiColor = BLUE;
	static var debugColor:AnsiColor = LIME;
	static var logColor:AnsiColor = MAGENTA;

	extern inline static function init():Void {
		Log.trace = (value:Dynamic, ?infos:PosInfos) -> log(value, infos);
		_log('\n					<purple>Initialized Custom Trace System<reset>\n		Thank you for using <yellow>Imaginative Engine<reset>, hope you like it!\n^w^');
	}

	static function formatPosInfos(value:Dynamic, level:LogLevel, ?infos:PosInfos, from:LogFrom = FromSource):String {
		var color:AnsiColor = switch (level) {
			case ErrorMessage: errorColor;
			case WarningMessage: warningColor;
			case SystemMessage: systemColor;
			case DebugMessage: debugColor;
			case LogMessage: logColor;
		}
		var log:String = switch (level) {
			case ErrorMessage: 'Error';
			case WarningMessage: 'Warning';
			case SystemMessage: 'System';
			case DebugMessage: 'Debug';
			case LogMessage: 'Message';
		}

		var info:String = infos == null ? null : '${infos.fileName}:${infos.lineNumber}';
		var who:String = switch (from) {
			case FromSource: '<gray>Source';
			#if Scripting.Haxe case FromHaxe: '<orange>Haxe Script'; #end
			#if Scripting.Lua case FromLua: '<blue>Lua Script'; #end
			default: '<red>Unknown';
		}

		var message:String = value.toStringAdvanced();
		if (infos != null && !infos.customParams.isBlank())
			message += infos.customParams.toStringAdvanced();

		return AnsiColor.format('$color$log <reset>~ ${info.isBlank() ? '' : '$info:'}$color[$who$color]<reset>: $message');
	}

	/**
	 * The engines special *trace* function.
	 * @param value The information you want to pop on to the console.
	 * @param level The level status of the message.
	 * @param from States if script or source logged this.
	 * @param infos The code position information.
	 */
	public static function log(value:Dynamic, level:LogLevel = LogMessage, from:LogFrom = FromSource, ?infos:PosInfos):Void {
		#if debug
		// TODO: Add the funny shit here.
		#end
		Sys.println(formatPosInfos(value, level, infos, from));
	}
	/**
	 * It's just the "log" function but without the file and line in the print.
	 * @param value The information you want to pop on to the console.
	 * @param level The level status of the message.
	 * @param from States if script or source logged this.
	 */
	public static function _log(value:Dynamic, level:LogLevel = SystemMessage, from:LogFrom = FromSource):Void {
		#if debug
		// TODO: Add the funny shit here.
		#end
		Sys.println(formatPosInfos(value, level, null, from));
	}
}