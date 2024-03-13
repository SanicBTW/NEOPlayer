package;

import VFS.SongObject;
import YoutubeAPI;
import audio.*;
import core.LifeCycle;
import discord.Gateway;
import elements.*;
import haxe.Json;
import haxe.Resource;
import haxe.crypto.Base64;
import haxe.ds.DynamicMap;
import haxe.io.Bytes;
import js.Syntax;
import js.html.Blob;
import js.html.File;
import js.html.URL;

// Class dedicated to generate entries for the list
// I should rewrite this and make it modular ngl
class Entries
{
	private static var list(get, null):MList;

	@:noCompletion
	private static function get_list():MList
	{
		@:privateAccess
		return Main.musicList;
	}

	// dummy
	public static function generateBack(name:String = "Go back", func:Void->Array<MEntry> = null):MEntry
	{
		// dirtiest workaround lmao
		if (func == null)
			func = defaultEntries;

		return new MEntry(name, () ->
		{
			BasicTransition.play((?_) ->
			{
				list.refresh(func());
			});
		});
	}

	public static function defaultEntries():Array<MEntry>
	{
		return [
			new MEntry("List Songs", () ->
			{
				var songs:DynamicMap<String, Any> = null;
				Main.storage.entries(SONGS).handle((out) ->
				{
					songs = out.sure();
					Console.success('Got ${songs["length"]} song(s)');
				});

				BasicTransition.play((?_) ->
				{
					if (songs != null)
						list.refresh(buildFromMap(songs));
				});
			}),
			new MEntry("Import Providers", () ->
			{
				BasicTransition.play((?_) ->
				{
					list.refresh(importOptions());
				});
			}),
			new MEntry('Import script'),
			new MEntry("Settings", () ->
			{
				BasicTransition.play((?_) ->
				{
					list.refresh(getSettings());
				});
			}),
			new MEntry("About", () ->
			{
				BasicTransition.play((?_) ->
				{
					list.refresh(getAbout());
				});
			})
		];
	}

	public static function importOptions():Array<MEntry>
	{
		var ret:Array<MEntry> = [generateBack()];

		ret.push(new MEntry('Local Import', () ->
		{
			// Accepts audio and json, json for the future quick metadata import
			// ,.json
			var accepts:String = HTML.detectDevice() == DESKTOP ? "audio/*" : "audio/mpeg,audio/wav,audio/ogg,audio/aac,audio/m4a,audio/x-m4a";
			HTML.fileSelect(accepts, (file) ->
			{
				BasicTransition.play((?_) ->
				{
					list.refresh(genUpload(file));
				});
			});
		}));

		// improve this, since the public api is always returning 502 bad gateway and some other times it works fine i have to find an alternative way to host the api n shit :sob
		if (Endpoint.ONLINE)
		{
			ret.push(new MEntry("Import from Youtube", () ->
			{
				if (!Endpoint.ONLINE)
					return;

				BasicTransition.play((?_) ->
				{
					list.refresh(youtubeImporter());
				});
			}));
		}

		return ret;
	}

	// check if its playing or if its the same entry and play/pause depending on the state
	public static function buildFromMap(map:DynamicMap<String, Any>):Array<MEntry>
	{
		// map shit is useless here i think
		var filterCb:MEntryCB = new MEntryCB("Sort by", [
			"Recently Added" => "recently",
			"Alphabetical order" => "alphabet",
			"Origin" => "source",
			"Favourites" => "favourite",
			"Author" => "author"
		], function(cb)
		{
			@:privateAccess
			cb.wrapper.setAttribute("selectedindex", "0");
			trace("sup");
		}, function(ev)
		{
			trace(ev);
		});

		var ret:Array<MEntry> = [generateBack()];

		if (map.length() >= 2)
			ret.push(filterCb);

		for (name => song in map)
		{
			// its the last one anyways lmao
			if (name == "length")
				break;

			var song:SongObject = song;

			var entry:MEntry = new MEntry(name, () ->
			{
				Main.sound.play(song);

				var meta:MediaMetadata = {
					title: name,
					author: song.author,
					artwork: [],
					handlers: PlayerHandler.getHandlers()
				};

				if (song.cover_art != null)
				{
					var urlObj:String = URL.createObjectURL(song.cover_art.blob);

					// Force resolutions in order to make the Media Session API work properly
					for (size in ["96x96", "128x128", "192x192", "256x256", "384x384", "512x512"])
					{
						meta.artwork.push({
							src: urlObj,
							type: song.cover_art.mimeType,
							sizes: size
						});
					}
				}

				HTML.setMediaMetadata(meta);
			});

			ret.push(entry);
		}

		return ret;
	}

