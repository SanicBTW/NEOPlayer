package elements;

import js.html.DivElement;
import js.html.ImageElement;
import js.html.ParagraphElement;
import js.html.URL;

// From the old BasicMusicPlayer v5 (Never released), I have another Notification code but its from my JS Chat Project so uhhh too lazy
// Also this class uses tailwind, very cool
@:publicFields
class Notification
{
	private var timer:Null<Int> = null;

	var container:DivElement = HTML.dom().createDivElement();
	var image:ImageElement = HTML.dom().createImageElement();

	var textContainer:DivElement = HTML.dom().createDivElement();
	var title:DivElement = HTML.dom().createDivElement();
	var info:ParagraphElement = HTML.dom().createParagraphElement();

	public function new(header:String, description:String, ?img:String, duration:Int = 3250)
	{
		container.classList.add('p-1', 'max-w-[480px]', 'w-fit', 'bg-black', "outline", "outline-white", "outline-1", 'flex', 'items-center', 'flex-wrap',
			'absolute', 'right-0', 'top-0', 'm-16', "z-100");
		container.style.transition = "var(--main-transition)";
		container.style.opacity = "0";

		image.classList.add('max-w-[80px]', 'max-h-[80px]', 'relative', 'pointer-events-none');

		var endSrc:String = "./assets/album-placeholder.png";
		@:privateAccess
		if (Network._cache["./assets/album-placeholder.png"] != null)
			endSrc = URL.createObjectURL(Network.bufferToBlob(cast(Network._cache["./assets/album-placeholder.png"], haxe.io.Bytes).b.buffer));
		if (img != null)
			endSrc = img;
		image.src = endSrc;

		textContainer.classList.add('flex', 'flex-wrap', 'flex-col', 'relative', 'mx-6');

		title.classList.add('font-light', 'my-1');
		info.classList.add('font-xl', 'font-semibold', 'my-1');

		title.innerText = header;
		info.innerText = description;

		textContainer.append(title, info);
		container.append(image, textContainer);
		HTML.dom().body.append(container);

		timer = HTML.window().setTimeout(() ->
		{
			container.style.opacity = "1";
			HTML.window().clearTimeout(timer);
			timer = null;
		}, 100);

		container.addEventListener('transitionend', () ->
		{
			timer = HTML.window().setTimeout(() ->
			{
				container.style.opacity = "0";
				HTML.window().clearTimeout(timer);
				timer = HTML.window().setTimeout(() ->
				{
					container.remove();

					if (endSrc.indexOf("blob") > -1)
					{
						URL.revokeObjectURL(endSrc);
						Console.debug('Revoked Image Blob URL ($endSrc)');
					}

					HTML.window().clearTimeout(timer);
				}, 1100);
			}, duration);
		});
	}
}
