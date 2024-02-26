package;

import elements.*;
import js.Browser;
import js.html.File;
import js.html.HTMLDocument;
import js.html.InputElement;
import js.html.Storage;
import js.html.Window;

enum DeviceType
{
	MOBILE;
	DESKTOP;
}

class HTML
{
	public static function window():Window
		return Browser.window;

	public static function dom():HTMLDocument
		return Browser.document;

	public static function localStorage():Storage
		return Browser.getLocalStorage();

	// Opens a quick file select window and executes the provided callbacks
	// Accepts audio and json, json for the future quick metadata import
	public static function fileSelect(accept:String, onFile:File->Void)
	{
		var input:InputElement = dom().createInputElement();
		input.type = "file";
		input.accept = accept;
		input.click();

		input.addEventListener('change', () ->
		{
			if (input.files == null)
			{
				Console.error("No file specified on File Select!");
				return;
			}

			onFile(input.files[0]);
		});
	}

	public static function detectDevice():DeviceType
		return ~/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/.match(Browser.navigator.userAgent) ? DeviceType.MOBILE : DeviceType.DESKTOP;
}