	public static function genUpload(file:File):Array<MEntry>
	{
		var songData:SongObject = VFS.makeEmptySong();

		function songConvertDone(blob:Blob)
		{
			songData.data = {
				blob: blob,
				mimeType: file.type
			};

			Console.debug("Song converted (File -> Blob)!");
		}

		Syntax.code("new Response({0}.stream()).blob().then((blob) => { {1}(blob) })", file, songConvertDone);

		return [
			generateBack("Cancel Import", () ->
			{
				songData = null;
				return importOptions();
			}),
			new MEntry("Song Metadata", true),
			new MEntryTB("Name", (name:String) ->
			{
				songData.name = name;
			}),
			new MEntryTB("Author", (author:String) ->
			{
				songData.author = author;
			}),
			new MEntry("Assets", true),
			new MEntry("Cover Art", () ->
			{
				HTML.fileSelect("image/*", (file) ->
				{
					function cartConvertDone(blob:Blob)
					{
						songData.cover_art = {
							blob: blob,
							mimeType: file.type
						};

						Console.debug("Cover Art converted (File -> Blob)!");
					}

					Syntax.code("new Response({0}.stream()).blob().then((blob) => { {1}(blob) })", file, cartConvertDone);
				});
			}),
			new MEntry("Cover Background", () ->
			{
				HTML.fileSelect("image/*", (file) ->
				{
					function cbgConvertDone(blob:Blob)
					{
						songData.cover_background = {
							blob: blob,
							mimeType: file.type
						};

						Console.debug("Cover Background converted (File -> Blob)!");
					}

					Syntax.code("new Response({0}.stream()).blob().then((blob) => { {1}(blob, {0}.type) })", file, cbgConvertDone);
				});
			}),
			new MEntry("Finish", () ->
			{
				if (songData.cover_art == null)
				{
					// only set if found on cache (most likely)
					@:privateAccess
					if (Network._cache["./assets/legacy-album.png"] != null)
					{
						songData.cover_art = {
							blob: Network.bufferToBlob(cast(Network._cache["./assets/legacy-album.png"], haxe.io.Bytes).b.buffer),
							mimeType: "image/png"
						};
					}
				}

				Main.storage.set(SONGS, songData.name, songData).handle((out) ->
				{
					var res:Bool = out.sure();
					if (res)
					{
						BasicTransition.play((?_) ->
						{
							Notification.show("Finished importing", 'New song',
								(songData.cover_art != null) ? URL.createObjectURL(songData.cover_art.blob) : null);
							list.refresh(defaultEntries());
						});
					}
					else
					{
						throw res;
					}
				});
			}),
		];
	}

