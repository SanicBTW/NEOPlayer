package;

// TODO: Cleaner code and avoid copy pasting
import haxe.Http;
import haxe.ds.DynamicMap;
import js.html.Blob;
import js.lib.ArrayBuffer;

using tink.CoreApi;

typedef QueueObject =
{
	var queue:Array<Dynamic->Void>;
	var inProgress:Bool;
}

class Network
{
	private static var _cache:DynamicMap<String, Dynamic> = new DynamicMap<String, Dynamic>();
	private static var _queue:DynamicMap<String, QueueObject> = new DynamicMap<String, QueueObject>();

	private static function checkQueue(file:String):QueueObject
	{
		var queueEntry:QueueObject = _queue[file];

		if (queueEntry == null)
		{
			queueEntry = {
				queue: [],
				inProgress: false
			};
			_queue[file] = queueEntry;
		}

		return queueEntry;
	}

	private static function cleanQueue<T>(c:T, file:String, obj:QueueObject)
	{
		for (resolve in obj.queue)
		{
			resolve(c);
		}

		obj.queue = null;
		obj.inProgress = false;
		_queue.remove(file);
	}

	@async public static function loadString<T>(file:String):Promise<T>
	{
		var queueEntry:QueueObject = checkQueue(file);

		if (_cache.exists(file))
			return Promise.resolve(cast _cache[file]);

		if (queueEntry.inProgress)
		{
			return new Promise((res, _) ->
			{
				queueEntry.queue.push(res);
				return null;
			});
		}

		queueEntry.inProgress = true;

		return new Promise<T>((res, rej) ->
		{
			var req:Http = new Http(file);
			req.async = true;

			req.onData = function(c)
			{
				_cache[file] = c;
				res(cast c);
				cleanQueue(c, file, queueEntry);
			}

			req.onError = function(err)
			{
				trace(err);
				rej(new Error(I_am_a_Teapot, err));
			}

			req.request();

			return null;
		});
	}

	@async public static function loadBytes<T>(file:String):Promise<T>
	{
		var queueEntry:QueueObject = checkQueue(file);

		if (_cache.exists(file))
			return Promise.resolve(cast _cache[file]);

		if (queueEntry.inProgress)
		{
			return new Promise((res, _) ->
			{
				queueEntry.queue.push(res);
				return null;
			});
		}

		queueEntry.inProgress = true;

		return new Promise<T>((res, rej) ->
		{
			var req:Http = new Http(file);
			req.async = true;
			req.onBytes = function(c)
			{
				_cache[file] = c;
				res(cast c);
				cleanQueue(c, file, queueEntry);
			}

			req.onError = function(err)
			{
				trace(err);
				rej(new Error(I_am_a_Teapot, err));
			}

			req.request();

			return null;
		});
	}

	public static function bufferToBlob(input:ArrayBuffer):Blob
	{
		return new Blob([input]);
	}
}
