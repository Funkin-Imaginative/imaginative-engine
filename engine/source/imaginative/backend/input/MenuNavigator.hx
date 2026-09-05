package imaginative.backend.input;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;

// import flixel.math.FlxPoint;

typedef MenuNavData = {
	/**
	 * The item id.
	 */
	var id:String;
	/**
	 * The function for how the item creation will be handled. If it returns true, the item will be added to the navigator.
	 */
	var ?createFunc:(Int, MenuNavItem) -> Bool;

	@:inheritDoc(MenuNavItem.onDeselect) var ?deselectFunc:() -> Void;
	@:inheritDoc(MenuNavItem.onChange) var ?changeFunc:() -> Void;
	@:inheritDoc(MenuNavItem.onSelected) var ?selectedFunc:() -> Void;
}

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
	inline function get_itemIndex():Int
		return parent.members.indexOf(this);
	/**
	 * The grid index of this item.
	 */
	// public var gridIndex(get, never):FlxReadOnlyPoint;
	// inline function get_gridIndex():FlxReadOnlyPoint return null;

	/**
	 * If true, the item is locked and cannot be chosen.
	 *
	 * __NOTE:__ This does not effect visuals. Override the "_isLocked" function for that, its dynamic for a reason.
	 */
	public var isLocked(default, set):Bool = false;
	inline function set_isLocked(value:Bool):Bool {
		_isLocked(isLocked = value);
		return value;
	}
	/**
	 * Override this to have the visuals change.
	 *
	 * **NOTE:** Override this after you've created all the objects within the item.
	 * @param value Whether the item is locked.
	 */
	public dynamic function _isLocked(value:Bool):Void {}

	/**
	 * If false, the item will be skipped over when navigating.
	 *
	 * __NOTE:__ This does not effect visuals. Override the "_canSelect" function for that, its dynamic for a reason.
	 */
	public var canSelect(default, set):Bool = true;
	inline function set_canSelect(value:Bool):Bool {
		_canSelect(canSelect = value);
		return value;
	}
	/**
	 * Override this to have the visuals change.
	 *
	 * **NOTE:** Override this after you've created all the objects within the item.
	 * @param value Whether the item can be selected.
	 * @return Bool
	 */
	public dynamic function _canSelect(value:Bool):Void {}

	public function new(parent:BaseMenuNavigator, itemId:String) {
		super();
		this.parent = parent;
		this.itemId = itemId;
	}

	/**
	 * The function for when the item is no longer the current selection.
	 */
	public var onDeselect:Null<() -> Void> = null;
	/**
	 * The function for when the item becomes the current selection.
	 */
	public var onChange:Null<() -> Void> = null;
	/**
	 * The function for when the item is selected.
	 */
	public var onSelected:Null<() -> Void> = null;
}

abstract class BaseMenuNavigator extends FlxTypedGroup<MenuNavItem> {
	/**
	 * The tag used to save and receive from the "savedSelections" map.
	 */
	final saveTag:Null<String>;

	/**
	 * Whether the navigator can receive input.
	 */
	public var allowSelect:Bool = false;

	final allowInput:Bool; final allowCursor:Bool;

