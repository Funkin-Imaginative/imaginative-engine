package imaginative.backend.scripting;

/**
 * Wrapper to use Script and ScriptGroup instances in the same variable when editing source.
 */
@:forward(
	// script related
	type, priorityIndex,
	parent, init,
	set, get,
	call, event,
	terminated,
	// object related
	destroy
)
abstract ScriptInstance(Script) from Script from ScriptGroup {
	/**
	 * States wether this instance is a group or not.
	 */
	public var isGroup(get, never):Bool;
	@:noCompletion inline function get_isGroup():Bool
		return this.type == TypeGroup;

	/**
	 * Utility function to get a Script.
	 */
	inline public function getScript(func:Script -> Void):Void
		if (!isGroup) func(this);
	/**
	 * Utility function to get a ScriptGroup.
	 */
	inline public function getGroup(func:ScriptGroup -> Void):Void
		if (isGroup) func(cast this);
}