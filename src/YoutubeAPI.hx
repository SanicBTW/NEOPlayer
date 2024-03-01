package;

import Network;
import haxe.Http;
import haxe.Json;
import haxe.io.Bytes;

using tink.CoreApi;

typedef ThumbnailObject =
{
	var url:String;
	var width:Float;
	var height:Float;
}

typedef InfoResponse =
{
	var videoId:String;
	var title:String;
	var lengthInSeconds:Float;
	var author:String;
	var thumbnails:Array<ThumbnailObject>;
}

typedef BlobResponse =
{
	var mimeType:String;
	var data:Bytes;
}

// just the same as Network but for the youtube api troll

@:allow(Entries)
class YoutubeAPI
{
	private static var _curID:Null<String> = null;

	private static final apiURL:String = #if debug "http://127.0.0.1:7654" #else "https://ytapi.sancopublic.com/" #end;

	// make enum you dumb fuck
	private static final infoEndpoint:String = "/video_info";
	private static final audioEndpoint:String = "/get_audio";
	private static final thumbEndpoint:String = "/get_thumbnail";

	@async public static function getDetails(id:String):Promise<InfoResponse>
	{
		var queueEntry:QueueObject = Network.checkQueue(id);

		if (Network._cache.exists(id))
			return Promise.resolve(cast Network._cache[id]);

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
			var req:Http = new Http('${apiURL}${infoEndpoint}?sessionID=${Network._sessionID}&id=${id}');
			req.async = true;

			req.onData = function(c)
			{
				var obj:InfoResponse = Json.parse(c);
				Network._cache[id] = obj;
				resolve(obj);
				Network.cleanQueue(obj, id, queueEntry);
			}

			req.onError = function(err)
			{
				reject(new Error(InternalError, err));
			}

			req.request();
		});
	}

	@async public static function getAudio(name:String):Promise<BlobResponse>
	{
		var queueEntry:QueueObject = Network.checkQueue(name);

		if (Network._cache.exists(name))
			return Promise.resolve(cast Network._cache[name]);

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
			var req:Http = new Http('${apiURL}${audioEndpoint}?sessionID=${Network._sessionID}');
			req.async = true;

			req.onBytes = function(c)
			{
				var ret:BlobResponse = {
					mimeType: req.responseHeaders.get("content-type"),
					data: c
				};
				Network._cache[name] = ret;
				resolve(ret);
				Network.cleanQueue(ret, name, queueEntry);
			}

			req.onError = function(err)
			{
				reject(new Error(InternalError, err));
			}

			req.request();
		});
	}

	@async public static function getThumbnail(url:String):Promise<BlobResponse>
	{
		var queueEntry:QueueObject = Network.checkQueue(url);

		if (Network._cache.exists(url))
			return Promise.resolve(cast Network._cache[url]);

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
			var req:Http = new Http('${apiURL}${thumbEndpoint}');
			req.async = true;

			req.onBytes = function(c)
			{
				var ret:BlobResponse = {
					mimeType: req.responseHeaders.get("content-type"),
					data: c
				};
				Network._cache[url] = ret;
				resolve(ret);
				Network.cleanQueue(ret, url, queueEntry);
			}

			req.onError = function(err)
			{
				reject(new Error(InternalError, err));
			}

			req.setHeader("thumbnail_url", Json.stringify({thumb: url}));
			req.request();
		});
	}
}
