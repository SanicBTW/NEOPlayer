package;

enum abstract Endpoint(String) to String from String
{
	public static var ONLINE(default, null):Bool = true;
	public static var API(default, set):String = "https://ytapi.sancopublic.com";

	@:noCompletion
	private static function set_API(newAPI:String):String
	{
		if (API == newAPI)
			return API;

		API = newAPI;

		// no need to save it if its the same
		if (newAPI == HTML.localStorage().getItem("api-endpoint"))
			return API;

		HTML.localStorage().setItem('api-endpoint', newAPI);
		return API;
	}

	var INFO:String = "/video_info";
	var AUDIO:String = "/get_audio";
	var THUMBNAIL:String = "/get_thumbnail";
	var HEALTH:String = "/health"; // To check if the server is up??

	public static function ping():Void
	{
		final savedAPI:Null<String> = HTML.localStorage().getItem("api-endpoint");
		if (savedAPI != null)
			API = savedAPI;

		Network.loadString('${API}${HEALTH}').handle((out) ->
		{
			switch (out)
			{
				case Success(data):
					Console.debug(haxe.Json.parse(data));
					ONLINE = true;
					Console.success("YTAPI Online");

				case Failure(_):
					ONLINE = false;
					Console.warn("YTAPI Offline");
			}
		});
	}

	public static function makeEndpoint(endpoint:Endpoint, ?query:Map<String, Any>):String
	{
		var querySuf:String = "?";
		if (query != null)
		{
			for (key => value in query)
			{
				querySuf += '$key=$value&';
			}

			if (querySuf.charCodeAt(querySuf.length - 1) == "&".code)
				querySuf = querySuf.substring(0, querySuf.length - 1);
		}

		return API + endpoint + ((query != null) ? querySuf : "");
	}
}
