package imaginative.states;

import moonchart.Moonchart;

class LaunchScreen extends GameState {
	@:unreflective static var game_boot:Bool = false;
	static var splash_screen:Bool = false;

	public function new() {
		super(false);
	}

	override function create():Void {
		if (!game_boot) @:privateAccess {
			game_boot = true;
			Logs.init();

			Moonchart.DEFAULT_DIFF = 'normal';
			Moonchart.init();

			Conductor.init();
			Assets.init();
			// Settings.init();
			Controls.init();
			Script.init();

			FlxG.fixedTimestep = false;
			flixel.FlxSprite.defaultAntialiasing = true; // this ain't a pixel game... yeah ik week 6 exists!
			FlxG.signals.preStateCreate.add(state -> {
				ArrayUtil._pool.pool.clear();
				cpp.vm.Gc.run(false);
				cpp.vm.Gc.compact();
				Game.state.preCreate();
			});
			FlxG.signals.preStateSwitch.add(() -> @:privateAccess {
				function getName(lol:flixel.util.typeLimit.NextState):Null<String> {
					return switch (lol) {
						case cls if (cls is Class): cls.getClassName(false);
						case state if (state is GameState): cast(state, GameState).id;
						case state if (state is flixel.FlxState): state.getClassName(false);
						case func if (Reflect.isFunction(func)): getName(cast func.getConstructor()());
						default: null;
					}
				}

				var stateName = getName(FlxG.game._nextState); _log('State: "$stateName"', DebugMessage);
				/* if (stateName != 'LaunchScreen' && Game.stateRedirects.exists(stateName)) {
					var classResolve = Type.resolveClass(Game.stateRedirects.get(stateName));
					FlxG.game._nextState = classResolve != null ? Type.createInstance(classResolve, ArrayUtil.recycle()) : new ModdedState(Game.stateRedirects.get(stateName));
				} */
			});
			FlxG.signals.postUpdate.add(() -> {
				if (Controls.global.resetState) {
					try {
						_log('Reseting state...');
						Game.resetState();
						_log('State reset successful!');
					} catch(error:haxe.Exception)
						_log('State reset failed. (error: "${error.message}")', ErrorMessage);
				}
				if (Controls.global.quickState) {
					try {
						_log('Heading to the MainMenu...');
						Game.switchState(() -> new imaginative.states.menus.MainMenu());
						_log('Successfully entered the MainMenu!');
					} catch(error:haxe.Exception)
						_log('Failed to enter the MainMenu. (error: "${error.message}")', ErrorMessage);
				}
				if (Controls.global.reloadGame) {
					try {
						_log('Reloading the game...');
						Game.reload();
						_log('Reload successfully!');
					} catch(error:haxe.Exception)
						_log('Reload failed. (error: "${error.message}")', ErrorMessage);
				}
			});
		} else Assets.clearContent();
		super.create();
		#if Updateable
		if (Game.updateAvailable) {
			openSubState(new UpdateScreen());
			return;
		}
		#end
		if (!splash_screen) {
			splash_screen = true;

			var logo = new BaseSprite('root:watermarks/static-logo');
			logo.screenCenter();
			logo.alpha = 0;
			logo.y -= 30;
			add(logo);

			var text = new BaseSprite('root:watermarks/engine-text');
			text.screenCenter();
			text.alpha = 0;
			text.y += 200 - 30;
			add(text);

			FlxTween.tween(logo, {alpha: 1}, 1, {ease: FlxEase.cubeOut});
			FlxTween.tween(text, {alpha: 1}, 1, {ease: FlxEase.cubeOut});

			// TODO: once settings state is coded, do first time game launch stuff
			FlxG.sound.play(Assets.sound('gameovers/retry', true, true), 0.5, () -> {
				Game.switchState(() -> new TitleScreen());
			});
		} else Game.switchState(() -> new TitleScreen());
	}
}

#if Updateable
class UpdateScreen extends GameState {
	//
}
#end