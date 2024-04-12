package elements;

import core.LifeCycle;
import html.VisualViewport;
import js.html.DOMRect;
import js.html.DivElement;
import js.html.Event;
import js.html.Node;

class MList
{
	private var container:DivElement = HTML.dom().createDivElement();
	private var cEntries:DivElement = HTML.dom().createDivElement();
	private var _entries:Array<MEntry> = [];

	public var firstRun:Bool = true;
	public var minWidth:Int = 0;

	public function new(entries:Array<MEntry>)
	{
		// 'items-flex-start' pending to check
		if (HTML.detectDevice() == DESKTOP)
		{
			container.classList.add('w-[${Styling.getComputedRootVar(LIST_WIDTH)}]');
			container.style.margin = "4rem";
		}
		else
		{
			container.classList.add('w-dvw');
			cEntries.style.width = "100%";
		}

		container.classList.add('flex', 'fixed', 'right-0', 'rounded-xl', 'h-dvh',);
		container.style.backgroundColor = "hsl(var(--hue), var(--saturation), 15%)";
		container.style.transition = "var(--main-transition)";
		container.style.marginTop = "12rem";

		cEntries.classList.add('overflow-x-hidden', 'overflow-y-scroll');

		container.append(cEntries);
		refresh(entries);

		HTML.dom().body.append(container);

		VisualViewport.addEventListener(RESIZE, updateSize);

		LifeCycle.timer(5, (?_) ->
		{
			updateSize();
		});
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

		if (HTML.detectDevice() == MOBILE)
			cEntries.style.width = "100%";

		cEntries.style.transition = "var(--main-transition)";

		_entries = entries;
	}

	private function updateSize(?ev:Event)
	{
		var rect:DOMRect = container.getBoundingClientRect();
		widthCheck(rect);
		heightCheck(rect);

		// Kind of bad to iterate through all the entries and resize each one of them EVERYTIME but I'll search for another way
		for (i in 0..._entries.length)
		{
			_entries[i].resize();
		}
	}

	private function widthCheck(rect:DOMRect)
	{
		// Aint no way we recalculating each resize :sob:
		var mRight:Int = Std.int(Styling.parsePX(HTML.window().getComputedStyle(container).marginRight) * 2); // cuz we apply both sides
		minWidth = Math.ceil(rect.width + mRight);

		// prob mobile viewport
		if (HTML.detectDevice() != DESKTOP && firstRun || VisualViewport.width < Main.musicList.minWidth)
		{
			// remove the previous shi
			container.classList.remove('w-[${Styling.getComputedRootVar(LIST_WIDTH)}]');
			container.style.margin = "0";

			container.classList.add('w-dvw');
			cEntries.style.width = "100%";
		}
		else
		{
			// remove the prev shi
			container.classList.remove('w-dvw');
			cEntries.style.width = "inherit";

			container.classList.add('w-[${Styling.getComputedRootVar(LIST_WIDTH)}]');
			container.style.margin = "4rem";
		}

		container.style.marginTop = "12rem";
		firstRun = false;
	}

	private function heightCheck(rect:DOMRect)
	{
		var mB:Int = Std.int(Styling.parsePX(HTML.window().getComputedStyle(container).marginBottom));

		// so the target is 445px
		var wHeight:Int = Std.int(HTML.window().outerHeight); // Window Height
		var diffH:Int = Math.floor(wHeight - rect.height); // Window Diff Height to Rect Height
		var rectDiff:Int = Math.floor(rect.height - diffH); // Rect Height Diff to diffH
		var hmDiff:Int = Math.floor((rect.height - mB) - rectDiff); // 23 - Rect Height - MarginB diff to rectDiff
		var tmDiff:Int = Math.floor(rectDiff - (rect.top - mB)); // 422 - rectDiff diff to Rect Top - MarginB
		var real:Int = Math.floor(tmDiff + hmDiff); // just sum up lmao

		cEntries.style.height = '${real}px';
	}
}
