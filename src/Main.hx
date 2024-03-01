package;

import elements.*;
import haxe.Json;
import js.html.AudioElement;
import js.html.ScriptElement;

// idk if im dumb or smth but im adding another div inside the wrapper on a shadow element which the wrapper should be the shadow root but since i cannot add a shadow root in haxe i use a wrapper and im dumb and fuck
// had to move from AudioContext to AudioElement for a lot of reasons
class Main
{
	public static var music:AudioElement = HTML.dom().createAudioElement();

	public static var storage:VFS = new VFS();
	private static var musicList:MList = new MList([]);

	public static function main()
	{
		Console.log("Hello!");
		Console.debug(HTML.detectDevice());
		ComboBox.visibleCheck();
		Network.prepareSessionID();
		HTML.dom().body.classList.add('mx-auto', 'my-auto', 'overflow-hidden');

		#if debug
		if (HTML.detectDevice() == MOBILE)
		{
			var erudaInit:ScriptElement = HTML.dom().createScriptElement();
			erudaInit.text = "eruda.init();";

			var eruda:ScriptElement = HTML.dom().createScriptElement();
			eruda.src = "//cdn.jsdelivr.net/npm/eruda";
			eruda.addEventListener('load', () -> HTML.dom().head.append(erudaInit));

			HTML.dom().head.append(eruda);
		}
		#end

		music.controls = false;
		music.loop = true;
		HTML.addMusicListeners(music);
		HTML.dom().body.append(music);

		preload();

		BasicTransition.play((?_) -> {});

		storage.create().handle((out) ->
		{
			switch (out)
			{
				case Success(_):
					Console.debug("Database Opened");
					dbOps();
				case Failure(e):
					Console.error(e);
			}
		});
	}

	private static function preload()
	{
		for (style in ["BasicTransition", 'TextBox', "ComboBox"])
		{
			Network.loadString('./stylesheets/$style.css').handle((out) ->
			{
				switch (out)
				{
					case Success(_):
						Console.success('Loaded $style.css');
					case Failure(e):
						Console.error(e);
				}
			});
		}

		var rawInfo:String = HTML.localStorage().getItem("theme-info");
		if (rawInfo != null)
		{
			var info:{hue:String, saturation:String} = Json.parse(rawInfo);
			Styling.setRootVarValue(HUE, info.hue);
			Styling.setRootVarValue(SATURATION, info.saturation);
		}

		// This will get deleted after creating a new one
		var deleted:String = HTML.localStorage().getItem("idb-deleted");
		if (deleted != null)
			Console.success('Deleted IndexedDB at ${HTML.localStorage().getItem("idb-del-time")}!');
	}

	// opps in da hood
	private static function dbOps()
	{
		musicList.refresh(Entries.defaultEntries(musicList));
		new Notification("Database", "Connected");
	}
}
