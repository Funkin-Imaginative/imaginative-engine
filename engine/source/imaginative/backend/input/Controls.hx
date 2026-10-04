package imaginative.backend.input;

import flixel.input.keyboard.FlxKey;
#if Scripting.Haxe import hxscript.proxy.ReflectProxy; #end

typedef Key = Null<FlxKey>;
@:forward(iterator, keyValueIterator)
abstract KeyList(Array<Key>) from Array<Key> to Array<Key> {
	inline public function set(list:KeyList):Void {
		list.prune(key -> !(key == ANY || key == NONE || key == null));
		if (list.isBlank()) _log('[Controls.KeyList] Cannot give an empty list. Check if your list contains invalid keys.', DebugMessage);
		else this.set(list);
	}

	inline public function add(key:Key):Void {
		if (key == ANY || key == NONE || key == null)
			_log('[Controls.KeyList] Cannot add "$key" to a KeyList.', ErrorMessage);
		else if (!this.contains(key)) this.push(key);
		else _log('[Controls.KeyList] Already contains "$key".', DebugMessage);
	}

	@:inheritDoc(Array.copy) // ensures typing on clone
	inline public function copy():KeyList
		return this.copy();

	inline public function clear():Void
		this.clear();
}

typedef Bind = flixel.util.typeLimit.OneOfTwo<Binds, String>;
enum abstract Binds(String) from String {
	// UI
	@:inheritDoc(GlobalInput.uiLeft) var UI_LEFT = 'ui_left';
	@:inheritDoc(GlobalInput.uiDown) var UI_DOWN = 'ui_down';
	@:inheritDoc(GlobalInput.uiUp) var UI_UP = 'ui_up';
	@:inheritDoc(GlobalInput.uiRight) var UI_RIGHT = 'ui_right';

	// Actions
	@:inheritDoc(GlobalInput.accept) var ACCEPT = 'accept';
	@:inheritDoc(GlobalInput.back) var BACK = 'back';
	@:inheritDoc(GlobalInput.pause) var PAUSE = 'pause';
	@:inheritDoc(GlobalInput.reset) var RESET = 'reset';

	// Volume
	@:inheritDoc(GlobalInput.volumeUp) var VOLUME_UP = 'volume_up';
	@:inheritDoc(GlobalInput.volumeDown) var VOLUME_DOWN = 'volume_down';
	@:inheritDoc(GlobalInput.volumeMute) var VOLUME_MUTE = 'volume_mute';

	// Extras
	@:inheritDoc(GlobalInput.fullscreen) var FULLSCREEN = 'fullscreen';

	// Debug
	@:inheritDoc(GlobalInput.botplay) var BOTPLAY = 'botplay';
	@:inheritDoc(GlobalInput.resetState) var RESET_STATE = 'reset_state';
	@:inheritDoc(GlobalInput.quickState) var QUICK_STATE = 'quick_state';
	@:inheritDoc(GlobalInput.reloadGame) var RELOAD_GAME = 'reload_game';
}

@:build(imaginative.backend.macro.ControlsMacro.build())
class GlobalInput extends UserInput {}

class PlayerInput extends UserInput {
	/**
	 * The amount of lanes the assigned field has.
	 */
	public var laneCount:Int = 4;

	/**
	 * Pressed input for notes.
	 * @param id The lane id.
	 * @param count The lane amount.
	 * @return Bool
	 */
	inline public function notePressed(id:Int, ?count:Int):Bool
		return pressed('note_${count ?? laneCount}:$id');
	/**
	 * Held input for notes.
	 * @param id The lane id.
	 * @param count The lane amount.
	 * @return Bool
	 */
	inline public function noteHeld(id:Int, ?count:Int):Bool
		return held('note_${count ?? laneCount}:$id');
	/**
	 * Released input for notes.
	 * @param id The lane id.
	 * @param count The lane amount.
	 * @return Bool
	 */
	inline public function noteReleased(id:Int, ?count:Int):Bool
		return released('note_${count ?? laneCount}:$id');

	/**
	 * Pressed inputs for all note id's in that lane amount.
	 * @param count The lane amount.
	 * @return Bool
	 */
	inline public function notesPressed(?count:Int):Array<Bool>
		return [for (id in 0...count) notePressed(id, count ?? laneCount)];
	/**
	 * Held inputs for all note id's in that lane amount.
	 * @param count The lane amount.
	 * @return Bool
	 */
	inline public function notesHeld(?count:Int):Array<Bool>
		return [for (id in 0...count) noteHeld(id, count ?? laneCount)];
	/**
	 * Released inputs for all note id's in that lane amount.
	 * @param count The lane amount.
	 * @return Bool
	 */
	inline public function notesReleased(?count:Int):Array<Bool>
		return [for (id in 0...count) noteReleased(id, count ?? laneCount)];

	/**
	 * Gets the note lane from a key event.
	 * @param key The keyCode to input.
	 * @param count The lane amount.
	 * @return Int
	 */
	public function noteFromEvent(key:Key, ?count:Int):Int {
		if (key == null) return -1;
		for (i in 0...(count ?? laneCount))
			for (note in bindCheck('note_${count ?? laneCount}:$i'))
				if (key == note)
					return i;
		return -1;
	}
}


