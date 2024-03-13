package;

import haxe.ds.ArraySort;

// Used to keep the parent variable in map sorting
private typedef ValueRef =
{
	var ref:Any;
	var val:Any;
}

class Utils
{
	public static function sortMap(map:Map<Any, Any>, cmp:(Any, Any) -> Int):Map<Any, Any>
	{
		var sorted:Map<Any, Any> = new Map<Any, Any>();

		var _sort:Array<Any> = [];
		var _refs:Array<ValueRef> = [];

		for (key => value in map)
		{
			_sort.push(value);
			_refs.push({ref: value, val: key});
		}

		_sort.sort(cmp);

		// I don't know how I fixed this but it works now LOL
		var i:Int = 0;
		while (i < _sort.length)
		{
			var ref:ValueRef = _refs[i];
			var sort:Any = _sort[i];

			if (ref.ref == sort && !sorted.exists(ref.val))
			{
				sorted.set(ref.val, sort);
				i++;
				continue;
			}
			else
			{
				// Remove the first element and then push it to the end of the array
				_refs.push(_refs.shift());
				continue;
			}
		}

		_sort = _refs = null;
		map = null;

		return sorted;
	}

	// kind of hardcoded but its supposed to give only support for saved objects lol
	public static function dateMapSort(map:Map<Any, Any>, reverse:Bool):Map<Any, Any>
	{
		final field:String = "created_at";

		var cmp:(Any, Any) -> Int = (v1, v2) ->
		{
			var v1Has:Bool = Reflect.hasField(v1, field);
			var v2Has:Bool = Reflect.hasField(v2, field);

			if (v1Has && v2Has)
			{
				var v1V:Date = Reflect.field(v1, field);
				var v2V:Date = Reflect.field(v2, field);

				var i:Int = 0;
				if (v1V.getTime() > v2V.getTime())
					i = 1;

				if (v1V.getTime() < v2V.getTime())
					i = -1;

				return i * (reverse ? -1 : 1);
			}

			return 0;
		}

		return sortMap(map, cmp);
	}

	public static function truncateFloat(number:Float, prec:Int):Float
	{
		var num:Float = number * Math.pow(10, prec);
		return Math.round(num) / Math.pow(10, prec);
	}

	public static function roundDecimal(value:Float, prec:Int):Float
	{
		var mult:Float = 1;
		for (i in 0...prec)
		{
			mult *= 10;
		}
		return Math.fround(value * mult) / mult;
	}

	public static function parseSize(size:Float):{size:Float, unit:String}
	{
		var i:Int = 0;

		while (size > VFS.mbSize && i < VFS.intervalArray.length - 1)
		{
			i++;
			size = size / VFS.mbSize;
		}
		size = Math.round(size * 100) / 100;

		return {size: size, unit: VFS.intervalArray[i]};
	}
}
