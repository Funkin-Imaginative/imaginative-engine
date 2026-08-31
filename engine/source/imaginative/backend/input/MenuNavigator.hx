package imaginative.backend.input;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

class MenuNavItem extends FlxSpriteGroup {
	// internals
	/**
	 * The parent navigator this item in contained within.
	 */
	final parent:BaseMenuNavigator;
	/**
	 * The id for this item.
	 */
	public final itemId:String;

	/**
	 * The index of this item.
	 */
	public var itemIndex(get, never):Int;
	inline function get_itemIndex():Int return parent.members.indexOf(this);
	/**
	 * The grid index of this item.
	 */
	// public var gridIndex(get, never):FlxReadOnlyPoint;
	// inline function get_gridIndex():FlxReadOnlyPoint return null;

	/**
	 * If true, the item is locked and cannot be chosen.
	 */
	public var isLocked:Bool = false;
	/**
	 * If false, the item will be skipped over when navigating.
	 */
	public var canSelect:Bool = true;

	public function new(parent:BaseMenuNavigator, itemId:String) {
		super();
		this.parent = parent;
		this.itemId = itemId;
	}
}

abstract class BaseMenuNavigator extends FlxTypedGroup<MenuNavItem> {
	/**
	 * The tag used to save and receive from the "savedSelections" map.
	 */
	final saveTag:Null<String>;

	/**
	 * Wether the navigator can receive input.
	 */
	public var allowSelect:Bool = false;

	final allowInput:Bool; final allowCursor:Bool;

	var _forceVisualOntoCurrent:Bool = true;
	/**
	 * Wether the **currentView** should always be the **currentValue**.
	 */
	final forceVisualOntoCurrent:Bool;

	/**
	 * States if this navigator has no items.
	 * @return If true, this is empty.
	 */
	inline public function isEmpty():Bool
		return members.empty();

	public function new(?saveTag:String, forceVisualOntoCurrent:Bool = true, allowInput:Bool = true, allowCursor:Bool = true) {
		for (data in Paths.readFolder('sounds/menus', new imaginative.backend.data.StringedArray(',', 'wav', 'ogg', 'mp3')))
			Assets.audio(data.toString(), true, false, true);
		super();
		this.saveTag = saveTag;
		this.forceVisualOntoCurrent = forceVisualOntoCurrent;
		this.allowInput = allowInput;
		this.allowCursor = allowCursor;
	}

	// abstract public function initializeList():Void;

	abstract public function initSelection():Void;

	/**
	 * Checks if the mouse is overlapping with the given item.
	 * @param item The item to check.
	 * @return If true, the mouse is overlapping with the given item.
	 */
	public dynamic function overlapsCheck(item:MenuNavItem):Bool
		return FlxG.mouse.overlaps(item);

	/**
	 * The default cooldown time in seconds.
	 *
	 * Isn't static because you might want different navigtors to have different default cooldowns.
	 */
	public var defaultCooldown:Float = 0.3;
	var cooldownTimer:FlxTimer = new FlxTimer();
	/**
	 * Sets a cooldown for how long until the navigtor registers your inputs again.
	 * @param duration The length of the cooldown in seconds.
	 * @param addOnto If true, it will add onto the existing cooldown.
	 * @return The cooldown timer itself.
	 */
	public function setCooldown(?duration:Float, addOnto:Bool = false):FlxTimer {
		allowSelect = false;
		duration ??= defaultCooldown;
		final totalDuration:Float = addOnto ? cooldownTimer.timeLeft + duration : duration;
		trace('Setting cooldown for $totalDuration seconds${addOnto ? ' (originally $duration seconds)' : ''}.');
		return cooldownTimer.start(totalDuration, timer -> allowSelect = true);
	}

	abstract public function selectCurrent():Void;
}

class MenuNavigator extends BaseMenuNavigator {
	/**
	 * All saved selections.
	 */
	static final savedSelections:Map<String, Int> = new Map<String, Int>();

	/**
	 * The previous value that was inputted.
	 */
	public var previousValue:Int;
	/**
	 * The current value that is inputted.
	 */
	public var currentValue:Int;
	/**
	 * Wether the **currentView** should always be the **currentValue**.
	 */
	public var currentView:Float;

	@:unreflective var _vertical:Bool;
	public function new(verticalLayout:Bool = true, ?saveTag:String, forceVisualOntoCurrent:Bool = true, allowInput:Bool = true, allowCursor:Bool = true) {
		super(saveTag, forceVisualOntoCurrent, allowInput, allowCursor);
		_vertical = verticalLayout;
	}

	public function initSelection():Void {
		if (saveTag != null && savedSelections.exists(saveTag))
			changeSelection(savedSelections.get(saveTag), true);
		else changeSelection(0);
		// if (currentValue == 0) members[currentValue].changeFunc(new SelectionChangeEvent(previousValue, currentValue));
		currentView = currentValue;
		allowSelect = true;
	}

