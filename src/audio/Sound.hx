package audio;

import VFS.SongObject;
import js.Syntax;
import js.html.AudioElement;
import js.html.Blob;
import js.html.SourceElement;
import js.html.URL;
import js.html.audio.AudioBuffer;
import js.html.audio.AudioContext;
import js.html.audio.AudioNode;
import js.html.audio.GainNode;
import js.html.audio.MediaElementAudioSourceNode;
import js.lib.ArrayBuffer;
import js.lib.Float32Array;

// Make it somewhat modular
@:allow(audio.Context)
@:allow(audio.PlayerHandler)
class Sound
{
	private static var element:AudioElement; // Handles sound playback
	private static var src:SourceElement; // Used to properly play songs in Safari

	private var buffer(default, null):AudioBuffer;

	private var context(get, null):AudioContext; // AudioContext

	@:noCompletion
	private function get_context():AudioContext
		return Context._ctx;

	private var track(get, null):MediaElementAudioSourceNode; // Media Element aka AudioElement

	@:noCompletion
	private function get_track():MediaElementAudioSourceNode
		return Context._source;

	public var volume:GainNode;

	public function new()
	{
		element = HTML.dom().createAudioElement();

		element.controls = false;
		element.loop = true;
		HTML.addMusicListeners(element);
		HTML.dom().body.append(element);

		if (HTML.isIOS())
			return;

		Context._source = context.createMediaElementSource(Sound.element);
		plug(volume = context.createGain());
	}

	// Used to quickly connect AudioNodes to the track and to the destination
	public function plug(node:AudioNode)
	{
		track.connect(node).connect(context.destination);
	}

	// Make it modular, array of functions queued to be executed once the buffer is ready, when calling the queued functions pass the buffer for manipulation and more
	public function bufferAvailable()
	{
		if (HTML.isIOS())
			return;

		normalizeVolume();
	}

	public function loadFromData(aBuffer:ArrayBuffer)
	{
		context.decodeAudioData(aBuffer, decoded ->
		{
			buffer = decoded;
			bufferAvailable();
		}, exception ->
		{
			Console.error(exception);
		});
	}

	public function loadFromBlob(blob:Blob)
	{
		var onDone = function(aBuf:ArrayBuffer)
		{
			Console.debug("Finished loading Sound from Blob (Blob -> Array Buffer)");
			loadFromData(aBuf);
		}

		Syntax.code("{0}.arrayBuffer().then((aBuf) => { {1}(aBuf); })", blob, onDone);
	}

	public function play(song:SongObject)
	{
		var srcEl:SourceElement = HTML.dom().createSourceElement();

		if (src != null)
		{
			var objURL:String = src.src;

			element.pause();
			URL.revokeObjectURL(objURL);
			Console.debug('Revoked Audio Blob URL ($objURL)');

			var copycat = element.cloneNode();
			element.replaceWith(copycat);
			element = cast copycat;
			HTML.addMusicListeners(element);

			src = null;
		}

		var blob:Blob = song.data.blob;
		if (!HTML.isIOS())
			loadFromBlob(blob); // Only used to get the buffer
		srcEl.src = URL.createObjectURL(blob);
		srcEl.type = song.data.mimeType;

		element.setAttribute("musicname", song.name);
		element.setAttribute("musicauthor", song.author);
		element.append(srcEl);
		src = srcEl;

		PlayerHandler.play();

		elements.Notification.show('Playing ${song.name}', 'by ${song.author}', (song.cover_art != null) ? URL.createObjectURL(song.cover_art.blob) : null,
			true);
	}

	// helpers
	private function normalizeVolume()
	{
		var max:Float = 0;
		for (channel in 0...buffer.numberOfChannels)
		{
			var data:Float32Array = buffer.getChannelData(channel);
			for (i in 0...data.length)
			{
				var abs:Float = Math.abs(data[i]);
				if (abs > max)
					max = abs;
			}
		}

		volume.gain.value = 1 / max;

		Console.debug('New normalized volume ${1 / max}');
	}
}
