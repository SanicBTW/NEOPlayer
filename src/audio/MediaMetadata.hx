package audio;

enum abstract PlaybackState(String) to String from String
{
	var NONE = "none";
	var PLAYING = "playing";
	var PAUSED = "paused";
}

typedef PositionState =
{
	var duration:Float;
	var playbackRate:Float;
	var position:Float;
}

typedef MediaArtwork =
{
	var src:String;
	var sizes:String;
	var type:String;
}

enum abstract MediaAction(String) to String from String
{
	var PLAY = "play";
	var PAUSE = "pause";
	var SEEK_BACKWARD = "seekbackward";
	var SEEK_FORWARD = "seekforward";
	var PREVIOUS_TRACK = "previoustrack";
	var NEXT_TRACK = "nexttrack";
}

typedef MediaHandler =
{
	var type:MediaAction;
	var func:Void->Void;
}

typedef MediaMetadata =
{
	var title:String;
	var author:String;
	var artwork:Array<MediaArtwork>;
	var handlers:Array<MediaHandler>;
}
