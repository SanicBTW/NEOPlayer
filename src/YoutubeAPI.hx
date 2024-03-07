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

@:allow(Entries)
class YoutubeAPI
{
	private static var _curID:Null<String> = null;

	private static final apiURL:String = "https://ytapi.sancopublic.com";

	@async public static function getDetails(id:String):Promise<InfoResponse>
	{
		return Promise.irreversible((resolve, reject) ->
		{
			var query:Map<String, Any> = ["sessionID" => Network._sessionID, "id" => id];
			var endpoint:String = Endpoint.makeEndpoint(INFO, query);
			Network.loadString(endpoint).handle((out) ->
			{
				switch (out)
				{
					case Success(data):
						resolve(Json.parse(data));
					case Failure(failure):
						trace(failure);
						reject(failure);
				}
			});
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
			var query:Map<String, Any> = ["sessionID" => Network._sessionID];
			var endpoint:String = Endpoint.makeEndpoint(AUDIO, query);
			var req:Http = new Http(endpoint);
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
			var endpoint:String = Endpoint.makeEndpoint(THUMBNAIL);
			var req:Http = new Http(endpoint);
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
