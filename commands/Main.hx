import compile.Compile;
import setup.Setup;

using StringTools;

typedef Command = {
	var names:Array<String>;
	var func:Array<String> -> Void;
	var ?description:String;
	var ?elaboration:String;
}

enum abstract PlatformTarget(String) from String to String {
	var WINDOWS = 'windows';
	var MAC = 'mac';
	var LINUX = 'linux';
	var ANDROID = 'android';
	var IOS = 'ios';
	var UNKNOWN = 'unknown';
	var CPP = 'cpp';
}

class Main {
	inline public static final dashes:String = '-------------------------------------------------------------------------------';

	public static var commands:Array<Command> = [
		{
			names: ['help', null],
			func: help,
			description: 'Tells you how things work. Put a command name for extra info on it (if it has any).'
		},
		{
			names: ['setup'],
			func: Setup.run,
			description: 'Installs / Updates libraries needed for the engine to run.'
		},
		{
			names: ['compile'],
			func: Compile.run,
			description: 'Compiles the engine.'
		}
	];

	public static function main():Void {
		var args:Array<String> = Sys.args();
		var commandName:String = args.shift()?.toLowerCase();
		for (command in commands) {
			if (command.names.contains(commandName)) {
				command.func(args);
				break;
			}
		}
	}

	public static function help(args:Array<String>):Void {
		Sys.println('does nothing for now');
	}

	inline public static function getTarget(useFile:Bool = false):PlatformTarget {
		if (useFile && sys.FileSystem.exists('commands/compile/platform.txt')) {
			var platform:String = sys.io.File.getContent('commands/compile/platform.txt').toLowerCase().trim();
			return switch (platform) {
				case 'macos': MAC;
				default: platform;
			}
		}
		return switch (Sys.systemName().toLowerCase()) {
			case 'windows': WINDOWS;
			case 'mac': MAC;
			case 'linux': LINUX;
			default: UNKNOWN;
		}
	}
}