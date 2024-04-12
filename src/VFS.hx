package;

import js.html.Blob;
import js.html.idb.*;

using tink.CoreApi;

enum abstract Tables(String) to String from String
{
	var SONGS = "songs";
	var SCRIPTS = "scripts";
}

typedef BlobObject =
{
	var blob:Blob;
	var mimeType:String;
}

typedef SongObject =
{
	var name:String;
	var data:BlobObject;
	var cover_art:BlobObject;
	var cover_background:BlobObject;
	var author:String;
	var favourite:Bool;
	var created_at:Date;
	var source:String;
}

typedef ScriptObject =
{
	var name:String;
	var data:BlobObject;
	var source:String;
	var created_at:Date;
}

class VFS
{
	public static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB'];
	public static final mbSize:Float = 1024;
	public static final name:String = "S_VirtualFS";

	private var request:OpenDBRequest;
	private var connection:Database;

	private var version:Int;
	private var created:Bool = false;

	// Only set when the Database Update adds or removes fields from the Tables to avoid issues with the new support
	private var updateEntries:Map<Tables, Bool> = new Map();

	public function new(version:Int = 3)
	{
		this.version = version;
	}

	@async public function create():Promise<VFS>
	{
		if (created)
			return Promise.resolve(this);

		return Promise.irreversible((resolve, reject) ->
		{
			request = HTML.window().indexedDB.open(name, version);

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
				var txn:Transaction = ev.target.transaction;
				var oldVersion:Int = ev.oldVersion;
				var newVersion:Int = ev.newVersion;
				Console.debug('Version $oldVersion -> Version $newVersion');

				if (db.objectStoreNames.contains(Tables.SONGS))
				{
					// I don't think people still have the v1 so we aint gonna update entries
					if (oldVersion == 1 && newVersion == 2)
					{
						txn.objectStore(Tables.SONGS).deleteIndex("size");
						Console.success('Updated Song Table to v2');
					}

					if (oldVersion == 2 && newVersion == 3)
					{
						txn.objectStore(Tables.SONGS).createIndex("created_at", "created_at");
						txn.objectStore(Tables.SONGS).createIndex("source", "source"); // scripts already had this lmao
						Console.success('Updated Song Table to v3');
						updateEntries[Tables.SONGS] = true;
					}
				}

				if (db.objectStoreNames.contains(Tables.SCRIPTS))
				{
					if (oldVersion == 2 && newVersion == 3)
					{
						txn.objectStore(Tables.SCRIPTS).createIndex("created_at", "created_at");
						Console.success('Updated Script Table to v3');
						updateEntries[Tables.SCRIPTS] = true;
					}
				}

				if (!db.objectStoreNames.contains(Tables.SONGS))
				{
					var store:ObjectStore = db.createObjectStore(Tables.SONGS);

					store.createIndex('author', 'author'); // String, author or artist
					store.createIndex('favourite', 'favourite'); // Bool, sort favs??
					store.createIndex("created_at", "created_at"); // Date, for sorting
					store.createIndex("source", "source"); // String, origin of the song
				}

				if (!db.objectStoreNames.contains(Tables.SCRIPTS))
				{
					// experimental, uses hscript soon it will use SlangZen
					var store:ObjectStore = db.createObjectStore(Tables.SCRIPTS);

					store.createIndex('source', 'source'); // From where it is
					store.createIndex("created_at", "created_at"); // Date, for sorting
				}
			});

			request.addEventListener('success', () ->
			{
				HTML.localStorage().removeItem("idb-deleted");
				HTML.localStorage().removeItem("idb-del-time");
				connection = request.result;
				created = true;

				if (updateEntries[Tables.SONGS])
					migrateV3(SONGS);

				if (updateEntries[Tables.SCRIPTS])
					migrateV3(SCRIPTS);

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

	@async public function entries(table:Tables):Promise<Map<String, Any>>
	{
		if (!created)
			return Promise.reject(new Error(InternalError, "Database not connected yet"));

		return Promise.irreversible((resolve, reject) ->
		{
			var tempMap:Map<String, Any> = new Map();
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

	private function migrateV3(table:Tables)
	{
		entries(table).handle((out) ->
		{
			var entr:Map<String, Any> = cast out.sure();
			for (name => entry in entr)
			{
				Reflect.setProperty(entry, "created_at", Date.now());
				if (table == SONGS)
					Reflect.setProperty(entry, "source", "Local");

				trace(entry);

				set(table, name, entry).handle((out) ->
				{
					Console.success('Migrated $name from $table (${out.sure()})');
				});
			}
		});
	}

	public static function makeEmptySong():SongObject
	{
		return {
			name: "",
			data: null,
			cover_art: null,
			cover_background: null,
			author: "",
			favourite: false,
			created_at: Date.now(),
			source: ""
		};
	}
}
