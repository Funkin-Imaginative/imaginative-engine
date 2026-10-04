package imaginative.backend.systems.events.callables;

class ResizeEvent extends CallableEvent {
	/**
	 * The new width.
	 */
	public var width:Int;
	/**
	 * The new height.
	 */
	public var height:Int;

	/**
	 * The old width. **Can be null.**
	 */
	 public var oldWidth:Null<Int> = null;
	/**
	 * The old height. **Can be null.**
	 */
	public var oldHeight:Null<Int> = null;

	override function toString():String
		return 'ResizeEvent(width: $width, height: $height, oldWidth: $oldWidth, oldHeight: $oldHeight)';
}