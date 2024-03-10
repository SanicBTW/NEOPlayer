package elements;

import core.LifeCycle;
import core.TimerObject;
import js.html.DivElement;
import js.html.ImageElement;
import js.html.ParagraphElement;
import js.html.URL;

// From the old BasicMusicPlayer v5 (Never released), I have another Notification code but its from my JS Chat Project so uhhh too lazy
// Also this class uses tailwind, very cool
// Had to base timer code on the old one for notification overriding wtf??? https://github.com/SanicBTW-Archive/Custom-Notifications-HTML5/blob/master/OldNotifications.js
@:publicFields
class Notification
{
	private static final SCROLL_MIN_LENGTH:Int = 40; // the minimun length the header needs to meet in order to apply the scrolling effect

	private static var instance:Notification = null; // Only one allowed
	private static var queue:Array<Void->Void> = [];
	private static var playing:Bool = false;

	private static var showTimer:TimerObject = null;
	private static var collectTimer:TimerObject = null;

	var container:DivElement = HTML.dom().createDivElement();
	var image:ImageElement = HTML.dom().createImageElement();

	var textContainer:DivElement = HTML.dom().createDivElement();
	var title:DivElement = HTML.dom().createDivElement();
	var info:ParagraphElement = HTML.dom().createParagraphElement();

	// i hate this so much
	public function new()
	{
		if (instance != null)
			return;

		container.classList.add('p-1', 'w-fit', "outline-1", 'flex', 'items-center', 'flex-nowrap', 'absolute', 'right-0', 'top-0', 'max-h-[88px]',
			'overflow-hidden', 'pointer-events-none');
		container.style.transition = "var(--main-transition)";
		container.style.opacity = "0";
		container.style.zIndex = "var(--topmost)";
		container.style.backgroundColor = "var(--accent)";
		container.style.outlineStyle = 'solid';
		container.style.outlineColor = "var(--foreground-color)";

		// better responisevennes (i should use vw instead of px lmao)
		if (HTML.detectDevice() == DESKTOP)
		{
			container.classList.add('m-16', 'max-w-[350px]');
		}
		else
		{
			container.classList.add("m-8", 'max-w-[315px]');
		}

		image.classList.add('max-w-[80px]', 'max-h-[80px]', 'relative', 'pointer-events-none', 'z-4');
		textContainer.classList.add('flex', 'flex-nowrap', 'flex-col', 'relative', 'mx-6', 'min-w-[148px]');

		title.classList.add('font-light', 'my-1', 'w-fit', 'relative');
		info.classList.add('font-xl', 'font-semibold', 'my-1', 'relative');

		textContainer.append(title, info);
		container.append(image, textContainer);
		HTML.dom().body.insertBefore(container, HTML.dom().body.children[0]);

		instance = this;
	}

	public static function show(header:String, description:String, ?imgSrc:String, shouldOverride:Bool = false, duration:Int = 195)
	{
		if (playing)
		{
			// force shouldOverride to false for good measure
			if (queue.length < 3) // 3 max to avoid having extra late notifs
				queue.push(() -> show(header, description, imgSrc, false, duration));

			if (shouldOverride)
				finish(true);

			return;
		}

		playing = true;
		instance.title.innerText = header;
		instance.info.innerText = description;

		var endSrc:String = "./assets/album-placeholder.png";
		@:privateAccess
		if (Network._cache["./assets/album-placeholder.png"] != null)
			endSrc = URL.createObjectURL(Network.bufferToBlob(cast(Network._cache["./assets/album-placeholder.png"], haxe.io.Bytes).b.buffer));
		if (imgSrc != null)
			endSrc = imgSrc;
		instance.image.src = endSrc;
		instance.container.style.opacity = "1";

		// TODO: Better scrolling (Clipping the text to a region, disable margins on scroll, proper x translating to fit the necessary width in screen)
		if (header.length > SCROLL_MIN_LENGTH && !instance.title.classList.contains("scroll"))
		{
			Styling.setRootVar(SCROLL_LENGTH, '${instance.title.offsetWidth * -1}px');
			instance.title.classList.add("scroll");
		}

		if (header.length > SCROLL_MIN_LENGTH)
		{
			instance.container.onanimationend = function()
			{
				finish();
			}
			return;
		}

		showTimer = LifeCycle.timer(duration, (?_) ->
		{
			finish();
		});
	}

	private static function finish(overriden:Bool = false)
	{
		playing = false;
		instance.container.style.opacity = "0";

		if (overriden)
		{
			instance.container.onanimationend = null;
			if (instance.title.classList.contains("scroll"))
			{
				instance.title.classList.remove("scroll");
				instance.title.style.transform = "translateX(0)";
			}
			Styling.setRootVar(SCROLL_LENGTH, '-100%');

			instance.container.classList.add("notransition");
			instance.container.offsetLeft;
			instance.container.classList.remove("notransition");

			if (showTimer != null)
			{
				showTimer.cancel();
				showTimer = null;
			}

			if (collectTimer != null)
			{
				collectTimer.cancel();
				collectTimer = null;
			}

			LifeCycle.timer(20, (?_) ->
			{
				if (queue[0] != null)
				{
					queue.shift()();
					return;
				}
			});
		}
		else
		{
			collectTimer = LifeCycle.timer(30, (?_) ->
			{
				instance.container.onanimationend = null;
				if (instance.title.classList.contains("scroll"))
				{
					instance.title.classList.remove("scroll");
					instance.title.style.transform = "translateX(0)";
				}
				Styling.setRootVar(SCROLL_LENGTH, '-100%');

				if (instance.image.src.indexOf("blob") > -1)
				{
					URL.revokeObjectURL(instance.image.src);
					Console.debug('Revoked Image Blob URL (${instance.image.src})');
				}

				instance.title.innerText = "";
				instance.info.innerText = "";
				instance.image.src = "";
			});

			collectTimer.onFinish = function(_)
			{
				if (queue[0] != null)
				{
					queue.shift()();
					return;
				}
			}
		}
	}
}
