package imaginative.backend.systems.events.callables;

import imaginative.backend.states.GameState;

class StateEvent extends CallableEvent {
	/**
	 * The game state that is opening or closing.
	 */
	public var state:GameState;

	override function toString():String
		return 'StateEvent(state: ${state.id})';
}