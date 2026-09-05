import haxe.macro.Compiler;
import flixel.FlxState;
import imaginative.backend.states.GameState;
import thx.semver.Version;

class Game extends openfl.display.Sprite {
	/**
	 * The mod that the engine will rely on. This is usually stated as "funkin", aka base game.
	 * When modding support is disabled it becomes the assets folder, like any normal fnf engine... but I'm not normal! 😎 #neurodivergent
	 */
	inline public static final fallbackMod:String = Compiler.getDefine('GeneralAssetFolder');

	/**
	 * The current version of the engine.
	 */
	public static var engineVersion(default, null):Version;
	#if Updateable
	/**
	 * The latest version of the engine.
	 */
	public static var latestVersion(default, null):Version;
	/**
	 * If true, a new update was released for the engine!
	 */
	public static var updateAvailable(default, null):Bool = false;
	#end

	// TODO: Figure out how to do this without creating these variables.
	/**
	 * The initial window width.
	 */
	public static final initialWidth:Int = Std.parseInt(Compiler.getDefine('InitialWidth'));
	/**
	 * The initial window height.
	 */
	public static final initialHeight:Int = Std.parseInt(Compiler.getDefine('InitialHeight'));

	function new() {
		// TODO: Implement crash handler
		#if Tracy_Debugger
		openfl.Lib.current.stage.addEventListener(openfl.events.Event.EXIT_FRAME, _ -> TracyProfiler.frameMark());
		TracyProfiler.messageAppInfo('Imaginative Engine');
		TracyProfiler.setThreadName('main');
		#end

		super();

		// TODO: Add class inits

		engineVersion = lime.app.Application.current.window.application.meta.get('version');
		#if Updateable
		latestVersion = engineVersion;
		// TODO: add update check
		#end

		hxhardware.CPU.init();
		addChild(new flixel.FlxGame(initialWidth, initialHeight, imaginative.states.LaunchScreen, true));
		FlxG.game.focusLostFramerate = 30;
		FlxG.mouse.useSystemCursor = true;
		FlxG.scaleMode = new flixel.system.scaleModes.RatioScaleMode();
		#if !windows FlxG.stage.window.setIcon(lime.graphics.Image.fromFile('icon.png')); #end
	}

	public static var state(get, never):GameState;
	inline static function get_state():GameState {
		if (FlxG.state is GameState)
			return cast FlxG.state;
		return null;
	}

	public static function switchState(nextState:() -> GameState):Void {
		inline function stateCheck(oldState:FlxState, nextState:() -> GameState):FlxState {
			var newState:FlxState = nextState();
			if (oldState is GameState && newState is GameState) {
				var oldConductor:Conductor = cast(oldState, GameState).conductor;
				if (oldConductor == Conductor.song || oldConductor == Conductor.charter)
					oldConductor.pause();
				else if (oldConductor != cast(newState, GameState).conductor)
					oldConductor.stop();
			} else if (oldState is GameState && !(newState is GameState)) {
				var oldConductor:Conductor = cast(oldState, GameState).conductor;
				if (oldConductor == Conductor.song || oldConductor == Conductor.charter)
					oldConductor.pause();
			}
			return newState;
		}

		FlxG.switchState(() -> stateCheck(FlxG.state, nextState));
	}
	public static function resetState():Void {
		if (FlxG.state is GameState) @:privateAccess {
			state.onReset();
			state.conductor.reset();
			var sub:GameState = state.subState is GameState ? cast state.subState : null;
			if (sub != null) {
				sub.conductor.reset();
				sub = sub.subState is GameState ? cast sub.subState : null;
			}
		}
		FlxG.resetState();
	}

	inline public static function reload():Void {
		fullReload();
	}
	inline public static function fullReload():Void {
		#if Modding
		//
		#end
		switchState(() -> new imaginative.states.LaunchScreen());
	}
}