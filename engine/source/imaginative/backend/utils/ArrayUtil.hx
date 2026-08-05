package imaginative.backend.utils;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPool;

class ArrayUtil {
	/**
	 * Returns a clean displayed list for quickly tracing a list.
	 * @param array The array.
	 * @param clear If true, it resizes the array to 0.
	 * @return The display list.
	 */
	inline public static function cleanDisplayList(array:Array<String>, clear:Bool = false):String {
		var result = '${[for (i => item in array) (i == (array.length - 2) && !array.empty()) ? '"$item" and' : '"$item"'].join(', ').replace('and,', 'and')}';
		if (clear) array.clear();
		return result;
	}

	@:inheritDoc(haxe.ds.ArraySort.sort)
	inline public static function arraySort<T>(array:Array<T>, method:(T, T) -> Int):Void
		haxe.ds.ArraySort.sort(array, method);

	/**
	 * Pushes all of array B into array A.
	 * @param a The first array.
	 * @param b The second array.
	 * @param clearB If true, it resizes array B to 0.
	 * @param recursive If true, it will recursively clear any arrays within array B.
	 */
	inline public static function merge<T>(a:Array<T>, b:Array<T>, clearB:Bool = false, recursive:Bool = true):Void {
		for (i in b)
			a.push(i);
		if (clearB)
			b.clear(recursive);
	}

	/**
	 * Removes all elements from the array.
	 * @param array The array.
	 * @param recursive If true, it will recursively clear any arrays within the array.
	 */
	public static function clear<T>(array:Array<T>, recursive:Bool = true):Void {
		while (!array.empty()) {
			var item = array.pop();
			if (recursive && item is Array)
				clear(cast item);
		}
		array.resize(0);
	}
	/**
	 * Same as "clear", but if any objects are destroyable, then they will be destroyed.
	 * @param array The array.
	 */
	inline public static function destroy<T:IFlxDestroyable>(array:Array<T>):Void {
		while (!array.empty())
			array.pop().destroy();
		array.resize(0);
	}
	/**
	 * Same as "clear", but if any objects are puttable, then they will be put.
	 * @param array The array.
	 */
	inline public static function put<T:IFlxPooled>(array:Array<T>, isWeak:Bool = false):Void {
		while (!array.empty())
			if (isWeak) array.pop().putWeak();
			else array.pop().put();
		array.resize(0);
	}
}