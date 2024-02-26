package;

import js.html.Element;
import js.html.StyleElement;

class ShadowElement
{
	private var wrapper:Element;

	public function new(name:String)
	{
		this.wrapper = HTML.dom().createDivElement();
		this.wrapper.classList.add('type-$name');
		HTML.dom().body.appendChild(this.wrapper);
	}

	private function loadStyle(path:String)
	{
		Network.loadString(path).handle((out) ->
		{
			switch (out)
			{
				case Success(data):
					var style:StyleElement = HTML.dom().createStyleElement();
					style.textContent = data;
					this.wrapper.appendChild(style);
				case Failure(e):
					Console.error(e);
			}
		});
	}

	private function inheritFromParent(target:Element, copy:Array<String>)
	{
		for (prop in copy)
		{
			var value = Reflect.field(wrapper.style, prop);
			if (value != null)
			{
				Reflect.setField(target.style, prop, value);
			}
		}
	}
}
