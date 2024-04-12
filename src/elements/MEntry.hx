package elements;

import html.VisualViewport;
import js.html.DivElement;
import js.html.ParagraphElement;

// TODO: Add sub header, images support
@:publicFields
class MEntry
{
	var container:DivElement = HTML.dom().createDivElement();
	var name:DivElement = HTML.dom().createDivElement();
	var author:ParagraphElement; // not used yet

	var convertedWidth:Int = 0;

	/* ?artist:String */
	public function new(header:String, isSection:Bool = false, ?onClick:Void->Void)
	{
		// m-8 is 32px aka 2rem, the converted width is multiplied by 2 cuz 32 just substracts the base margin
		var listWidth:Int = Std.int(Styling.parsePX(Styling.getComputedRootVar(LIST_WIDTH)));
		convertedWidth = listWidth - (32 * 2);

		resize();

		container.classList.add('flex', 'flex-row', 'min-h-[90px]', 'rounded-xl', 'hover:cursor-pointer');
		container.style.transition = "var(--main-transition)";
		container.style.backgroundColor = "hsl(var(--hue), var(--saturation), 30%)";
		if (isSection)
		{
			container.classList.remove('hover:cursor-pointer');
			container.classList.add('flex-col', 'items-center', 'justify-center');
		}

		if (!isSection)
		{
			container.addEventListener('mouseenter', () ->
			{
				container.style.backgroundColor = "hsl(var(--hue), var(--saturation), 25%)";
			});
			container.addEventListener('mouseleave', () ->
			{
				container.style.backgroundColor = "hsl(var(--hue), var(--saturation), 30%)";
			});
			container.addEventListener('click', () ->
			{
				if (onClick != null)
					onClick();
			});
		}

		name.classList.add('font-2xl', 'p-8');
		name.innerText = header;

		container.append(name);
	}

	public function resize()
	{
		if (HTML.detectDevice() == DESKTOP || VisualViewport.width > Main.musicList.minWidth)
		{
			container.style.width = "91%";
			container.classList.remove("m-5");

			container.classList.add('w-[${convertedWidth}px]');
			container.classList.add("m-8");
		}
		else
		{
			container.classList.remove('w-[${convertedWidth}px]');
			container.classList.remove("m-8");

			container.style.width = "95%";
			container.classList.add("m-5");
		}
	}
}
