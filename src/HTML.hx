package;

import audio.MediaMetadata;
import js.Browser;
import js.Syntax;
import js.html.AudioElement;
import js.html.File;
import js.html.HTMLDocument;
import js.html.InputElement;
import js.html.Storage;
import js.html.URL;
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

	// Move to Audio Soon
	// https://stackoverflow.com/a/61035921
	private static var _prevMeta:Null<MediaMetadata> = null;

	public static function setMediaMetadata(meta:MediaMetadata)
	{
		if (_prevMeta != meta)
		{
			// revoke created obj urls just in case
			if (_prevMeta != null && _prevMeta.artwork != null)
			{
				for (art in _prevMeta.artwork)
				{
					URL.revokeObjectURL(art.src);
				}
			}
			_prevMeta = meta;
		}

		Syntax.code('
			if (!"mediaSession" in navigator)
			{
				console.log("Media Session API not available");
				return;
			}

			var artwork = [];
			{0}.artwork.forEach((art) =>
			{
				artwork.push(art);
			});

			navigator.mediaSession.metadata = new MediaMetadata({
				title: {0}.title,
				artist: {0}.author,
				artwork: artwork
			});

			{0}.handlers.forEach((handler) => 
			{
				navigator.mediaSession.setActionHandler(handler.type, function() { handler.func(); });
			});
		', meta);

	}

	public static function updatePositionState(state:PositionState)
	{
		Syntax.code('
			if (!"mediaSession" in navigator)
			{
				console.log("Media Session API not available");
				return;
			}

			navigator.mediaSession.setPositionState({
				duration: {0}.duration,
				playbackRate: {0}.playbackRate,
				position: {0}.position
			});
		', state);

	}

	// Opens a quick file select window and executes the provided callbacks
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

	public static function addMusicListeners(music:AudioElement)
	{
		updatePositionState({
			duration: 0,
			position: 0,
			playbackRate: 1
		});

		music.addEventListener('timeupdate', () ->
		{
			updatePositionState({
				duration: music.duration,
				position: music.currentTime,
				playbackRate: music.playbackRate
			});
		});
	}

	public static function confirmation(message:String, onConfirm:Bool->Void)
	{
		Syntax.code("{0}(confirm({1}))", onConfirm, message);
	}

	public static function detectDevice():DeviceType
		return ~/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/.match(Browser.navigator.userAgent) ? DeviceType.MOBILE : DeviceType.DESKTOP;

	public static function isIOS():Bool
		return ~/iPhone|iPad|iPod/.match(Browser.navigator.userAgent);

	// dummy
	public static function onChrome():Bool
		return ~/Chrome/.match(Browser.navigator.userAgent);
}
