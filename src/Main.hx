package;

import audio.Context;
import audio.Sound;
import core.LifeCycle;
import discord.Gateway;
import discord.presence.PresenceBuilder;
import elements.*;
import haxe.Json;
import haxe.Resource;
import haxe.crypto.Base64;
import js.html.ScriptElement;

// idk if im dumb or smth but im adding another div inside the wrapper on a shadow element which the wrapper should be the shadow root but since i cannot add a shadow root in haxe i use a wrapper and im dumb and fuck
class Main
{
	public static var context:Context = new Context();
	public static var sound:Sound = new Sound();
	public static var notification:Notification = new Notification();

	public static var storage:VFS = new VFS();
	private static var musicList:MList = new MList([]);

	public static function main()
	{
		Console.log("Hello!");
		Console.log('NEOPlayer V${Resource.getString("version")} (From Resource)');
		Console.debug(HTML.detectDevice());

		LifeCycle.initialize();
		ComboBox.visibleCheck();
		Network.prepareSessionID();
		Endpoint.ping();

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
		var svToken:String = HTML.localStorage().getItem("discord-token");
		if (svToken != null)
		{
			Gateway.Initialize({
				applicationName: "NEOPlayer",
				applicationID: "1193103722021126195",
				onTokenRequest: () ->
				{
					return Base64.decode(svToken).toString();
				},
				onReady: () ->
				{
					Console.success("Authenticated on the Gateway!");
					new PresenceBuilder(GAME).addDetails("On the menus").addLargeAsset("haxelogo", "Using HxDiscordGateway!").send();
				}
			});
		}

		Network.loadBytes('./assets/album-placeholder.png').handle((out) ->
		{
			switch (out)
			{
				case Success(_):
					Console.success('Loaded album-placeholder.png');
				case Failure(e):
					Console.error(e);
			}
		});

		for (style in ["BasicTransition", 'TextBox', "ComboBox", "Switch"])
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
			Styling.setRootVar(HUE, info.hue);
			Styling.setRootVar(SATURATION, info.saturation);
		}

		// This will get deleted after creating a new one
		var deleted:String = HTML.localStorage().getItem("idb-deleted");
		if (deleted != null)
			Console.success('Deleted IndexedDB at ${HTML.localStorage().getItem("idb-del-time")}!');
	}

	// opps in da hood
	private static function dbOps()
	{
		musicList.refresh(Entries.defaultEntries());
		Notification.show("Database", "Connected");
	}
}
