package core;

import js.html.DivElement;
import js.html.Element;
import js.html.SpanElement;

// use reflection soon

typedef DebugElement =
{
	var name:String;
	var element:Element;
	@:optional var parent:Element;
}

@:allow(core.DebugUI)
interface IDebugComponent
{
	private var d_added:Bool;
	private var d_elements:Array<DebugElement>;
	private function init():Void;
	private function update():Void;
}

@:allow(core.LifeCycle)
class DebugUI
{
	private var comp:Array<IDebugComponent> = [];

	private var view:DivElement = HTML.dom().createDivElement();

	public function new()
	{
		view.classList.add("fixed", "bottom-0", "left-0", "opacity-50", "m-4", "text-left", "pointer-events-none");
		view.style.zIndex = "var(--topmost)";

		HTML.dom().body.append(view);
	}

	public function add(app:IDebugComponent)
	{
		if (app.d_added)
			return;

		comp.push(app);
		app.d_added = true;
		app.init();

		for (obj in app.d_elements)
		{
			if (obj.parent == null)
				view.append(obj.element);
			else
			{
				if (obj.parent == obj.element)
				{
					Console.warn('Tried adding parent to itself on ${obj.name}');
					continue;
				}

				obj.parent.append(obj.element);
			}
		}
	}

	public function remove(app:IDebugComponent)
	{
		if (!app.d_added)
			return;

		comp.remove(app);

		for (obj in app.d_elements)
		{
			if (obj.parent == null)
				view.removeChild(obj.element);
			else
			{
				if (obj.parent == obj.element)
				{
					Console.warn('Tried removing parent from itself on ${obj.name}');
					continue;
				}

				obj.parent.removeChild(obj.element);
			}
		}
	}

	public function update()
	{
		for (plug in comp)
		{
			plug.update();
		}
	}
}
