package;

import VFS.SongObject;
import YoutubeAPI;
import audio.*;
import discord.Gateway;
import elements.*;
import haxe.Json;
import haxe.crypto.Base64;
import haxe.ds.DynamicMap;
import haxe.io.Bytes;
import js.Syntax;
import js.html.Blob;
import js.html.File;
import js.html.SourceElement;
import js.html.URL;

// Class dedicated to generate entries for the list
class Entries
{
	public static function defaultEntries(musicList:MList):Array<MEntry>
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
						musicList.refresh(buildFromMap(musicList, songs));
				});
			}),
			new MEntry("Import Providers", () ->
			{
				BasicTransition.play((?_) ->
				{
					musicList.refresh(importOptions(musicList));
				});
			}),
			new MEntry('Import script'),
			new MEntry("Settings", () ->
			{
				BasicTransition.play((?_) ->
				{
					musicList.refresh(getSettings(musicList));
				});
			}),
			new MEntry("About", () ->
			{
				BasicTransition.play((?_) ->
				{
					musicList.refresh(getAbout(musicList));
				});
			})
		];
	}

	public static function importOptions(musicList:MList):Array<MEntry>
	{
		var ret:Array<MEntry> = [
			new MEntry("Go back", () ->
			{
				BasicTransition.play((?_) ->
				{
					musicList.refresh(defaultEntries(musicList));
				});
			})
		];

		ret.push(new MEntry('Local Import', () ->
		{
			// Accepts audio and json, json for the future quick metadata import
			// ,.json
			var accepts:String = HTML.detectDevice() == DESKTOP ? "audio/*" : "audio/mpeg,audio/wav,audio/ogg,audio/aac,audio/m4a,audio/x-m4a";
			HTML.fileSelect(accepts, (file) ->
			{
				BasicTransition.play((?_) ->
				{
					musicList.refresh(genUpload(musicList, file));
				});
			});
		}));

		if (Endpoint.ONLINE)
		{
			ret.push(new MEntry("Import from Youtube", () ->
			{
				if (!Endpoint.ONLINE)
					return;

				BasicTransition.play((?_) ->
				{
					musicList.refresh(youtubeImporter(musicList));
				});
			}));
		}

		return ret;
	}

	public static function buildFromMap(musicList:MList, map:DynamicMap<String, Any>):Array<MEntry>
	{
		var ret:Array<MEntry> = [
			new MEntry("Go back", () ->
			{
				BasicTransition.play((?_) ->
				{
					musicList.refresh(defaultEntries(musicList));
				});
			})
		];

		for (name => song in map)
		{
			// its the last one anyways lmao
			if (name == "length")
				break;

			var song:SongObject = song;

			var entry:MEntry = new MEntry(name, () ->
			{
				var srcEl:SourceElement = HTML.dom().createSourceElement();

				if (Main.music.firstElementChild != null)
				{
					var objURL:String = Main.music.firstElementChild.getAttribute("objurl");
					Main.music.pause();
					URL.revokeObjectURL(objURL);
					Console.debug('Revoked Audio Blob URL ($objURL)');

					var copycat = Main.music.cloneNode();
					Main.music.replaceWith(copycat);
					Main.music = cast copycat;
					HTML.addMusicListeners(Main.music);
				}

				srcEl.src = URL.createObjectURL(song.data.blob);
				srcEl.type = song.data.mimeType;
				srcEl.setAttribute("objurl", srcEl.src);
				Main.music.setAttribute("musicname", song.name);
				Main.music.setAttribute("musicauthor", song.author);
				Main.music.append(srcEl);
				PlayerHandler.play();

				new Notification('Playing ${name}', 'by ${song.author}', (song.cover_art != null) ? URL.createObjectURL(song.cover_art.blob) : null);

				var meta:MediaMetadata = {
					title: name,
					author: song.author,
					artwork: [],
					handlers: [
						{
							type: PLAY,
							func: () -> PlayerHandler.play()
						},
						{
							type: PAUSE,
							func: () -> PlayerHandler.pause()
						},
						{
							type: SEEK_BACKWARD,
							func: () -> PlayerHandler.seekBackward()
						},
						{
							type: SEEK_FORWARD,
							func: () -> PlayerHandler.seekForward()
						}
					]
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

	public static function genUpload(musicList:MList, file:File):Array<MEntry>
	{
		var songData:SongObject = {
			name: "",
			data: null,
			cover_art: null,
			cover_background: null,
			author: "",
			favourite: false
		};

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
			new MEntry("Cancel import", () ->
			{
				songData = null;
				Console.debug("User canceled the song import");
				BasicTransition.play((?_) ->
				{
					musicList.refresh(defaultEntries(musicList));
				});
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
				Main.storage.set(SONGS, songData.name, songData).handle((out) ->
				{
					var res:Bool = out.sure();
					if (res)
					{
						BasicTransition.play((?_) ->
						{
							new Notification("Finished importing", 'New song',
								(songData.cover_art != null) ? URL.createObjectURL(songData.cover_art.blob) : null);
							musicList.refresh(defaultEntries(musicList));
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

	public static function youtubeImporter(musicList:MList):Array<MEntry>
	{
		var target:Int = 2;
		var steps:Int = 0;
		var status:MEntry = new MEntry('Pending assets: $steps/$target', true);

		var song:VFS.SongObject = {
			name: "",
			author: "",
			data: null,
			cover_art: null,
			cover_background: null,
			favourite: false
		};

		return [
			new MEntry("Go back", () ->
			{
				BasicTransition.play((?_) ->
				{
					musicList.refresh(defaultEntries(musicList));
				});
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
									new Notification("Finished importing", 'New song',
										(song.cover_art != null) ? URL.createObjectURL(song.cover_art.blob) : null);
									musicList.refresh(defaultEntries(musicList));
								});
							}
						});
					});
				}

				function checkTick()
				{
					haxe.Timer.delay(() ->
					{
						if (steps == target)
						{
							onFinish();
							return;
						}

						checkTick();
					}, 1);
				}

				checkTick();
			}),
		];
	}

	// formatting for sure is killing my eyes
	public static function getSettings(musicList:MList):Array<MEntry>
	{
		return [
			new MEntry("Go back", () ->
			{
				BasicTransition.play((?_) ->
				{
					musicList.refresh(defaultEntries(musicList));
				});
			}),
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

			new MEntryTB("User Token", function(token:String)
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
				@:privateAccess
				tb.input.type = "password";

				var svToken:String = HTML.localStorage().getItem("discord-token");
				if (svToken == null)
					return;

				tb.value = Base64.decode(svToken).toString();
			}),
			new MEntry("Remove Token", () ->
			{
				HTML.localStorage().removeItem("discord-token");
				Gateway.Shutdown();
				haxe.Timer.delay(() ->
				{
					HTML.window().location.reload();
				}, 15);
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
				Styling.setRootVarValue(HUE, hue);
				Styling.setRootVarValue(SATURATION, sat);
				HTML.localStorage().setItem("chosen-preset", Std.string(ev.index));
				HTML.localStorage().setItem("theme-info", Json.stringify({hue: hue, saturation: sat}));
			}),
			new MEntry("Make your own theme!", true),
			new MEntry("Hue"),
			new MEntry("Saturation")
		];
	}

	public static function getAbout(musicList:MList):Array<MEntry>
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

		return [
			new MEntry("Go back", () ->
			{
				BasicTransition.play((?_) ->
				{
					musicList.refresh(defaultEntries(musicList));
				});
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
			})
		];
	}
}
