package;

import js.html.CSSStyleDeclaration;

enum abstract RootVars(String) to String from String
{
	/* HSL */
	var HUE = "--hue";
	var SATURATION = "--saturation";
	var FG_PCT = "--fg-pct";
	var BG_PCT = "--bg-pct";
	var DF_PCT = "--df-pct";

	/* ACCENTS */
	var FOREGROUND_ACCENT = "--foreground-accent";
	var BACKGROUND_ACCENT = "--background-accent";
	var ACCENT = "--accent";

	/* SPACING */
	var DEFAULT_PADDING = "--default-padding";
	var HALF_PADDING = "--half-padding";
	var DEFAULT_MARGIN = "--default-margin";
	var TEXTBOX_OFFSET = "--textbox-offset";

	/* SCROLLING ANIMATION */
	var SCROLL_TIME = "--scroll-time";
	var SCROLL_DELAY = "--scroll-delay";
	var SCROLL_LENGTH = "--scroll-length";

	/* MISC */
	var FONT_FAMILY = "--font-family";
	var MAIN_TRANSITION = "--main-transition";
	var COMBOBOX_PRIORITYZ = "--combobox-priorityZ";
	var COMBOBOX_TOPZ = "--combobox-topZ";
	var LIST_WIDTH = "--list-width";
	var TOPMOST = "--topmost";
}

class Styling
{
	// 20% is the sweet spot bet
	// 0 red, 120 green, 240 blue aprox, differs on the saturation lmfao
	public static var themes:Map<String, String> = [
		"default" => "hue:185|saturation:20%",
		"gray" => "hue:0|saturation:0%",
		"red" => "hue:0|saturation:20%",
		"green" => "hue:120|saturation:20%",
		"blue" => "hue:200|saturation:20%",
		"brown" => "hue:25|saturation:20%",
	];

	public static function getComputedRoot():CSSStyleDeclaration
		return HTML.window().getComputedStyle(HTML.dom().querySelector(":root"));

	public static function getCurrentRoot():CSSStyleDeclaration
		return HTML.dom().querySelector(":root").style;

	public static function arrowSVG(w:String, h:String):String
	{
		return '<!-- Uploaded to: SVG Repo, www.svgrepo.com, Generator: SVG Repo Mixer Tools - arrow_up [#337] Created with Sketch. -->
        <svg width="${w}" height="${h}" viewBox="0 -4.5 20 20" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g id="Page-1" stroke="none" stroke-width="1" fill="currentColor" fill-rule="evenodd"><g id="Dribbble-Light-Preview" transform="translate(-260.000000, -6684.000000)" fill="currentColor"><g id="icons" transform="translate(56.000000, 160.000000)"><path d="M223.707692,6534.63378 L223.707692,6534.63378 C224.097436,6534.22888 224.097436,6533.57338 223.707692,6533.16951 L215.444127,6524.60657 C214.66364,6523.79781 213.397472,6523.79781 212.616986,6524.60657 L204.29246,6533.23165 C203.906714,6533.6324 203.901717,6534.27962 204.282467,6534.68555 C204.671211,6535.10081 205.31179,6535.10495 205.70653,6534.69695 L213.323521,6526.80297 C213.714264,6526.39807 214.346848,6526.39807 214.737591,6526.80297 L222.294621,6534.63378 C222.684365,6535.03868 223.317949,6535.03868 223.707692,6534.63378" id="arrow_up-[#337]"></path></g></g></g></svg>';
	}

	public static function setRootVar(property:RootVars, value:Any)
		getCurrentRoot().setProperty(property, Std.string(value));

	public static function getRootVar(property:RootVars):String
		return getCurrentRoot().getPropertyValue(property);

	public static function getComputedRootVar(property:RootVars):String
		return getComputedRoot().getPropertyValue(property);

	public static function parsePX(string:String):Float
		return Std.parseFloat(string.substring(0, string.indexOf("px")));

	public static function parseTime(string:String, separator:String = "s"):Float
		return Std.parseFloat(string.substring(0, string.indexOf(separator)));
}