	override function update(delta:Float):Void {
		super.update(delta);
		if (!allowSelect) return;

		if (allowInput) {
			if (_vertical) {
				if (Controls.global.uiUp || FlxG.keys.justPressed.PAGEUP) {
					changeSelection(-1);
					currentView = currentValue;
				}
				if (Controls.global.uiDown || FlxG.keys.justPressed.PAGEDOWN) {
					changeSelection(1);
					currentView = currentValue;
				}
			} else {
				if (Controls.global.uiLeft || FlxG.keys.justPressed.COMMA) {
					changeSelection(-1);
					currentView = currentValue;
				}
				if (Controls.global.uiRight || FlxG.keys.justPressed.PERIOD) {
					changeSelection(1);
					currentView = currentValue;
				}
			}

			if (FlxG.mouse.wheel != 0) {
				changeSelection((FlxG.keys.pressed.SHIFT ? 5 : 1) * -1 * FlxG.mouse.wheel);
				currentView = currentValue;
			}
		}
		if (allowCursor && FlxG.mouse.justMoved)
			for (i => item in members)
				if (item.canSelect && overlapsCheck(item))
					changeSelection(i, true);

		// quick jumps
		if (allowInput && FlxG.keys.justPressed.HOME) {
			var slot:Int = 0; // jic the first item is un-selectable
			while (slot < length && !members[slot].canSelect) slot++;
			changeSelection(slot, true);
			currentView = currentValue;
		}
		if (allowInput && FlxG.keys.justPressed.END) {
			var slot:Int = length - 1; // jic the last item is un-selectable
			while (slot > 0 && !members[slot].canSelect) slot--;
			changeSelection(slot, true);
			currentView = currentValue;
		}

		if ((allowInput && Controls.global.accept) || (allowCursor && (currentValue == -1 ? true : overlapsCheck(members[currentValue])))) {
			if (currentView != currentValue) {
				currentView = currentValue;
				FlxG.sound.play(Assets.sound('menus/scroll', true, false, true), 0.7);
			} else selectCurrent();
		}
	}

	@:unreflective var _recursionTracker:Int = 0;
	public function changeSelection(amount:Int = 0, pureSelect:Bool = false):Void {
		_recursionTracker++;
		if (_recursionTracker > length) {
			trace('Recursion detected, setting selection to -1 to prevent stack overflow! (length: $length)');
			_recursionTracker = 0; changeSelection(-1, true);
			return;
		}

		if (isEmpty()) {
			trace('Cannot change selection, no members exist!');
			return;
		}
		inline function wrap(amount:Int, curAmount:Int = 0):Int
			return FlxMath.wrap(curAmount + amount, 0, length - 1);
		final unselected:Bool = amount == -1 && pureSelect;
		var prevSel = currentValue; var newSel = pureSelect ? (unselected ? -1 : wrap(amount)) : wrap(amount, currentValue);
		var changeAmount = newSel - prevSel;

		var currentItem = members[newSel];
		if (!unselected && !currentItem.canSelect) {
			if (!pureSelect)
				changeSelection(amount + (amount > 0 ? 1 : -1));
			return;
		}
		_recursionTracker = 0;

		previousValue = prevSel == newSel ? previousValue : prevSel;
		currentValue = newSel;

		/* if (!event.noChange) {
			members[event.previousValue]?.deselectFunc(event);
			currentItem?.changeFunc(event);
		} */
	}
	public function selectCurrent():Void {
		if (currentValue == -1) {
			trace('Nothing selected.');
			return;
		}
		setCooldown();

		final curItem = members[currentValue];
		trace('Selecting item "${curItem.itemId}". (index: $currentValue)');
	}

	override function destroy():Void {
		if (saveTag != null)
			savedSelections.set(saveTag, currentValue == -1 ? 0 : currentValue);
		super.destroy();
	}
}

// @:forward abstract NavPoint(FlxPoint) to FlxReadOnlyPoint {
// 	public function new() {
// 		this = new FlxCallbackPoint(point -> point.round());
// 	}
// }
// class GridMenuNavigator extends BaseMenuNavigator {
// 	/**
// 	 * All saved selections.
// 	 */
// 	static final savedSelections:Map<String, FlxReadOnlyPoint> = new Map<String, FlxReadOnlyPoint>();

// 	/**
// 	 * The previous value that was inputted.
// 	 */
// 	public var previousValue:NavPoint;
// 	/**
// 	 * The current value that is inputted.
// 	 */
// 	public var currentValue:NavPoint;
// 	/**
// 	 * Wether the **currentView** should always be the **currentValue**.
// 	 */
// 	public var currentView:FlxPoint;

// 	override function destroy():Void {
// 		if (saveTag != null)
// 			savedSelections.set(saveTag, currentValue == -1 ? 0 : currentValue);
// 		super.destroy();
// 		previousValue.destroy();
// 		currentValue.destroy();
// 		currentView.put();
// 	}
// }