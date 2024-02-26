package;

import VFS.SongObject;
import audio.Context;
import audio.Sound;
import elements.*;
import haxe.Json;
import haxe.ds.DynamicMap;
import js.Syntax;
import js.html.Blob;
import js.html.File;

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
				HTML.fileSelect("audio/*,.json", (file) ->
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
				var music:Sound = Main.music;
				if (music.playing)
					music.stop();

				music.loadFromBlob(song.data);
				music.play(0, true);

				new Notification('Playing ${name}', 'by ${song.author}');
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
			size: 0,
			cover_art: null,
			cover_background: null,
			author: "",
			favourite: false
		};

		function jsConvertDone(blob:Blob)
		{
			songData.data = blob;
			songData.size = blob.size;

			Console.debug("Data converted (File -> Blob)!");
		}

		Syntax.code("new Response({0}.stream()).blob().then((blob) => { {1}(blob) })", file, jsConvertDone);

		return [
			new MEntry("Cancel import", () ->
			{
				file = null;
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
			new MEntry("Cover Art", () -> {
				// pending
			}),
			new MEntry("Cover Background", () -> {
				// pending
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
							new Notification("Finished importing", 'New song');
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
		var strUsage:MEntry = new MEntry("Storage Usage: ?");

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
				size += song.size;
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
			strUsage
		];
	}
}
