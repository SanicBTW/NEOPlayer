package elements;

import js.html.DOMRect;
import js.html.DivElement;

// spent a whole ass hour for this, im giving up to input ranges, fuck off
class Slider extends ShadowElement
{
	private var container:DivElement = HTML.dom().createDivElement();
	private var slider:DivElement = HTML.dom().createDivElement();
	private var thumb:DivElement = HTML.dom().createDivElement();

	public function new(size:Int = 100, steps:Int = 100)
	{
		super("slider");

		loadStyle('./stylesheets/Slider.css');

		// wrapper.style.position = "absolute";
		// wrapper.style.left = "50%";
		// wrapper.style.top = "50%";

		container.classList.add('container', 'w-[${size}px]');
		slider.classList.add("slider");
		thumb.classList.add("slider-thumb");

		var canMove:Bool = false;
		wrapper.addEventListener('mousedown', () ->
		{
			canMove = true;
		});

		wrapper.addEventListener('mouseup', () ->
		{
			canMove = false;
		});

		wrapper.addEventListener('mousemove', (ev) ->
		{
			if (!canMove)
				return;

			var mouseX:Int = ev.clientX;
			var rect:DOMRect = slider.getBoundingClientRect();
			var value:Float = mouseX - rect.left;
			var pLeft:Int = Std.int(Styling.parsePX(HTML.window().getComputedStyle(slider).paddingLeft));
			var bLeft:Int = Std.int(Styling.parsePX(HTML.window().getComputedStyle(slider).borderLeftWidth));

			// so first val is the left max, second val is the right max
			value = Math.max(pLeft - bLeft, Math.min(value, rect.left - rect.width));

			thumb.style.left = '${value}px';
		});

		slider.append(thumb);
		container.append(slider);
		wrapper.append(container);

		thumb.style.left = "50%";
	}
}
