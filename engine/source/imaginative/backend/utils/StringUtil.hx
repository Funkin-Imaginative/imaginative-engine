package imaginative.backend.utils;

import haxe.iterators.StringIterator;
import haxe.iterators.StringKeyValueIterator;

class StringUtil {
	// Custom Stuff
	/**
	 * Is basically an array's split function, but each slot gets trimmed.
	 * @param string The string.
	 * @param delimiter The splitter key.
	 * @return The trimmed array.
	 */
	inline public static function trimSplit(string:String, delimiter:String):Array<String> {
		var daList:Array<String> = string.split(delimiter);
		for (i in 0...daList.length)
			daList[i] = daList[i].trim();
		return daList;
	}


	/**
	 * A port of Godot's "get_slice" function.
	 * @param string The string.
	 * @param delimiter The splitter key.
	 * @param slice The slice index.
	 * @return The sliced string.
	 */
	public static function getSlice(string:String, delimiter:String, slice:Int):String {
		if (string.isBlank(false) || delimiter.isBlank(false) || slice < 0) return '';

		var start = 0;
		var count = 0;
		while (true) {
			var index = string.indexOf(delimiter, start);
			if (index == -1) return (count == slice) ? string.substring(start) : '';
			if (count == slice) return string.substring(start, index);
			start = index + delimiter.length;
			count++;
		}
	}
	/**
	 * A port of Godot's "get_slice_count" function.
	 * @param string The string.
	 * @param delimiter The splitter key.
	 * @return The total amount of slices.
	 */
	public static function getSliceCount(string:String, delimiter:String):Int {
		if (string.isBlank(false) || delimiter.isBlank(false)) return 0;

		var start = 0;
		var count = 1;
		while (true) {
			var index = string.indexOf(delimiter, start);
			if (index == -1) break; count++;
			start = index + delimiter.length;
		}
		return count;
	}

	inline public static function iterateSlices(string:String, delimiter:String):SliceIterator
		return new SliceIterator(string, delimiter);
	inline public static function iterateSlicesKV(string:String, delimiter:String):SliceKeyValueIterator
		return new SliceKeyValueIterator(string, delimiter);

	/**
	 * Checks if a string is blank.
	 * @param string The string.
	 * @param trim If true, it trims the string before checking.
	 * @return If true, the string is empty or null.
	 */
	inline public static function isBlank(string:String, trim:Bool = true):Bool {
		return string == null || (trim ? string.trim() : string).length == 0;
	}
	/**
	 * Checks if a string is blank, and if so, you can choose what to replace it with.
	 * @param string The string.
	 * @param newString The new string, can be null.
	 * @param trim If true, it trims the string before checking.
	 * @return If blank, it will return what you put for **"newString"**.
	 */
	inline public static function ifBlankReplace(string:String, ?newString:String, trim:Bool = true):Null<String>
		return string.isBlank(trim) ? newString : string;

	// From StringTools
	/**
	 * Checks if a string contains a set value.
	 * @param string The string.
	 * @param value The content to check for.
	 * @return If true, what you put for **"value"** exists within the contents of the string.
	 */
	inline public static function contains(string:String, value:String):Bool
		return StringTools.contains(string, value);

	/**
	 * Checks if a string starts with a set value.
	 * @param string Ths string.
	 * @param value The content to check for.
	 * @return If true, what you put for **"value"** is what's at the start of the string.
	 */
	inline public static function startsWith(string:String, value:String):Bool
		return StringTools.startsWith(string, value);
	/**
	 * Checks if a string ends with a set value.
	 * @param string Ths string.
	 * @param value The content to check for.
	 * @return If true, what you put for **"value"** is what's at the end of the string.
	 */
	inline public static function endsWith(string:String, value:String):Bool
		return StringTools.endsWith(string, value);

	@:inheritDoc(StringTools.isSpace)
	inline public static function isSpace(string:String, pos:Int):Bool
		return StringTools.isSpace(string, pos);

	/**
	 * Trims blank space on both sides of a string.
	 * @param string The string.
	 * @return Returns the string without empty characters on the sides.
	 */
	inline public static function trim(string:String):String
		return StringTools.trim(string);
	/**
	 * Trims blank space on the left side of a string.
	 * @param string The string.
	 * @return Returns the string without empty characters on the left side.
	 */
	inline public static function leftTrim(string:String):String
		return StringTools.ltrim(string);
	/**
	 * Trims blank space on the right side of a string.
	 * @param string The string.
	 * @return Returns the string without empty characters on the right side.
	 */
	inline public static function rightTrim(string:String):String
		return StringTools.rtrim(string);

	@:inheritDoc(StringTools.lpad)
	inline public static function leftPad(string:String, content:String, length:Int):String
		return StringTools.lpad(string, content, length);
	@:inheritDoc(StringTools.rpad)
	inline public static function rightPad(string:String, content:String, length:Int):String
		return StringTools.rpad(string, content, length);

	/**
	 * Replaces set parts of a string with a set value.
	 * @param string The string.
	 * @param sub The content to replace.
	 * @param replacement The content to use instead.
	 * @return Returns the string but with every instance of **"sub"** being replaced by **"replacement"**.
	 */
	inline public static function replace(string:String, sub:String, replacement:String):String
		return StringTools.replace(string, sub, replacement);

	@:noCompletion inline public static function iterator(string:String):StringIterator
		return new StringIterator(string);
	@:noCompletion inline public static function keyValueIterator(string:String):StringKeyValueIterator
		return new StringKeyValueIterator(string);
}

private class SliceIterator {
	var offset:Int = 0;
	var string:String; var delimiter:String;
	inline public function new(string:String, delimiter:String) {
		this.string = string;
		this.delimiter = delimiter;
	}
	inline public function hasNext() return offset < string.getSliceCount(delimiter);
	inline public function next() return string.getSlice(delimiter, offset++);
}
private class SliceKeyValueIterator {
	var offset:Int = 0;
	var string:String; var delimiter:String;
	inline public function new(string:String, delimiter:String) {
		this.string = string;
		this.delimiter = delimiter;
	}
	inline public function hasNext() return offset < string.getSliceCount(delimiter);
	inline public function next() return {key: offset, value: string.getSlice(delimiter, offset++)}
}