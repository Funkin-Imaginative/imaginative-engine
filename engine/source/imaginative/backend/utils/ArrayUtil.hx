package imaginative.backend.utils;

class ArrayUtil {
	/**
	 * Returns a clean displayed list for quickly tracing a list.
	 * @param array The array.
	 * @param clear If true, it resizes the array to 0.
	 * @return The display list.
	 */
	inline public static function cleanDisplayList(array:Array<String>, clear:Bool = false):String {
		var result = '${[for (i => item in array) (i == (array.length - 2) && !array.empty()) ? '"$item" and' : '"$item"'].join(', ').replace('and,', 'and')}';
		if (clear) array.resize(0);
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
	 */
	inline public static function merge<T>(a:Array<T>, b:Array<T>, clearB:Bool = false):Void {
		for (i in b)
			a.push(i);
		if (clearB)
			b.resize(0);
	}
}