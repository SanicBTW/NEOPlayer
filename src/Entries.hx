package;

import VFS.SongObject;
import audio.MediaMetadata;
import elements.*;
import haxe.Json;
import haxe.ds.DynamicMap;
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
			new MEntry('Import song', () ->
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

	public static function buildFromMap(musicList:MList, map:DynamicMap<String, Any>):Array<MEntry>
	{
		var ret:Array<MEntry> = [];

		var backBtn:MEntry = new MEntry("Go back", () ->
		{
			BasicTransition.play((?_) ->
			{
				musicList.refresh(defaultEntries(musicList));
			});
		});
		ret.push(backBtn);

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
				Main.music.append(srcEl);
				Main.music.play();

				new Notification('Playing ${name}', 'by ${song.author}', (song.cover_art != null) ? URL.createObjectURL(song.cover_art.blob) : null);

				var meta:MediaMetadata = {
					title: name,
					author: song.author,
					artwork: [],
					handlers: [
						{
							type: PLAY,
							func: () -> Main.music.play()
						},
						{
							type: PAUSE,
							func: () -> Main.music.pause()
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
			new MEntry('Preset Themes', true),
			new MEntryCB('Current preset: default', Styling.themes, (cb) ->
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
			}, (ev) ->
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
				function confirmation(state:Bool)
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
				}
				Syntax.code('{0}(confirm({1}))', confirmation,
					"Are you sure you want to proceed?\nAll the data inside the database will be deleted and won't be accessible again");
			})
		];
	}
}