	public static function youtubeImporter():Array<MEntry>
	{
		var target:Int = 2;
		var steps:Int = 0;
		var status:MEntry = new MEntry('Pending assets: $steps/$target', true);

		var song:VFS.SongObject = VFS.makeEmptySong();

		return [
			generateBack("Back to Import Providers", () ->
			{
				YoutubeAPI._curID = null;
				return importOptions();
			}),
			new MEntryTB("Youtube Link", (link:String) ->
			{
				var id:String = "";
				if (link.indexOf("youtu.be") > -1)
				{
					id = link.substring(link.lastIndexOf("/") + 1);
					if (id.indexOf("?") > -1)
						id = id.substring(0, id.indexOf("?"));
				}

				if (link.indexOf("youtube.com") > -1)
				{
					id = link.substring(link.indexOf("?") + 3);
					if (id.indexOf("&") > -1)
						id = id.substring(0, id.indexOf("&"));
				}
				YoutubeAPI._curID = id;
			}),
			status,
			new MEntry("Done", () ->
			{
				if (YoutubeAPI._curID != null && YoutubeAPI._curID.length <= 0)
					return;

				// long ahh function bro
				YoutubeAPI.getDetails(YoutubeAPI._curID).handle((det) ->
				{
					var infResp:InfoResponse = det.sure();

					song.name = infResp.title;
					song.author = infResp.author;

					YoutubeAPI.getAudio(infResp.title).handle((pra) ->
					{
						var res:BlobResponse = pra.sure();
						var data:Dynamic = res.data;
						var blob:Blob = Network.bufferToBlob(data.b.buffer);
						song.data = {
							blob: blob,
							mimeType: res.mimeType
						};
						steps++;
						status.name.textContent = 'Pending assets: $steps/$target';
					});

					// force to wait for the thumbnail
					// should improve race conditions, last day it failed to get the thumbnail but could continue anyway, will need to do more testing or move to a websocket
					var hdThumb:ThumbnailObject = infResp.thumbnails[infResp.thumbnails.length - 1]; // the last one is usually 1920x1080
					YoutubeAPI.getThumbnail(hdThumb.url).handle((pri) ->
					{
						var res:BlobResponse = pri.sure();
						var data:Dynamic = res.data;
						var blob:Blob = Network.bufferToBlob(data.b.buffer);
						song.cover_art = {
							blob: blob,
							mimeType: res.mimeType
						};
						steps++;
						status.name.textContent = 'Pending assets: $steps/$target';
					});
				});

				// dirty approach imo

				function onFinish()
				{
					Main.storage.get(SONGS, song.name).handle((existCheck) ->
					{
						if (existCheck.sure() != null)
							return;

						Main.storage.set(SONGS, song.name, song).handle((sOut) ->
						{
							var res:Bool = sOut.sure();
							if (res)
							{
								YoutubeAPI._curID = null;
								BasicTransition.play((?_) ->
								{
									Notification.show("Finished importing", 'New song',
										(song.cover_art != null) ? URL.createObjectURL(song.cover_art.blob) : null);
									list.refresh(defaultEntries());
								});
							}
						});
					});
				}

				LifeCycle.add((_) ->
				{
					if (steps == target)
					{
						onFinish();
						return STOPPED;
					}

					return RUNNING;
				});
			}),
		];
	}

