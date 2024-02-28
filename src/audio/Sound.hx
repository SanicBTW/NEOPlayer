package audio;

// TODO: Better Queue System - do i need it tho
import js.Syntax;
import js.html.Blob;
import js.html.audio.AudioBuffer;
import js.html.audio.AudioBufferSourceNode;
import js.lib.ArrayBuffer;

typedef QueueEntry =
{
	func:Array<Dynamic>->Void,
	args:Array<Dynamic>
}

class Sound
{
	private var _buffer:AudioBuffer = null;
	private var _source:AudioBufferSourceNode = null;
	private var _queue:Array<QueueEntry> = [];

	public var playing(default, null):Bool = false;

	public function new() {}

	private function cleanQueue()
	{
		for (entry in _queue)
		{
			entry.func(entry.args);
			_queue.remove(entry);
		}
	}

	public function loadFromData(buffer:ArrayBuffer)
	{
		Context._ctx.decodeAudioData(buffer, decoded ->
		{
			_buffer = decoded;
			cleanQueue();
		}, exception ->
		{
			Console.error(exception);
		});
	}

	public function loadFromBlob(blob:Blob)
	{
		// dumb shit lmao
		function onDone(buf:ArrayBuffer)
		{
			Console.debug("Finished loading from Blob (Blob -> Array Buffer)");
			loadFromData(buf);
		}

		// i love this (not really)
		Syntax.code("{0}.arrayBuffer().then((buf) => { {1}(buf) })", blob, onDone);
	}

	private function clean()
	{
		_buffer = null;

		_source.stop();
		_source = null;
	}

	public function play(startFrom:Float = 0, loop:Bool = false)
	{
		// Dumbass :sob:
		if (_buffer == null)
		{
			var playF:QueueEntry = {
				func: (args) ->
				{
					play(args[0], args[1]);
				},
				args: [startFrom, loop],
			};

			if (!_queue.contains(playF))
				_queue.push(playF);

			playF = null;

			return;
		}

		_source = Context._ctx.createBufferSource();
		_source.buffer = _buffer;
		// @:privateAccess
		// if (Main.context._dstNode != null)
		//	_source.connect(Main.context._dstNode);
		// else
		_source.connect(Context._ctx.destination);

		_source.loop = loop;
		_source.start(startFrom);
		playing = true;
	}

	public function stop()
	{
		clean();
		playing = false;
	}
}
