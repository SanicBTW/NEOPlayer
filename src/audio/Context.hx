package audio;

import js.html.audio.AudioContext;
import js.html.audio.AudioContextState;
import js.html.audio.MediaElementAudioSourceNode;

// Make it modular or sum shit
@:allow(audio.Sound)
class Context
{
	private static var _ctx:AudioContext;
	private static var _source:MediaElementAudioSourceNode;

	public function new()
	{
		if (HTML.isIOS())
			return;

		_ctx = new AudioContext();
		Console.debug("Opening AudioContext");

		if (_ctx == null)
		{
			Console.error("Failed to create AudioContext");
			return;
		}

		HTML.dom().addEventListener('click', () ->
		{
			if (_ctx.state == AudioContextState.SUSPENDED)
			{
				Console.debug("AudioContext Resumed!");
				_ctx.resume();
			}
		});
	}

	public function close()
	{
		_source.disconnect();

		_ctx.close().then((_) ->
		{
			Console.success("Closed Audio Context");
		});
	}
}
