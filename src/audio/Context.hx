package audio;

import js.html.audio.AudioContext;

@:allow(audio.Sound)
class Context
{
	private static var _ctx:AudioContext;

	public function new()
	{
		_ctx = new AudioContext();
		Console.debug("Opening AudioContext");

		if (_ctx == null)
		{
			Console.error("Failed to create AudioContext");
			return;
		}

		HTML.dom().addEventListener('click', () ->
		{
			if (_ctx.state == SUSPENDED)
			{
				Console.debug("AudioContext Resumed!");
				_ctx.resume();
			}
		});
	}
}
