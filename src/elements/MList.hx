package elements;

import js.html.DOMRect;
import js.html.DivElement;
import js.html.Node;

class MList
{
	private var container:DivElement = HTML.dom().createDivElement();
	private var cEntries:DivElement = HTML.dom().createDivElement();

	public function new(entries:Array<MEntry>)
	{
		container.classList.add('overflow-hidden', 'flex', 'w-[${Styling.getComputedRoot().getPropertyValue("--list-width")}]', 'fixed', 'right-0',
			'rounded-xl', 'h-dvh');
		container.style.backgroundColor = "hsl(var(--hue), var(--saturation), 15%)";
		container.style.transition = "var(--main-transition)";
		container.style.margin = "4rem";
		container.style.marginTop = "12rem";

		cEntries.classList.add('overflow-x-hidden', 'overflow-y-scroll');

		container.append(cEntries);
		refresh(entries);

		HTML.dom().body.append(container);

		// TODO: Viewport listener
	}

	public function refresh(entries:Array<MEntry>)
	{
		var copycat:Node = cEntries.cloneNode();
		cEntries.replaceWith(copycat);
		cEntries = cast copycat;

		for (entry in entries)
		{
			cEntries.append(entry.container);
		}

		// bro wtf :sob:
		haxe.Timer.delay(() ->
		{
			var rect:DOMRect = container.getBoundingClientRect();

			var mB:Int = Std.int(Styling.parsePX(HTML.window().getComputedStyle(container).marginBottom));

			// trace(rectDiff - mB); // 490

			// so the target is 445px
			var wHeight:Int = Std.int(HTML.window().outerHeight); // Window Height
			var diffH:Int = Math.floor(wHeight - rect.height); // Window Diff Height to Rect Height
			var rectDiff:Int = Math.floor(rect.height - diffH); // Rect Height Diff to diffH
			var hmDiff:Int = Math.floor((rect.height - mB) - rectDiff); // 23 - Rect Height - MarginB diff to rectDiff
			var tmDiff:Int = Math.floor(rectDiff - (rect.top - mB)); // 422 - rectDiff diff to Rect Top - MarginB
			var real:Int = Math.floor(tmDiff + hmDiff); // just sum up lmao

			cEntries.style.height = '${real}px';
			cEntries.style.transition = "var(--main-transition)";
		}, 15);
	}
}
