package imaginative.backend.systems.events;

import flixel.util.FlxDestroyUtil;

@:build(imaginative.backend.macro.CallableEventMacro.build())
@:autoBuild(imaginative.backend.macro.CallableEventMacro.build())
class CallableEvent implements IFlxDestroyable {
	/**
	 * If true, whatever this event does gets cancelled.
	 */
	@:ignore public var cancelled:Bool = false;
	/**
	 * If false, it will stop whatever for loop is calling upon this event.
	 */
	@:ignore public var breakLoop:Bool = true;

	/**
	 * Just sets "cancelled" to true.
	 */
	inline public function stop():Void
		cancelled = true;
	/**
	 * Has the power to make the loop come to a halt.
	 */
	inline public function halt():Void {
		cancelled = true;
		breakLoop = false;
	}

	public function new() {}

	public function _recycle():Void {
		cancelled = false;
		breakLoop = true;
	}

	public function destroy():Void {
		//
	}
}