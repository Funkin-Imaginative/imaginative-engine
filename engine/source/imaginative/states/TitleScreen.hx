package imaginative.states;

class TitleScreen extends GameState {
	static var played_intro:Bool = false;

	override function create():Void {
		if (!conductor.playing) {
			conductor.loadMusic('freakyMenu');
			conductor.fadeIn(4, 0.7);
		}

		var logo = new BeatSprite(-150, -100, 'menus/title/logoBumpin').setupDance(MEASURE);
		logo.addAnimation('idle', 'logo bumpin');
		add(logo);

		var gf = new BeatSprite(camera.width * 0.4, camera.height * 0.07, 'menus/title/gfDanceTitle').setupDance(1);
		// gf.addAnimation('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]);
		// gf.addAnimation('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]);
		gf.addAnimation('idle', 'gfDance');
		gf.playAnimation('idle');
		add(gf);

		var text = new BaseSprite(100, camera.height * 0.8, 'menus/title/titleEnter');
		text.addAnimation('idle', 'Press Enter to Begin', true);
		text.addAnimation('press', 'ENTER PRESSED', true);
		text.playAnimation('idle');
		add(text);

		super.create();
	}
}