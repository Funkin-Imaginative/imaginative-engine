package imaginative.states.menus;

class MainMenu extends GameState {
	override function create():Void {
		if (!conductor.playing) {
			conductor.loadMusic('freakyMenu');
			conductor.fadeIn(4, 0.7);
		}

		super.create();
	}
}