package elements;

import js.html.DivElement;
import js.html.ParagraphElement;

// TODO: Add sub header, images support
@:publicFields
class MEntry
{
	var container:DivElement = HTML.dom().createDivElement();
	var name:DivElement = HTML.dom().createDivElement();
	var author:ParagraphElement; // not used yet

	/* ?artist:String */
	public function new(header:String, isSection:Bool = false, ?onClick:Void->Void)
	{
		// m-8 is 32px aka 2rem, the converted width is multiplied by 2 cuz 32 just substracts the base margin
		if (HTML.detectDevice() == DESKTOP)
		{
			var listWidth:Int = Std.int(Styling.parsePX(Styling.getComputedRoot().getPropertyValue("--list-width")));
			var convertedWidth:Int = listWidth - (32 * 2);
			container.classList.add('w-[${convertedWidth}px]');
		}
		else
		{
			container.style.width = "90%";
		}

		container.classList.add('flex', 'flex-row', 'h-[90px]', 'min-h-[90px]', 'rounded-xl', 'm-8', 'hover:cursor-pointer');
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
		name.textContent = header;

		container.append(name);
	}
}
