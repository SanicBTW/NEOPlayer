package audio;

import js.html.AudioElement;
import js.html.audio.AudioContext;
import js.html.audio.MediaElementAudioSourceNode;
import js.html.audio.MediaStreamAudioDestinationNode;

@:allow(audio.Sound)
class Context
{
	private static var _ctx:AudioContext;

	private var _srcNode:MediaElementAudioSourceNode;
	private var _dstNode:MediaStreamAudioDestinationNode;

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

	public function bindTo(element:AudioElement)
	{
		_srcNode = _ctx.createMediaElementSource(element);
		_dstNode = _ctx.createMediaStreamDestination();

		_srcNode.connect(_dstNode);
		element.srcObject = _dstNode.stream;
	}
}
