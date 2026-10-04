package imaginative.backend.systems.events.callables.sprites;

class PlayAnimationEvent extends CallableEvent {
	/**
	 * The animation name.
	 */
	public var name:String;
	/**
	 * If true, it forces the animation to play.
	 */
	public var force:Bool = true;
	/**
	 * The animation context.
	 */
	public var context:AnimationContext = Unclear;
	/**
	 * If true, the animation will play in reverse.
	 */
	public var reverse:Bool = false;
	/**
	 * The frame for the animation to start at.
	 */
	public var frame:Int = 0;

	/**
	 * If false, it won't slowly prune each dashed suffix in the "name" variable.
	 */
	@:hidden public var doSuffixChecks:Bool = true;

	override function toString():String
		return 'PlayAnimationEvent(name: "${name.ifBlankReplace('')}", force: $force, context: ${context.debugString()}, reverse: $reverse, frame: $frame)';
}