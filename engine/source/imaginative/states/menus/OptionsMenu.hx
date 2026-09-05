package imaginative.states.menus;

class OptionsMenu extends GameState {
	public function new(?func:Void -> Void) {
		super();
		exitMenu = func ?? () -> if (isSubState) close();
	}

	/**
	 * Running this function makes you leave the options menu.
	 *
	 * What it does is determined by the new constructor.
	 */
	public dynamic function exitMenu():Void {}
}