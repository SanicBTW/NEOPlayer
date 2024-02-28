package;

import haxe.ds.DynamicMap;
import js.html.Blob;
import js.html.idb.*;

using tink.CoreApi;

enum abstract Tables(String) to String from String
{
	var SONGS = "songs";
	var SCRIPTS = "scripts";
}

typedef SongObject =
{
	var name:String;
	var data:Blob;
	var size:Int;
	var cover_art:Blob;
	var cover_background:Blob;
	var author:String;
	var favourite:Bool;
}

typedef ScriptObject =
{
	var name:String;
	var data:Blob;
	var source:String;
}

class VFS
{
	public static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB'];

	private var request:OpenDBRequest;
	private var connection:Database;

	private var version:Int;
	private var created:Bool = false;

	public function new(version:Int = 1)
	{
		this.version = version;
	}

	@async public function create():Promise<VFS>
	{
		if (created)
			return Promise.resolve(this);

		return Promise.irreversible((resolve, reject) ->
		{
			request = HTML.window().indexedDB.open('S_VirtualFS', version);

			request.addEventListener('error', () ->
			{
				reject(new Error(InternalError, request.error.message));
			});

			request.addEventListener('blocked', () ->
			{
				reject(new Error(Forbidden, request.error.message));
			});

			request.addEventListener('upgradeneeded', (ev) ->
			{
				var db:Database = ev.target.result;
				// TODO: When upgrading copy the old data and try to move it to the new version of the database
				/*
					if (db.objectStoreNames.contains("songs"))
					{
						var transaction:Transaction = db.transaction('songs', READONLY);
						trace(transaction);
						reject('Failed to upgrade on existing filesystem');
						//db.deleteObjectStore("filesystem");
				}*/

				if (!db.objectStoreNames.contains(Tables.SONGS))
				{
					var store:ObjectStore = db.createObjectStore(Tables.SONGS);

					// store.createIndex('data', 'data'); // BLOB
					store.createIndex('size', 'size'); // To get the size of the song
					// store.createIndex('cover_art', 'cover_art'); // BLOB
					// store.createIndex('cover_background', 'cover_background'); // BLOB
					store.createIndex('author', 'author'); // String - author or artist
					store.createIndex('favourite', 'favourite'); // Bool, sort favs??
				}

				if (!db.objectStoreNames.contains(Tables.SCRIPTS))
				{
					// experimental, uses hscript
					var store:ObjectStore = db.createObjectStore(Tables.SCRIPTS);

					// store.createIndex('data', 'data'); // BLOB
					store.createIndex('source', 'source'); // From where it is
				}
			});

			request.addEventListener('success', () ->
			{
				connection = request.result;
				created = true;
				resolve(this);
			});
		});
	}

	@async public function set(table:Tables, key:String, value:Any):Promise<Bool>
	{
		if (!created)
			return Promise.reject(new Error(InternalError, "Database not connected yet"));

		if (value == null)
			return remove(table, key);

		return Promise.irreversible((resolve, reject) ->
		{
			var res:Request = connection.transaction(table, READWRITE).objectStore(table).put(value, key);

			res.addEventListener('success', () ->
			{
				resolve(true);
			});

			res.addEventListener('error', () ->
			{
				reject(new Error(InternalError, res.error.message));
			});
		});
	}

	@async public function remove(table:Tables, key:String):Promise<Bool>
	{
		if (!created)
			return Promise.reject(new Error(InternalError, "Database not connected yet"));

		return Promise.irreversible((resolve, reject) ->
		{
			var res:Request = connection.transaction(table, READWRITE).objectStore(table).delete(key);

			res.addEventListener('success', () ->
			{
				resolve(true);
			});

			res.addEventListener('error', () ->
			{
				reject(new Error(InternalError, res.error.message));
			});
		});
	}

	@async public function get(table:Tables, key:String):Promise<Any>
	{
		if (!created)
			return Promise.reject(new Error(InternalError, "Database not connected yet"));

		return Promise.irreversible((resolve, reject) ->
		{
			var res:Request = connection.transaction(table, READWRITE).objectStore(table).get(key);

			res.addEventListener('success', () ->
			{
				if (res.result != null)
					resolve(res.result);
				else
					resolve(null);
			});

			res.addEventListener('error', () ->
			{
				reject(new Error(InternalError, res.error.message));
			});
		});
	}

	@async public function entries(table:Tables):Promise<DynamicMap<String, Any>>
	{
		if (!created)
			return Promise.reject(new Error(InternalError, "Database not connected yet"));

		return Promise.irreversible((resolve, reject) ->
		{
			var tempMap:DynamicMap<String, Any> = new DynamicMap();
			var length:Int = 0;

			var res:Request = connection.transaction(table, READONLY).objectStore(table).openKeyCursor();

			res.addEventListener('success', () ->
			{
				var cursor:Cursor = res.result;
				if (cursor == null || cursor.source == null)
				{
					tempMap["length"] = length;
					// End of cycling between entries
					resolve(tempMap);
					return;
				}

				var objStr:ObjectStore = cursor.source;
				var obj:Request = objStr.get(cursor.key);
				length++;

				obj.addEventListener('success', () ->
				{
					tempMap[cursor.key] = obj.result;
					cursor.advance(1);
				});
			});

			res.addEventListener('error', () ->
			{
				reject(new Error(InternalError, res.error.message));
			});
		});
	}

	public function destroy():Void
	{
		connection.close();
	}

	public function makeSong(song:String, author:String, data:Blob, ?coverArt:Blob, ?coverBG:Blob):SongObject
	{
		return {
			name: song,
			data: data,
			size: data.size,
			cover_art: coverArt, // Will use the default music png
			cover_background: coverBG, // Will show a background color based off the cover art
			author: author,
			favourite: false // Start as false since the user will decide it
		};
	}
}
