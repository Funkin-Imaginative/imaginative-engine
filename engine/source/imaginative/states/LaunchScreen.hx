package imaginative.states;

import moonchart.Moonchart;

class LaunchScreen extends GameState {
	@:unreflective static var game_boot:Bool = false;
	static var splash_screen:Bool = false;

	override function create():Void {
		if (!game_boot) @:privateAccess {
			game_boot = true;

			Moonchart.DEFAULT_DIFF = 'normal';
			Moonchart.init();

			Conductor.init();
			Assets.init();
			// Settings.init();
			Controls.init();

			FlxG.fixedTimestep = false;
			flixel.FlxSprite.defaultAntialiasing = true; // this ain't a pixel game... yeah ik week 6 exists!
			FlxG.signals.preStateCreate.add(state -> Game.state.preCreate());
			/* FlxG.signals.preStateSwitch.add(() -> @:privateAccess {
				function getName(lol:flixel.util.typeLimit.NextState):String {
					return switch (lol) {
						case _class if (_class is Class):
							// trace('class');
							var lol = Type.getClassName(cast _class);
							lol.getSlice('.', lol.getSliceCount('.') - 1);
						case state if (state is GameState):
							// trace('game');
							cast(state, GameState).id;
						case state if (state is flixel.FlxState):
							// trace('base');
							var lol = Type.getClassName(Type.getClass(state));
							lol.getSlice('.', lol.getSliceCount('.') - 1);
						case func if (Reflect.isFunction(func)):
							// trace('func');
							getName(cast func.getConstructor()());
						default: null;
					}
				}

				var stateName = getName(FlxG.game._nextState);
				trace(stateName);
				if (Game.stateRedirects.exists(stateName)) {
					var classResolve = Type.resolveClass(Game.stateRedirects.get(stateName));
					FlxG.game._nextState = classResolve != null ? Type.createInstance(classResolve, []) : new ModdedState(Game.stateRedirects.get(stateName));
				}
			}); */
		}
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
		} // else
	}
}

#if Updateable
class UpdateScreen extends GameState {
	//
}
#end