class Controls {
	extern inline static function init():Void {
		// TODO: Save data junk.
		_log('Initializing Controls');

		global.binds.set(UI_LEFT, [A, LEFT]);
		global.binds.set(UI_DOWN, [S, DOWN]);
		global.binds.set(UI_UP, [W, UP]);
		global.binds.set(UI_RIGHT, [D, RIGHT]);

		global.binds.set(ACCEPT, [ENTER, SPACE]);
		global.binds.set(BACK, [BACKSPACE, ESCAPE]);
		global.binds.set(PAUSE, [ENTER, ESCAPE]);
		global.binds.set(RESET, [R, DELETE]);

		global.binds.set(VOLUME_UP, FlxG.sound.volumeUpKeys);
		global.binds.set(VOLUME_DOWN, FlxG.sound.volumeDownKeys);
		global.binds.set(VOLUME_MUTE, FlxG.sound.muteKeys);

		global.binds.set(FULLSCREEN, [F11]);

		global.binds.set(BOTPLAY, [F4]);
		global.binds.set(RESET_STATE, [F5]);
		global.binds.set(QUICK_STATE, [F6]);
		global.binds.set(RELOAD_GAME, [F8]);

		player1.binds.set('note_4:0', [D, LEFT]);
		player1.binds.set('note_4:1', [F, DOWN]);
		player1.binds.set('note_4:2', [J, UP]);
		player1.binds.set('note_4:3', [K, RIGHT]);

		/* FlxG.sound.volumeUpKeys.set(global.binds.get(VOLUME_UP).copy());
		FlxG.sound.volumeDownKeys.set(global.binds.get(VOLUME_DOWN).copy());
		FlxG.sound.muteKeys.set(global.binds.get(VOLUME_MUTE).copy()); */
	}

	/**
	 * Menu input amongst other things.
	 */
	public static final global:GlobalInput = new GlobalInput('Input()');

	/**
	 * Player 1's controls.
	 */
	public static final player1:PlayerInput = new PlayerInput('Input(Player: One)');
	/**
	 * Player 2's controls.
	 */
	public static final player2:PlayerInput = new PlayerInput('Input(Player: Two)');

	/**
	 * Used for arrow field's when it's not maintained by a player.
	 */
	public static final blank:PlayerInput = new PlayerInput('Input(Player: Blank)');
}

typedef InputList = Map<Bind, KeyList>;
abstract class UserInput extends flixel.FlxBasic #if Scripting.Haxe.IGNORE implements ICustomReflection #end {
	/**
	 * The id of the input handler.
	 *
	 * Used for debugging.
	 */
	public final id:String;

	/**
	 * The binds that are contained within this input handler.
	 */
	public final binds:InputList = new InputList();

	/**
	 * Pressed input.
	 * @param bind The bind name.
	 * @return Bool
	 */
	inline public function pressed(bind:Bind):Bool
		return FlxG.keys.anyJustPressed(bindCheck(bind));
	/**
	 * Held input.
	 * @param bind The bind name.
	 * @return Bool
	 */
	inline public function held(bind:Bind):Bool
		return FlxG.keys.anyPressed(bindCheck(bind));
	/**
	 * Released input.
	 * @param bind The bind name.
	 * @return Bool
	 */
	inline public function released(bind:Bind):Bool
		return FlxG.keys.anyJustReleased(bindCheck(bind));

	extern inline function bindCheck(bind:Bind):Null<KeyList> {
		if (!active) return null;
		if (binds.exists(bind)) return binds.get(bind);
		_log('$id: Bind "$bind" not found.', DebugMessage);
		return null;
	}

	@:allow(imaginative.backend.input.Controls)
	function new(id:String) {
		super();
		this.id = id;
	}

	inline public function clearBinds():Void {
		for (bind in binds)
			bind.put();
		binds.clear();
		_log('$id: Binds cleared.');
	}

	override function destroy():Void {
		kill();
		clearBinds();
		super.destroy();
	}

	#if Scripting.Haxe.IGNORE // TODO: Use global scripting to allow users to do more advanced shit.
	@:inheritDoc(ICustomReflection.reflectHasField)
	@:noCompletion public function reflectHasField(field:String):Bool {
		return Reflect.hasField(this, field);
	}

	@:inheritDoc(ICustomReflection.reflectGetField)
	@:noCompletion public function reflectGetField(field:String):Dynamic {
		return Reflect.field(this, field);
	}

	@:inheritDoc(ICustomReflection.reflectSetField)
	@:noCompletion public function reflectSetField(field:String, value:Dynamic):Dynamic {
		return Reflect.setField(this, field, value);
	}

	@:inheritDoc(ICustomReflection.reflectGetProperty)
	@:noCompletion public function reflectGetProperty(property:String):Dynamic {
		return Reflect.getProperty(this, property);
	}

	@:inheritDoc(ICustomReflection.reflectSetProperty)
	@:noCompletion public function reflectSetProperty(property:String, value:Dynamic):Dynamic {
		return Reflect.setProperty(this, property, value);
	}

	@:inheritDoc(ICustomReflection.reflectListFields)
	@:noCompletion public function reflectListFields():Array<String> {
		return Reflect.fields(this);
	}
	#end
}