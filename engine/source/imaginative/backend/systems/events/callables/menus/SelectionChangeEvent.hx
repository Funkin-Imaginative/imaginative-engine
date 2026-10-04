package imaginative.backend.systems.events.callables.menus;

class SelectionChangeEvent extends MenuSFXEvent {
	/**
	 * The value before the change.
	 */
	public var previousValue:Int;
	/**
	 * The value after the change.
	 */
	public var currentValue:Int;

	/**
	 * The amount of change between the **previousValue** and the **currentValue**.
	 */
	public var changeAmount(get, never):Int;
	inline function get_changeAmount():Int {
		if (currentValue == -1) return 0;
		return currentValue - previousValue;
	}
	/**
	 * States if the amount of change between the **previousValue** and the **currentValue** is unchanged.
	 */
	public var noChange(get, never):Bool;
	inline function get_noChange():Bool
		return changeAmount == 0;

	override function toString():String
		return 'SelectionChangeEvent(previousValue: $previousValue, currentValue: $currentValue)';
}