package imaginative.states;

import flixel.FlxCamera;
import flixel.text.FlxText;

typedef IntroTextData = {
	var intro:Array<{
		var beat:Int;
		var ?text:String;
		var ?image:ModPath;
	}>;
	var length:Int;
	var texts:Array<Array<String>>;
}

class TitleScreen extends GameState {
	static var played_intro:Bool = false;
	var transitioning:Bool = false;

	var fnfLogo:BeatSprite;
	var menuGraphic:BeatSprite;
	var beginText:BaseSprite;

	var textCamera:FlxCamera;
	var introImage:BaseSprite;
	var introText:FlxText;

	static var introTextData:IntroTextData;

	@:unreflective static final _intro_entry:Array<String> = [];
	static function getIntroEntry(reload:Bool = false):Array<String> {
		if (reload || _intro_entry.empty()) {
			_intro_entry.clear();
			_intro_entry.merge(FlxG.random.getObject(introTextData.texts));
		}
		return _intro_entry;
	}

	function stopIntro(isSkip:Bool = false):Void {
		played_intro = true;
		textCamera.visible = false;
		if (isSkip) camera.flash(FlxColor.WHITE, 4);
	}

	override function create():Void {
		if (!conductor.playing) {
			conductor.loadMusic('freakyMenu');
			conductor.fadeIn(4, 0.7);
		}

		fnfLogo = new BeatSprite(-10, 'menus/title/logoBumpin').setupDance(2);
		fnfLogo.addAnimation('dance', 'logo bumpin');
		fnfLogo.scale.scale(0.9);
		add(fnfLogo);

		menuGraphic = new BeatSprite(520, 40, 'menus/title/gfDanceTitle').setupDance(1);
		menuGraphic.addAnimation('dance', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]);
		menuGraphic.addAnimation('dance1', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]);
		add(menuGraphic);

		beginText = new BaseSprite(0, 550, 'menus/title/titleEnter');
		beginText.addAnimation('idle', 'Press Enter to Begin', true);
		beginText.addAnimation('enter', 'ENTER PRESSED', 24 / 1.5, true);
		beginText.playAnimation('idle');
		beginText.screenCenter(X);
		add(beginText);

		textCamera = new FlxCamera();
		FlxG.cameras.add(textCamera, false);
		textCamera.bgColor = FlxColor.BLACK;

		introImage = new BaseSprite('main:menus/title/newgrounds');
		introImage.cameras = [textCamera];
		introImage.visible = false;
		add(introImage);

		introText = new FlxText(0, 160, FlxG.width * 5);
		introText.setFormat(Paths.font('vcr').format(), 50, CENTER);
		introText.cameras = [textCamera];
		introText.screenCenter(X);
		add(introText);

		introTextData = Assets.json('data/introText', true);
		for (data in introTextData.intro)
			if (data.image.isFile) // preloads all images
				Assets.image(data.image, true);
		if (played_intro || introTextData == null)
			stopIntro();

		super.create();
	}

	override function update(delta:Float):Void {
		super.update(delta);

		if (Controls.global.accept && !transitioning) {
			if (played_intro) {
				transitioning = true;
				camera.flash(true);
				beginText.playAnimation('enter');
				FlxTween.tween(beginText, {alpha: 0}, 0.5, {ease: FlxEase.cubeIn, startDelay: 0.5});
				FlxG.sound.play(Assets.sound('menus/confirm', true, false, true), 0.7, () -> Game.switchState(() -> new imaginative.states.menus.MainMenu()));
			} else stopIntro(true);
		}
	}

	override function beatHit(beat:Int, target:Conductor):Void {
		super.beatHit(beat, target);
		_introHandler(beat);
	}

	extern inline function _introHandler(tick:Int):Void {
		if (!played_intro) {
			if (tick >= introTextData.length)
				stopIntro(true);
			else {
				var data = introTextData.intro.find(data -> data.beat == tick);
				if (data != null) {
					var imageAsset:ModPath = data.image;
					if (data.text != null) {
						introText.text = '';
						for (i => text in data.text.iterateSlicesKV('\n')) {
							if (text == '{INTRO_TEXT}')
								introText.text += getIntroEntry()[i] + '\n';
							else introText.text += '$text\n';
						}
					}
					if (!Paths.image(imageAsset).isFile) {
						imageAsset = switch (introText.text.toLowerCase()) {
							case text if (text.contains('newgrounds')): 'main:menus/title/newgrounds';
							case text if (text.contains('imaginative')): 'root:watermarks/static-logo';
							default: '';
						}
					}
					if (introImage.visible = Paths.image(imageAsset).isFile) {
						introImage.loadImage(imageAsset);
						introImage.setGraphicScale(350);
						introImage.updateHitbox();
						introImage.screenCenter();
						introImage.y += 90;
					}
				}
			}
		}
	}
}