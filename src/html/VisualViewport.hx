package html;

import js.Syntax;
import js.html.Event;

enum abstract VVEvent(String) to String from String
{
	var RESIZE = "resize";
	var SCROLL = "scroll";
}

// I know there is some "externs" for the VisualViewport but they aren't exposed on js.Browser yet
class VisualViewport
{
	public static var width(get, null):Float;

	@:noCompletion
	private static function get_width():Float
		return Syntax.code("window.visualViewport.width");

	public static var height(get, null):Float;

	@:noCompletion
	private static function get_height():Float
		return Syntax.code("window.visualViewport.height");

	public static var scale(get, null):Float;

	@:noCompletion
	private static function get_scale():Float
		return Syntax.code("window.visualViewport.scale");

	public static var offsetLeft(get, null):Float;

	@:noCompletion
	private static function get_offsetLeft():Float
		return Syntax.code("window.visualViewport.offsetLeft");

	public static var offsetTop(get, null):Float;

	@:noCompletion
	private static function get_offsetTop():Float
		return Syntax.code("window.visualViewport.offsetTop");

	public static var pageLeft(get, null):Float;

	@:noCompletion
	private static function get_pageLeft():Float
		return Syntax.code("window.visualViewport.pageLeft");

	public static var pageTop(get, null):Float;

	@:noCompletion
	private static function get_pageTop():Float
		return Syntax.code("window.visualViewport.pageTop");

	public static function addEventListener(event:VVEvent, func:Event->Void):Void
	{
		Syntax.code("window.visualViewport.addEventListener({0}, {1})", event, func);
	}

	public static function removeEventListener(event:VVEvent, func:Event->Void):Void
	{
		Syntax.code("window.visualViewport.removeEventListener({0}, {1})", event, func);
	}
}
