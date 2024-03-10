package audio;

import audio.MediaMetadata.MediaHandler;
import discord.presence.PresenceBuilder;

// TODO: Webworkers for updating in the background
class PlayerHandler
{
	public static var skipTime:Int = 10;

	public static function play()
	{
		var name:String = Sound.element.getAttribute("musicname");
		var author:String = Sound.element.getAttribute("musicauthor");

		new PresenceBuilder(LISTENING).addDetails('Playing $name').addState('by $author').send();

		Sound.element.play();
	}

	public static function pause()
	{
		var name:String = Sound.element.getAttribute("musicname");
		var author:String = Sound.element.getAttribute("musicauthor");

		new PresenceBuilder(LISTENING).addDetails('Paused $name').addState('by $author').send();

		Sound.element.pause();
	}

	// have the seek offset in count?
	public static function seekBackward()
	{
		Sound.element.currentTime = Math.max(Sound.element.currentTime - skipTime, 0);
	}

	public static function seekForward()
	{
		Sound.element.currentTime = Math.min(Sound.element.currentTime + skipTime, Sound.element.duration);
	}

	public static function getHandlers():Array<MediaHandler>
	{
		return [
			{
				type: PLAY,
				func: () -> play()
			},
			{
				type: PAUSE,
				func: () -> pause()
			},
			{
				type: SEEK_BACKWARD,
				func: () -> seekBackward()
			},
			{
				type: SEEK_FORWARD,
				func: () -> seekForward()
			}
		];
	}
}