	var _forceVisualOntoCurrent:Bool = true;
	/**
	 * Whether the **currentView** should always be the **currentValue**.
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

	/**
	 * WHen called, it will generate the items for the navigator.
	 * @param items The list of items.
	 * @param createFunc The function for how the item creation will be handled. Only gets used if an individual item does not have a **createFunc**. If it returns true, the item will be added to the navigator.
	 */
	abstract public function generateItems(items:Array<MenuNavData>, ?createFunc:(Int, MenuNavItem) -> Bool):Void;
	/**
	 * Initializes the selection of the navigator.
	 */
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
	final cooldownTimer:FlxTimer = new FlxTimer();
	/**
	 * Sets a cooldown for how long until the navigtor registers your inputs again.
	 * @param duration The length of the cooldown in seconds.
	 * @return The cooldown timer itself.
	 */
	public function setCooldown(?duration:Float):FlxTimer {
		allowSelect = false;
		duration ??= defaultCooldown;
		trace('Setting cooldown for $duration seconds.');
		return cooldownTimer.start(duration, timer -> allowSelect = true);
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
	 * Whether the **currentView** should always be the **currentValue**.
	 */
	public var currentView:Float;

	@:unreflective var _vertical:Bool;
	public function new(verticalLayout:Bool = true, ?saveTag:String, forceVisualOntoCurrent:Bool = true, allowInput:Bool = true, allowCursor:Bool = true) {
		super(saveTag, forceVisualOntoCurrent, allowInput, allowCursor);
		_vertical = verticalLayout;
	}

	@:inheritDoc(BaseMenuNavigator.generateItems)
	public function generateItems(items:Array<MenuNavData>, ?createFunc:(Int, MenuNavItem) -> Bool):Void {
		if (!isEmpty()) {
			trace('List has already been created. (length: $length)');
			return;
		}
		items.prune(data -> !(data == null || data.id.isBlank()));
		if (items.empty()) {
			trace('Item list is empty.');
			return;
		}
		trace('List contents are, ${[for (data in items) data.id].cleanDisplayList(true)}');

		var _i:Int = 0;
		var failed:Array<String> = [];
		for (data in items) {
			var item = new MenuNavItem(this, data.id);
			if (data.changeFunc != null) item.onChange = data.changeFunc;
			if (data.selectedFunc != null) item.onSelected = data.selectedFunc;
			if (data.deselectFunc != null) item.onDeselect = data.deselectFunc;

			var daFunc = data.createFunc ?? createFunc;
			if (daFunc != null && daFunc(_i, item)) {
				add(item); _i++;
			} else {
				item.destroy();
				failed.push(data.id);
			}
		}
		items.clear();

		if (isEmpty())
			trace('Item list is empty!');
		else if (!failed.empty())
			trace('Failed items are, ${failed.cleanDisplayList(true)}.');
	}
	@:inheritDoc(BaseMenuNavigator.initSelection)
	public function initSelection():Void {
		if (saveTag != null && savedSelections.exists(saveTag))
			changeSelection(savedSelections.get(saveTag), true);
		else changeSelection(0);
		if (currentValue == 0) members[currentValue].onChange();
		currentView = currentValue;
		allowSelect = true;
	}

	extern inline function selMult():Int
		return FlxG.keys.pressed.SHIFT ? 5 : 1;
	override function update(delta:Float):Void {
		super.update(delta);
		if (!allowSelect) return;

		if (allowInput) {
			if (_vertical) {
				if (Controls.global.uiUp || FlxG.keys.justPressed.PAGEUP) {
					changeSelection(selMult() * -1);
					currentView = currentValue;
				}
				if (Controls.global.uiDown || FlxG.keys.justPressed.PAGEDOWN) {
					changeSelection(selMult() * 1);
					currentView = currentValue;
				}
			} else {
				if (Controls.global.uiLeft || FlxG.keys.justPressed.COMMA) {
					changeSelection(selMult() * -1);
					currentView = currentValue;
				}
				if (Controls.global.uiRight || FlxG.keys.justPressed.PERIOD) {
					changeSelection(selMult() * 1);
					currentView = currentValue;
				}
			}
		}
		if (allowCursor) {
			if (FlxG.mouse.wheel != 0) {
				changeSelection(selMult() * -1 * FlxG.mouse.wheel);
				currentView = currentValue;
			}
			if (FlxG.mouse.justMoved)
				for (i => item in members)
					if (item.canSelect && overlapsCheck(item))
						changeSelection(i, true);
		}

		// quick jumps
		if (allowInput) {
			if (FlxG.keys.justPressed.HOME) {
				var slot:Int = 0; // jic the first item is un-selectable
				while (slot < length && !members[slot].canSelect) slot++;
				if (!members[slot].canSelect) slot = -1;
				changeSelection(slot, true);
				currentView = currentValue;
			}
			if (FlxG.keys.justPressed.END) {
				var slot:Int = length - 1; // jic the last item is un-selectable
				while (slot > 0 && !members[slot].canSelect) slot--;
				if (!members[slot].canSelect) slot = -1;
				changeSelection(slot, true);
				currentView = currentValue;
			}
		}

		if ((allowInput && Controls.global.accept) || (allowCursor && FlxG.mouse.justPressed && (currentValue == -1 ? true : overlapsCheck(members[currentValue])))) {
			if (currentView != currentValue) {
				currentView = currentValue;
				FlxG.sound.play(Assets.sound('menus/scroll', true, false, true), 0.7);
			} else selectCurrent();
		}

		if (forceVisualOntoCurrent && _forceVisualOntoCurrent && currentValue != -1)
			currentView = currentValue;
	}

	@:unreflective var _recursionTracker:Int = 0;
	extern inline function wrap(amount:Int, curAmount:Int = 0):Int
		return FlxMath.wrap(curAmount + amount, 0, length - 1);
	public function changeSelection(amount:Int = 0, pureSelect:Bool = false):Void {
		if (isEmpty()) {
			currentValue = -1;
			trace('Cannot change selection, no members exist!');
			return;
		}

		_recursionTracker++;
		if (_recursionTracker > length) {
			trace('Recursion detected, setting selection to -1 to prevent stack overflow. (length: $length)');
			_recursionTracker = 0; changeSelection(-1, true);
			return;
		}
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


		if (changeAmount != 0) {
			FlxG.sound.play(Assets.sound('menus/scroll', true, false, true), 0.7);
			members[previousValue].onDeselect();
			currentItem.onChange();
		}
	}
	public function selectCurrent():Void {
		if (currentValue == -1) {
			trace('Nothing selected.');
			return;
		}
		setCooldown();

		final curItem = members[currentValue];
		trace('Selecting item "${curItem.itemId}". (index: $currentValue)');

		if (curItem.isLocked) {}
		else {
			FlxG.sound.play(Assets.sound('menus/confirm', true, false, true), 0.7);
			curItem.onSelected();
		}
	}

	extern inline public function addLogs():Void
		FlxG.watch.addFunction('Navigator Selection', () -> 'from ${previousValue ?? 0} to ${currentValue ?? 0} (${currentView ?? 0})');

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
// 	 * Whether the **currentView** should always be the **currentValue**.
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