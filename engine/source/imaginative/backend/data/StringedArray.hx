package imaginative.backend.data;

/**
 * For less array usage, and hopefully is more optimized.
 */
abstract StringedArray(String) from String to String {
	@:inheritDoc(Array.length)
	public var length(get, never):Int;
	inline function get_length():Int
		return Std.int(Math.max(0, this.getSliceCount(delimiter) - 1));

	public var delimiter(get, set):String;
	inline function get_delimiter():String
		return this.charAt(0);
	inline function set_delimiter(value:String):String {
		this = this.replace(delimiter, value);
		return value;
	}

	inline public function new(delimiter:String, ...list:String) {
		var lol = list.toArray();
		this = delimiter + lol.join(delimiter);
		lol.clear();
	}

	@:arrayAccess inline public function get(slot:Int):String
		return this.getSlice(delimiter, slot + 1);
	@:arrayAccess inline public function set(slot:Int, value:Any):Any {
		var lol:String = '';
		for (i => a in abstract)
			lol += delimiter + (i == slot ? Std.string(value ?? '') : a);
		this = lol;
		return value;
	}

	@:inheritDoc(Array.contains)
	public function contains(value:String):Bool {
		for (a in abstract)
			if (a == value)
				return true;
		return false;
	}

	inline public function iterator():StringedArrayIterator {
		return new StringedArrayIterator(abstract);
	}
	inline public function keyValueIterator():StringedArrayKeyValueIterator {
		return new StringedArrayKeyValueIterator(abstract);
	}

	@:from inline public static function fromArray(value:Array<Any>):StringedArray {
		for (i in 0...value.length) value[i] ??= '';
		var result = value.join('@');
		value.clear(); // ON PURPOSE
		return '@' + result;
	}
	@:to inline public function toArray():Array<String>
		return [for (i in abstract) i];

	@:to inline public function toInt():Array<Int>
		return [for (i in abstract) Std.parseInt(i)];
	@:to inline public function toFloat():Array<Float>
		return [for (i in abstract) Std.parseFloat(i)];
}

final class StringedArrayIterator {
	var offset:Int = 0;
	var string:StringedArray;
	inline public function new(string:StringedArray) this.string = string;
	inline public function hasNext() return offset < string.length;
	inline public function next() return string[offset++];
}
final class StringedArrayKeyValueIterator {
	var offset:Int = 0;
	var string:StringedArray;
	inline public function new(string:StringedArray) this.string = string;
	inline public function hasNext() return offset < string.length;
	inline public function next() return {key: offset, value: string[offset++]}
}