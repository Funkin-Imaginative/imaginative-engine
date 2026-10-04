package imaginative.backend.systems.events;

import flixel.util.FlxDestroyUtil;

@:build(imaginative.backend.macro.CallableEventMacro.build())
@:autoBuild(imaginative.backend.macro.CallableEventMacro.build())
class CallableEvent implements IFlxDestroyable {
	/**
	 * If true, whatever this event does gets cancelled.
	 */
	@:hidden public var cancelled:Bool = false;
	/**
	 * If true, it will stop whatever for loop is calling upon this event.
	 */
	@:hidden public var breakLoop:Bool = false;

	/**
	 * Just sets "cancelled" to true.
	 */
	inline public function stop():Void
		cancelled = true;
	/**
	 * Has the power to make the loop come to a halt.
	 */
	inline public function halt():Void
		cancelled = breakLoop = true;

	public function new() {
		_log('Initalized ${toString()}');
	}

	public function _recycle():Void
		cancelled = breakLoop = false;

	public function destroy():Void {}

	public function toString():String
		return 'CallableEvent(cancelled: $cancelled, breakLoop: $breakLoop)';
}