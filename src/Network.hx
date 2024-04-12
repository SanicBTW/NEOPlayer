package;

// TODO: Cleaner code and avoid copy pasting
import haxe.Http;
import haxe.io.Bytes;
import js.html.Blob;
import js.lib.ArrayBuffer;

using tink.CoreApi;

typedef QueueObject =
{
	var queue:Array<Dynamic->Void>;
	var inProgress:Bool;
}

// TODO - When finishing a request, return a struct with the Http var and the data

@:allow(YoutubeAPI)
@:allow(Endpoint)
class Network
{
	private static var _cache:Map<String, Dynamic> = new Map<String, Dynamic>();
	private static var _queue:Map<String, QueueObject> = new Map<String, QueueObject>();
	private static var _sessionID:Int = -1;

	public static function prepareSessionID()
	{
		if (_sessionID != -1)
		{
			Console.error('You may not generate a new Session ID in the current session!');
			return;
		}

		_sessionID = Math.floor(Math.random() * 9999);
		Console.debug('Your session ID $_sessionID');
	}

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

	@async public static function loadString(file:String):Promise<String>
	{
		var queueEntry:QueueObject = checkQueue(file);

		if (_cache.exists(file))
			return Promise.resolve(cast _cache[file]);

		if (queueEntry.inProgress)
		{
			return Promise.irreversible((res, _) ->
			{
				queueEntry.queue.push(res);
			});
		}

		queueEntry.inProgress = true;

		return Promise.irreversible((resolve, reject) ->
		{
			var req:Http = new Http(file);
			req.async = true;

			req.onData = function(c)
			{
				_cache[file] = c;
				resolve(c);
				cleanQueue(c, file, queueEntry);
			}

			req.onError = function(err)
			{
				reject(new Error(InternalError, err));
			}

			req.request();
		});
	}

	@async public static function loadBytes(file:String):Promise<Bytes>
	{
		var queueEntry:QueueObject = checkQueue(file);

		if (_cache.exists(file))
			return Promise.resolve(cast _cache[file]);

		if (queueEntry.inProgress)
		{
			return Promise.irreversible((res, _) ->
			{
				queueEntry.queue.push(res);
			});
		}

		queueEntry.inProgress = true;

		return Promise.irreversible((resolve, reject) ->
		{
			var req:Http = new Http(file);
			req.async = true;
			req.onBytes = function(c)
			{
				_cache[file] = c;
				resolve(c);
				cleanQueue(c, file, queueEntry);
			}

			req.onError = function(err)
			{
				reject(new Error(InternalError, err));
			}

			req.request();
		});
	}

	public static function bufferToBlob(input:ArrayBuffer):Blob
	{
		return new Blob([input]);
	}
}
