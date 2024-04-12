package;

class Utils
{
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
