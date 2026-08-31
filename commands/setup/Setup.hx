package setup;

import haxe.Json;
import haxe.iterators.DynamicAccessIterator;
import haxe.iterators.DynamicAccessKeyValueIterator;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import Main.PlatformTarget;

using StringTools;

typedef SetupJson = ReflectMap<String, Library>;
typedef Library = {
	var ?version:String;
	var ?branch:String;
	var ?url:String;
	var ?dependencies:SetupJson;
	var ?dev:Bool;
	var ?checks:LibCheck;
}
typedef LibCheck = {
	var ?target:PlatformTarget;
	var ?optional:Bool;
	var ?debug:Bool;
}

class Setup {
	static var data:SetupJson;
	static var optionalLibs:Array<String> = [];
	static var libsToInstall:Map<String, Bool> = new Map<String, Bool>();

	inline public static function run(ranArgs:Array<String>):Void {
		// arguments
		var args:Array<String> = ranArgs;

		// json parse
		Sys.println('Getting libraries from "commands/setup/data.json"');
		if (FileSystem.exists('commands/setup/data.json')) {
			data = Json.parse(File.getContent('commands/setup/data.json'));
			function recursion(data:SetupJson) {
				for (name => lib in data) {
					lib.dev ??= false;
					lib.checks ??= {
						target: Main.getTarget(true),
						optional: false,
						debug: false
					}
					lib.checks.target ??= Main.getTarget(true);
					lib.checks.optional ??= false;
					lib.checks.debug ??= false;

					if (lib.dependencies.length != 0)
						recursion(lib.dependencies);
				}
			}
			recursion(data);
		} else {
			var exampleJson:SetupJson = {
				'hxcpp-debug-server': {
					version: 'git',
					branch: '7459934666a473a4cc4d066ba4a93ef92f1ce94c',
					url: 'https://github.com/FunkinCrew/hxcpp-debugger',
					dev: true,
					checks: { debug: true }
				},
				hxWindowColorMode: {
					checks: { target: WINDOWS }
				},
				hxvlc: {
					version: '2.2.5',
					dependencies: {}
				}
			}
			// was hating github not properly coloring the rest of this file.
			Sys.println('The libraries json doesn\'t exist!\nPlease make one in the setup folder.\nHere\'s an example of one.\n${Json.stringify(exampleJson, '\t')}');
			return;
		}

		function recursion(data:SetupJson) {
			for (name => lib in data) {
				libsToInstall.set(name, false);
				if (lib.checks.target == Main.getTarget(true)) {
					if (lib.checks.optional) optionalLibs.push(name);
					else libsToInstall.set(name, true);

					if (lib.dependencies.length != 0)
						recursion(lib.dependencies);
				}
			}
		}
		recursion(data);

		Sys.println(Main.dashes);

		if (args.contains('--always')) { // When "--always" is used, it installs all the libs.
			Sys.println('Skipping questions.');
			for (name in optionalLibs)
				libsToInstall.set(name, true);
		} else {
			Sys.println('Please answer carefully.');
			for (name in optionalLibs)
				if (!libsToInstall.get(name)) {
					Sys.println('Do you wish to install $name? [y/n]');
					if (Sys.stdin().readLine().toLowerCase().trim() == 'y')
						libsToInstall.set(name, true);
				}
		}

		if (!FileSystem.exists('.haxelib'))
			FileSystem.createDirectory('.haxelib');
		Sys.println(Main.dashes);

		Sys.command('haxelib install haxelib --global --always');
		Sys.command('haxelib fixrepo');
		Sys.println(Main.dashes);
		dependenciesCheck(data);
		File.saveContent('commands/setup/history.txt', libHistory.join('\n'));
		Sys.println('Finished installing libraries.\n\nYou can check the history of installed libraries in "commands/setup/history.txt".');

		var proc:Process = new Process('haxe --version');
		proc.exitCode(true);
		var haxeVer:String = proc.stdout.readLine().toLowerCase().trim();
		if (haxeVer != '4.3.7') {
			// check for outdated haxe
			var curHaxeVer:Array<Int> = [
				for (v in haxeVer.split('.'))
					Std.parseInt(v)
			];
			var requiredHaxeVer:Array<Int> = [4, 3, 7];
			for (i in 0...requiredHaxeVer.length) {
				if (curHaxeVer[i] < requiredHaxeVer[i]) {
					Sys.println(Main.dashes);
					Sys.println('Your current Haxe version is outdated.');
					Sys.println('You\'re using $haxeVer, while the required version is 4.3.7.');
					Sys.println('The engine may or may not compile with your current version of Haxe.');
					Sys.println('We recommend upgrading to 4.3.7!');
					break;
				}
			}
		}

		// This part here was taken from Codename Engine's commandline stuff.
		if (Main.getTarget() == WINDOWS && new Process('"C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe" -property catalog_productDisplayVersion').exitCode(true) == 1) {
			Sys.println(Main.dashes);
			Sys.println('Installing Microsoft Visual Studio Community (Dependency)');

			Sys.command('curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe');
			Sys.command('vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p');

			FileSystem.deleteFile('vs_Community.exe');
			Sys.println('If it didn\'t say it before: Because of this component if you want to compile you have to restart the device.');
			Sys.println(Main.dashes);
			Sys.println('Do you wish to do it now? [y/n]');
			if (Sys.stdin().readLine().toLowerCase().trim() == 'y') Sys.command('shutdown /r /t 0 /f');
		}
	}