	// formatting for sure is killing my eyes
	public static function getSettings():Array<MEntry>
	{
		return [
			generateBack(),
			// More flexible system soon??? (Custom paths n more!! - maybe with the modding support being able to change some routes, that would be sick)
			new MEntry("API Settings", true),
			new MEntryTB("Youtube API Endpoint", function(newEnd:String)
			{
				HTML.confirmation("Are you sure you want to change the Youtube API Endpoint?\nOnly change this if the provided server is slow or you're hosting one by yourself.\nThe page will refresh and set the provided Endpoint when you click \"OK\".\n*This will only work when using the API Provided in the Github Repo*",
					(state:Bool) ->
					{
						if (!state)
							return;

						Endpoint.API = newEnd;
						HTML.window().location.reload();
					});
			}, function(tb)
			{
				tb.value = Endpoint.API;
			}),
			new MEntry("Discord Gateway (Experimental)
				Know this is optional and not required to make the app fully work
				DO NOT give your token in random sites and only on secure ones
				Please, proceed with caution, you can always remove your token afterwards
			", true),

			new MEntryTB("User Token (Hidden)", function(token:String)
			{
				HTML.confirmation("Are you sure you want to set your Discord User Token?\nThis will show a Rich Presence in your Discord Profile\nOnce you press \"OK\" the page will refresh and a connection to\nthe Discord Gateway will be established",
					(state:Bool) ->
					{
						if (!state)
							return;

						HTML.localStorage().setItem("discord-token", Base64.encode(Bytes.ofString(token)));
						HTML.window().location.reload();
					});
			}, function(tb)
			{
				// made it like this so the DOM stops complaining about the fucking input type password not in a form warning
				@:privateAccess
				{
					tb.input.classList.add("password");
					tb.input.placeholder = "";
					tb.input.ondrag = tb.input.ondrop = tb.input.ondragstart = (ev) ->
					{
						ev.preventDefault();
					}
				}

				var svToken:String = HTML.localStorage().getItem("discord-token");
				if (svToken == null)
					return;

				tb.value = Base64.decode(svToken).toString();
			}),
			new MEntry("Remove Token", () ->
			{
				if (HTML.localStorage().getItem("discord-token") == null)
					return;

				HTML.localStorage().removeItem("discord-token");
				Gateway.Shutdown();
				LifeCycle.timer(15, (?_) ->
				{
					HTML.window().location.reload();
				});
			}),
			new MEntry('Preset Themes', true),
			new MEntryCB('Current preset: default', Styling.themes, function(cb)
			{
				// this will not work if the user changed manually the theme, it will get the saved themes from the local storage then append it to the entries hehe
				@:privateAccess
				{
					var savedPres:String = HTML.localStorage().getItem("chosen-preset");
					if (savedPres != null)
					{
						cb.wrapper.setAttribute("selectedindex", savedPres);
						cb.header.textContent = 'Current preset: ${cb.items.children.item(Std.parseInt(savedPres)).textContent}';
					}
					else
					{
						cb.wrapper.setAttribute("selectedindex", "0");
					}
				}
			}, function(ev)
			{
				@:privateAccess
				ev.parent.header.textContent = 'Current preset: ${ev.name}';
				var values:Array<String> = ev.value.split("|");
				var hue:String = values[0].split(":")[1];
				var sat:String = values[1].split(":")[1];
				Styling.setRootVar(HUE, hue);
				Styling.setRootVar(SATURATION, sat);
				HTML.localStorage().setItem("chosen-preset", Std.string(ev.index));
				HTML.localStorage().setItem("theme-info", Json.stringify({hue: hue, saturation: sat}));
			}),
			new MEntry("Make your own theme!", true),
			new MEntry("Hue"),
			new MEntry("Saturation")
		];
	}

	public static function getAbout():Array<MEntry>
	{
		var strUsage:MEntry = new MEntry("Storage Usage: ?", true);

		Main.storage.entries(SONGS).handle((out) ->
		{
			var size:Float = 0;
			var idx:Int = 0;
			var data:DynamicMap<String, Any> = out.sure();
			for (name => song in data)
			{
				// its the last one anyways lmao
				if (name == "length")
					break;

				var song:SongObject = song;
				size += song.data.blob.size;

				// Make a section where it details properly where the entry displays tthe storage quota it uses??
				if (song.cover_art != null)
					size += song.cover_art.blob.size;

				if (song.cover_background != null)
					size += song.cover_background.blob.size;
			}

			while (size > 1000 && idx < VFS.intervalArray.length - 1)
			{
				idx++;
				size = size / 1000;
			}
			size = Math.round(size * 100) / 100;

			@:privateAccess
			strUsage.name.textContent = 'Storage Usage: ${size} ${VFS.intervalArray[idx]}';
		});

		// instead of manually setting the state outside the ticker, wait for the go back entry to be pressed and set the flag that will return STOPPED on the tickers
		// ok i did that
		var shouldStop:Bool = false;
		var fpsStat:MEntry = new MEntry("FPS: ?", true);
		LifeCycle.add((_) ->
		{
			if (shouldStop)
				return STOPPED;

			@:privateAccess
			fpsStat.name.textContent = 'FPS: ${Math.ceil(LifeCycle.fps)}';
			return RUNNING;
		});

		var ticksStat:MEntry = new MEntry("Ticks: ?", true);
		LifeCycle.add((_) ->
		{
			if (shouldStop)
				return STOPPED;

			@:privateAccess
			ticksStat.name.textContent = 'Ticks: ${LifeCycle.ticks}';
			return RUNNING;
		});

		return [
			generateBack(() ->
			{
				shouldStop = true;
				return defaultEntries();
			}),
			new MEntry("IndexedDB Stats", true),
			strUsage,
			new MEntry("Delete IndexedDB", () ->
			{
				HTML.confirmation("Are you sure you want to proceed?\nAll the data inside the database will be deleted and won't be accessible again",
					(state:Bool) ->
					{
						if (!state)
							return;

						// Close it to proceed with deletion
						Main.storage.destroy();

						var req = HTML.window().indexedDB.deleteDatabase(VFS.name);
						req.addEventListener('error', () ->
						{
							Console.error('Failed to delete IndexedDB: ${req.error.message}');
						});
						req.addEventListener('success', () ->
						{
							HTML.localStorage().setItem("idb-deleted", "true");
							HTML.localStorage().setItem("idb-del-time", Std.string(Date.now()));
							HTML.window().location.reload();
						});
					});
			}),
			new MEntry("LifeCycle Stats", true),
			fpsStat,
			ticksStat,
			new MEntry('NEOPlayer V${Resource.getString("version")}', true)
		];
	}
}
