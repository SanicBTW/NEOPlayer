package audio;

import discord.presence.PresenceBuilder;

// TODO: Webworkers for updating in the background
class PlayerHandler
{
	public static var skipTime:Int = 10;

	public static function play()
	{
		new PresenceBuilder(LISTENING).addDetails('Playing ${Main.music.getAttribute("musicname")}')
			.addState('by ${Main.music.getAttribute("musicauthor")}')
			.send();
		Main.music.play();
	}

	public static function pause()
	{
		new PresenceBuilder(LISTENING).addDetails('Paused ${Main.music.getAttribute("musicname")}')
			.addState('by ${Main.music.getAttribute("musicauthor")}')
			.send();
		Main.music.pause();
	}

	// have the seek offset in count?
	public static function seekBackward()
	{
		Main.music.currentTime = Math.max(Main.music.currentTime - skipTime, 0);
	}

	public static function seekForward()
	{
		Main.music.currentTime = Math.min(Main.music.currentTime + skipTime, Main.music.duration);
	}
}