	static var libHistory:Array<String> = [];
	static function dependenciesCheck(dependencies:SetupJson, doneAgain:Bool = false):Void {
		inline function commandCheck(command:Array<String>):String {
			var filtered = command.filter((string:String) -> return string.trim().length != 0);
			command.resize(0);
			var result = filtered.join(' ');
			filtered.resize(0);
			return result;
		}

		for (name => lib in dependencies) {
			if (!libsToInstall.get(name)) continue;

			if (lib.version == 'git') {
				var repo:Array<String> = lib.url.split('/');
				Sys.println('Installing "$name" from git repo "${repo[repo.length - 2]}/${repo[repo.length - 1]}".');
				repo.resize(0);

				var command = commandCheck(['haxelib', 'git', name, lib.url ?? '', lib.branch ?? '', lib.dependencies == null ? '' : '--skip-dependencies']);
				Sys.command('$command --always');
				libHistory.push(command);

				if (lib.dev) {
					var command = commandCheck(['haxelib', 'dev', name, '".haxelib/${name.replace('.', ',')}/${File.getContent('.haxelib/${name.replace('.', ',')}/.current').trim().replace('.', ',')}/${name.replace('.', ',')}"']);
					Sys.command(command);
					libHistory.push(command);
				}
			} else {
				Sys.println('Installing "$name".');
				var command = commandCheck(['haxelib', 'install', name, lib.version ?? '', lib.dependencies == null ? '' : '--skip-dependencies']);
				Sys.command('$command --always');
				libHistory.push(command); // TODO: Figure out how to get lib version when none specified.

				if (lib.dev) {
					var command = commandCheck(['haxelib', 'dev', name, '".haxelib/${name.replace('.', ',')}/${File.getContent('.haxelib/${name.replace('.', ',')}/.current').trim().replace('.', ',')}/${name.replace('.', ',')}"']);
					Sys.command(command);
					libHistory.push(command);
				}
			}
			if (lib.dependencies.length != 0) dependenciesCheck(lib.dependencies, true);
			if (!doneAgain) Sys.println(Main.dashes);
		}
	}
}

abstract ReflectMap<K, V>(Dynamic<V>) from Dynamic<V> to Dynamic<V> {
	public var length(get, never):Int;
	inline function get_length():Int {
		var lol = keys();
		var l = lol.length;
		lol.resize(0);
		return l;
	}

	inline public function new()
		this = {}

	@:arrayAccess inline public function get(key:K):Null<V>
		return Reflect.field(this, Std.string(key));
	@:arrayAccess inline public function set(key:K, value:V):V {
		Reflect.setField(this, Std.string(key), value);
		return value;
	}

	inline public function exists(key:K):Bool
		return Reflect.hasField(this, Std.string(key));
	inline public function remove(key:K):Bool
		return Reflect.deleteField(this, Std.string(key));

	inline public function keys():Array<String>
		return Reflect.fields(this);
	inline public function copy():ReflectMap<K, V>
		return Reflect.copy(this);

	inline public function iterator():DynamicAccessIterator<V> {
		return new DynamicAccessIterator<V>(this);
	}
	inline public function keyValueIterator():DynamicAccessKeyValueIterator<V> {
		return new DynamicAccessKeyValueIterator<V>(this);
	}
}
