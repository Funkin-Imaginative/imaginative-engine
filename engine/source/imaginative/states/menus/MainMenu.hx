package imaginative.states.menus;

import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

class MainMenu extends GameState {
	var itemList:Array<String> = [];
	var itemData:Array<MenuNavData> = [
		{
			id: 'storymode',
			selectedFunc: () -> Game.switchState(() -> new StoryMenu())
		},
		{
			id: 'freeplay',
			selectedFunc: () -> Game.switchState(() -> new FreeplayMenu())
		},
		{
			id: 'options',
			selectedFunc: () -> {
				cast(Game.state, MainMenu).menuItems.setCooldown(0.4); // extend cooldown
				Conductor.menu.fadeOut(0.4, _ -> Game.switchState(() -> new OptionsMenu()));
			}
		},
		{
			id: 'credits',
			selectedFunc: () -> {
				cast(Game.state, MainMenu).menuItems.setCooldown(0.4); // extend cooldown
				Conductor.menu.fadeOut(0.4, _ -> Game.switchState(() -> new CreditsMenu()));
			}
		},
		{
			id: 'donate',
			selectedFunc: () -> PlatformUtil.openURL('https://ninja-muffin24.itch.io/funkin/purchase')
		},
		{
			id: 'kickstarter',
			selectedFunc: () -> PlatformUtil.openURL('https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game')
		},
		{
			id: 'merch',
			selectedFunc: () -> PlatformUtil.openURL('https://needlejuicerecords.com/pages/friday-night-funkin')
		}
	];

	var bg:MenuSprite;
	var menuItems:MenuNavigator;

	var camPoint:FlxObject;
	@:unreflective var highestY:Float = 0;
	@:unreflective var lowestY:Float = 0;

	override function preCreate():Void {
		super.preCreate();
		var lePath = Paths.image('menus/main');
		var lol = Paths.readFolder(lePath.applyExt(), new imaginative.backend.data.StringedArray(',', 'xml'));
		for (file in lol)
			itemList.push(file.file.getSlice('/', file.file.getSliceCount('/') - 1));
		itemList.sortByList(Assets.text(Paths.txt(lePath + 'order'), true).trimSplit('\n'));
		lol.clear();
	}
	override function create():Void {
		if (!conductor.playing) {
			conductor.loadMusic('freakyMenu');
			conductor.fadeIn(4, 0.7);
		}

		super.create();

		stateCamera.follow(camPoint = new FlxObject(0, 0, 1, 1), 0.2);
		add(camPoint);

		bg = new MenuSprite();
		bg.scrollFactor.set();
		bg.updateScale(1.2);
		bg.screenCenter();
		bgColor = bg.blankBg.color;
		add(bg);

		menuItems = new MenuNavigator(id, false);
		menuItems.generateItems(
			[for (id in itemList) itemData.find(data -> data.id == id)],
			(index, group) -> {
				var id = group.itemId;
				if (!Paths.spritesheetExists('menus/main/$id'))
					return false;

				// TODO: Eventually switch to object jsons. Use script event call for people to able to do their own thing if need be.
				var item:BaseSprite = new BaseSprite(0, 0, 'menus/main/$id');
				item.addAnimation('idle', '$id idle', true);
				item.addAnimation('selected', '$id selected', true);
				item.animation.onPlay.add((_, _, _, _) -> {
					item.centerOffsets();
					item.centerOrigin();
				});
				item.playAnimation('idle');
				group.extra.set('item', item);
				group.add(item);

				group._isLocked = value -> {
					item.color = FlxColor.WHITE;
					if (value) item.color -= 0xFF646464;
				}
				group._canSelect = (value:Bool) ->
					item.alpha = value ? 1 : 0.5;
				switch (id) {
					case 'donate' | 'kickstarter' | 'merch':
						group.canSelect = false;
					case 'credits':
						group.isLocked = true;
				}

				group.onChange = () -> item.playAnimation('selected');
				group.onDeselect = () -> item.playAnimation('idle');

				group.screenCenter(X);
				group.y = 60 + (index * 160);
				return true;
			}
		);
		menuItems.addLogs();
		add(menuItems);

		if (!menuItems.isEmpty()) {
			var highMid:FlxPoint = menuItems.members[0].getMidpoint();
			var lowMid:FlxPoint = menuItems.members[menuItems.length - 1].getMidpoint();

			var range = FlxMath.remapToRange(menuItems.currentView, 0, menuItems.length - 1, 0, 1);
			bg.y = MathUtil.lerp(0, FlxG.height - bg.height, range);
			camPoint.setPosition(
				MathUtil.lerp(highMid.x, lowMid.x, range),
				MathUtil.lerp(highestY = highMid.y, lowestY = lowMid.y, range)
			);
			highMid.put(); lowMid.put();
			stateCamera.snapToTarget();
			menuItems.initSelection();
		}
	}

	override function update(delta:Float):Void {
		if (conductor.volume < 0.8)
			conductor.volume += 0.5 * delta;
		super.update(delta);

		if (Controls.global.back && (menuItems.isEmpty() ? true : menuItems.allowSelect)) {
			FlxG.sound.play(Assets.sound('menus/cancel', true, false, true), 0.7).persist = true;
			Game.switchState(() -> new TitleScreen());
		}

		var range:Float = FlxMath.remapToRange(menuItems.currentView, 0, menuItems.length - 1, 0, 1);
		camPoint.y = FlxMath.lerp(highestY, lowestY, range);
		bg.y = MathUtil.lerp(bg.y, MathUtil.lerp(0, FlxG.height - bg.height, range), 0.16, delta);
	}
}