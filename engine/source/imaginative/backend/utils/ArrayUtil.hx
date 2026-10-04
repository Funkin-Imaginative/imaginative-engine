package imaginative.backend.utils;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPool;

/**
 * This *might* be overcomplicated.
 */
@:unreflective private class ArrayPool {
	final exceptions:Array<Array<Dynamic>> = [];
	final pool:Array<Array<Dynamic>> = []; final weakened:Array<Array<Dynamic>> = [];

	public function new() {
		exceptions.push(exceptions);
		exceptions.push(pool);
		exceptions.push(weakened);
	}

	public function recycle<T>(weak:Bool = false):Array<T> {
		for (array in pool) {
			if (exceptions.contains(array)) {
				if (isWeak(array)) weakened.remove(array);
				pool.remove(array);
				continue;
			}
			pool.remove(array);
			if (weak && !isWeak(array)) weakened.push(array);
			return cast array;
		}
		return [];
	}

	extern inline public function put(array:Array<Dynamic>):Void {
		if (!inPool(array)) {
			array.clear();
			pool.push(array);
			if (isWeak(array))
				weakened.remove(array);
		}
	}
	extern inline public function putWeak(array:Array<Dynamic>):Void
		if (isWeak(array)) put(array);

	extern inline public function inPool(array:Array<Dynamic>):Bool return pool.contains(array);
	extern inline public function isWeak(array:Array<Dynamic>):Bool return weakened.contains(array);
}

class ArrayUtil {
	/**
	 * FlxPool recreation, cause fuck extern classes :bk_dead:
	 */
	@:unreflective static final _pool:ArrayPool = new ArrayPool();

	/**
	 * Recycles an array from the pool.
	 * @param weak If true, it will be a weak array.
	 * @return The recycled array.
	 */
	public static function recycle<T>(weak:Bool = false):Array<T>
		return _pool.recycle(weak);
	/**
	 * Makes a pre-existing array weak.
	 * @param array The array to make weak.
	 * @return The array itself.
	 */
	inline public static function weaken<T>(array:Array<T>):Array<T> {
		if (!_pool.isWeak(array))
			@:privateAccess _pool.weakened.push(array);
		return array;
	}

	/**
	 * Puts an array back into the pool.
	 * @param array The array to put back into the pool.
	 */
	inline public static function put(array:Array<Dynamic>):Void
		_pool.put(array);
	/**
	 * Puts an array back into the pool if it's weakened.
	 * @param array The array to put back into the pool.
	 */
	inline public static function putWeak(array:Array<Dynamic>):Void
		_pool.putWeak(array);

	// Custom Stuff
	/**
	 * Returns a clean display list for quickly tracing a list.
	 * @param array The array.
	 * @return The display list.
	 */
	inline public static function cleanDisplayList(array:Array<String>):String {
		var temp = [for (i => item in array) (i == (array.length - 2) && !array.isBlank()) ? '"$item" and' : '"$item"'];
		var result = '${temp.join(', ').replace('and,', 'and')}';
		array.putWeak(); temp.put();
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
	 */
	public static function sortByList<T>(array:Array<T>, list:Array<T>, keepUnlisted:Bool = false):Void {
		if (!array.isBlank() && !list.isBlank()) {
			var newArray:Array<T> = ArrayUtil.recycle();
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
		list.putWeak();
	}

	/**
	 * Overrides a pre-existing array with an intirely different one.
	 * @param array The array.
	 * @param content The content to override with.
	 * @return The array itself.
	 */
	inline public static function set<T>(array:Array<T>, content:Array<T>):Array<T> {
		array.clear();
		array.merge(content.weaken());
		return array;
	}

	/**
	 * Pushes all of array B into array A.
	 * @param a The first array.
	 * @param b The second array.
	 * @return Array a.
	 */
	inline public static function merge<T>(a:Array<T>, b:Array<T>):Array<T> {
		for (i in b) a.push(i);
		b.putWeak();
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
	public static function clear<T>(array:Array<T>, recursive:Bool = false):Void {
		while (!array.isBlank()) {
			var item = array.pop();
			if (recursive && item is Array)
				clear(cast item, true);
		}
		array.resize(0); // jic
	}
	/**
	 * Same as "clear" function, but if any objects are destroyable, then they will be destroyed.
	 * @param array The array.
	 */
	inline public static function destroyItems<T:IFlxDestroyable>(array:Array<T>):Void {
		while (!array.isBlank())
			array.pop().destroy();
		array.clear();
	}
	/**
	 * Same as "clear" function, but if any objects are poolable, then they will be put back into the pool.
	 * @param array The array.
	 * @param weak If true, it will put weak ones.
	 */
	inline public static function putItems<T:IFlxPooled>(array:Array<T>, weak:Bool = false):Void {
		while (!array.isBlank())
			if (weak) array.pop().putWeak();
			else array.pop().put();
		array.clear();
	}
}