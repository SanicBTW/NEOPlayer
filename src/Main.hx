package;

import VFS.SongObject;
import audio.Context;
import audio.Sound;
import elements.*;
import haxe.Json;
import js.html.Blob;

// idk if im dumb or smth but im adding another div inside the wrapper on a shadow element which the wrapper should be the shadow root but since i cannot add a shadow root in haxe i use a wrapper and im dumb and fuck
class Main
{
	private static var context:Context;
	public static var music:Sound = new Sound(); // force it to ONLY one sound playing, also empty for quick stuff lmao

	public static var storage:VFS = new VFS();
	private static var musicList:MList = new MList([]);

	public static function main()
	{
		Console.log("Hello!");
		Console.debug(HTML.detectDevice());
		ComboBox.visibleCheck();
		HTML.dom().body.classList.add('mx-auto', 'my-auto', 'overflow-hidden');
		context = new Context();

		BasicTransition.play((?_) ->
		{
			var rawInfo:String = HTML.localStorage().getItem("theme-info");
			if (rawInfo != null)
			{
				var info:{hue:String, saturation:String} = Json.parse(rawInfo);
				Styling.setRootVarValue(HUE, info.hue);
				Styling.setRootVarValue(SATURATION, info.saturation);
			}
		});

		preload();

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
	}

	// opps in da hood
	private static function dbOps()
	{
		musicList.refresh(Entries.defaultEntries(musicList));
		new Notification("Database", "Connected");
	}
}
