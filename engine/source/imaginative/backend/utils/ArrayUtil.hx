package imaginative.backend.utils;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPool;

class ArrayUtil {
	static var lastArray:Array<Dynamic> = [];
	/**
	 * Sets an array to the last array used.
	 * @param array The array.
	 * @return The array itself.
	 */
	inline public static function setLast<T>(array:Array<T>):Array<T> {
		lastArray = array;
		return array;
	}
	/**
	 * Clears the last array used.
	 */
	inline public static function clearLast():Void
		lastArray.clear();
	/**
	 * Same as "clearLast" function, but if any objects are destroyable, then they will be destroyed.
	 */
	inline public static function destroyLast():Void {
		lastArray.destroy();
	}
	/**
	 * Same as "clearLast" function, but if any objects are poolable, then they will be put back into the pool.
	 * @param isWeak If true, it will put weak ones.
	 */
	@:noUsing inline public static function putLast(isWeak:Bool = false):Void {
		lastArray.put(isWeak);
	}

	/**
	 * Returns a clean display list for quickly tracing a list.
	 * @param array The array.
	 * @param clear If true, it resizes the array to 0.
	 * @return The display list.
	 */
	inline public static function cleanDisplayList(array:Array<String>, clear:Bool = false):String {
		var result = '${[for (i => item in array) (i == (array.length - 2) && !array.isBlank()) ? '"$item" and' : '"$item"'].setLast().join(', ').replace('and,', 'and')}';
		if (clear) array.clear();
		clearLast();
		return result;
	}

	@:inheritDoc(haxe.ds.ArraySort.sort)
	inline public static function arraySort<T>(array:Array<T>, method:(T, T) -> Int):Void
		haxe.ds.ArraySort.sort(array, method);

	/**
	 * Sorts an array by a list of items.
	 *
	 * **May not play nicely if not a string array.**
	 * @param array The array to sort.
	 * @param list The list to sort by.
	 * @param keepUnlisted Whether to keep items that aren't referenced in the main array.
	 * @param clearList If true, it resizes list to 0.
	 * @param recursive If true, it will recursively clear any arrays within the list.
	 */
	public static function sortByList<T>(array:Array<T>, list:Array<T>, keepUnlisted:Bool = false, clearList:Bool = true, recursive:Bool = true):Void {
		if (!array.isBlank() && !list.isBlank()) {
			var newArray:Array<T> = [];
			for (n in list)
				for (i in array)
					if (n == i)
						newArray.push(i);
			if (keepUnlisted)
				for (i in array)
					if (!newArray.contains(i))
						newArray.push(i);
			array.set(newArray);
		}
		if (clearList) list.clear(recursive);
	}

	/**
	 * Overrides a pre-existing array with an intirely different one.
	 * @param array The array.
	 * @param content The content to override with.
	 * @return The array itself.
	 */
	inline public static function set<T>(array:Array<T>, content:Array<T>):Array<T> {
		array.clear();
		array.merge(content, true);
		return array;
	}

	/**
	 * Pushes all of array B into array A.
	 * @param a The first array.
	 * @param b The second array.
	 * @param clearB If true, it resizes array B to 0.
	 * @param recursive If true, it will recursively clear any arrays within array B.
	 * @return Array a.
	 */
	inline public static function merge<T>(a:Array<T>, b:Array<T>, clearB:Bool = false, recursive:Bool = true):Array<T> {
		for (i in b) a.push(i);
		if (clearB) b.clear(recursive);
		return a;
	}

	/**
	 * Same as built in "filter" function, expect it doesn't make a *new* array.
	 * @param array The array to prune.
	 * @param func If false, that element gets pruned.
	 * @return The array itself.
	 */
	inline public static function prune<T>(array:Array<T>, func:T -> Bool):Array<T>
		return array.set(array.filter(func));

	/**
	 * Checks if an array is blank.
	 * @param array The array.
	 * @return If true, the array is empty or null.
	 */
	inline public static function isBlank<T>(array:Array<T>):Bool
		return array == null || array.empty();

	/**
	 * Removes all elements from the array.
	 * @param array The array.
	 * @param recursive If true, it will recursively clear any arrays within the array.
	 */
	public static function clear<T>(array:Array<T>, recursive:Bool = true):Void {
		while (!array.isBlank()) {
			var item = array.pop();
			if (recursive && item is Array)
				clear(cast item);
		}
		array.resize(0); // jic
	}
	/**
	 * Same as "clear" function, but if any objects are destroyable, then they will be destroyed.
	 * @param array The array.
	 */
	inline public static function destroy<T:IFlxDestroyable>(array:Array<T>):Void {
		while (!array.isBlank())
			array.pop().destroy();
		array.clear();
	}
	/**
	 * Same as "clear" function, but if any objects are poolable, then they will be put back into the pool.
	 * @param array The array.
	 * @param isWeak If true, it will put weak ones.
	 */
	inline public static function put<T:IFlxPooled>(array:Array<T>, isWeak:Bool = false):Void {
		while (!array.isBlank())
			if (isWeak) array.pop().putWeak();
			else array.pop().put();
		array.clear();
	}
}