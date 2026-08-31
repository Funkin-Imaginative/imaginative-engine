package imaginative.states.menus;

import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

class MainMenu extends GameState {
	var bg:MenuSprite;
	var menuItems:MenuNavigator;

	var camPoint:FlxObject;
	@:unreflective var highestY:Float = 0;
	@:unreflective var lowestY:Float = 0;

	override function create():Void {
		if (!conductor.playing) {
			conductor.loadMusic('freakyMenu');
			conductor.fadeIn(4, 0.7);
		}

		super.create();

		stateCamera.follow(camPoint = new FlxObject(0, 0, 1, 1), 0.2);
		add(camPoint);

		bg = new MenuSprite();
		bgColor = bg.blankBg.color;
		bg.scrollFactor.set();
		bg.updateScale(1.2);
		bg.screenCenter();
		add(bg);

		menuItems = new MenuNavigator(id, false);
		add(menuItems);

		if (!menuItems.isEmpty()) {
			var highMid:FlxPoint = menuItems.members[0].getMidpoint();
			var lowMid:FlxPoint = menuItems.members[menuItems.length - 1].getMidpoint();

			var range = FlxMath.remapToRange(menuItems.currentView, 0, menuItems.length - 1, 0, 1);
			bg.y = FlxMath.lerp(0, FlxG.height - bg.height, range);
			camPoint.setPosition(
				FlxMath.lerp(highMid.x, lowMid.x, range),
				FlxMath.lerp(highestY = highMid.y, lowestY = lowMid.y, range)
			);
			stateCamera.snapToTarget();
			menuItems.initSelection();
		}
	}

	override function update(delta:Float):Void {
		if (conductor.volume < 0.8)
			conductor.volume += 0.5 * delta;
		super.update(delta);

		if (Controls.global.back && (menuItems.isEmpty() ? true : menuItems.allowSelect)) {
			Game.switchState(() -> new TitleScreen());
		}

		var range:Float = FlxMath.remapToRange(menuItems.currentView, 0, menuItems.length - 1, 0, 1);
		camPoint.y = FlxMath.lerp(highestY, lowestY, range);
		bg.y = MathUtil.lerp(bg.y, FlxMath.lerp(0, FlxG.height - bg.height, range), 0.16, delta);
	}
}