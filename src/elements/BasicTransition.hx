package elements;

import core.LifeCycle;
import core.TimerObject;
import js.html.DivElement;

class CallbackStack
{
	private var listeners:Array<?Any->Void> = [];

	public function new() {}

	public function add(callback:?Any->Void):Int
	{
		return listeners.push(callback);
	}

	public function dispatch(?arg:Any):Void
	{
		for (listener in listeners)
		{
			listener(arg);
			listeners.remove(listener);
		}
	}

	public function remove(id:Int):Void
	{
		listeners.splice(id, 1);
	}

	public function has(func:?Any->Void):Bool
	{
		return listeners.contains(func);
	}
}

// Testing is required, moved to the new TimerObject system and i don't know if its working as intended
class BasicTransition extends ShadowElement
{
	public static var isTransitioning:Bool = false;
	public static var time:Int = 75;
	private static var timer:TimerObject = null;
	private static var cbStack:CallbackStack = new CallbackStack();
	private static var instance:BasicTransition = null;

	private var container:DivElement = HTML.dom().createDivElement();

	public function new()
	{
		if (BasicTransition.instance != null)
			return;

		super("basic-transition");
		HTML.dom().body.removeChild(wrapper);
		HTML.dom().body.insertBefore(wrapper, HTML.dom().body.childNodes[0]);

		loadStyle('./stylesheets/BasicTransition.css');
		container.classList.add('basicTransition');
		wrapper.append(container);

		BasicTransition.instance = this;
	}

	public static function play(after:?Any->Void, autoOverflow:Bool = false)
	{
		// dirty work ig??
		var tInst:BasicTransition = BasicTransition.instance;
		if (tInst == null)
			tInst = new BasicTransition();

		tInst.container.style.top = "0px";

		if (autoOverflow)
			HTML.dom().body.style.overflow = "hidden";

		if (!cbStack.has(after))
			cbStack.add(after);

		if (isTransitioning)
		{
			reset(after);
			return;
		}

		isTransitioning = true;

		timer = LifeCycle.timer(time, (?_) ->
		{
			tInst.container.style.top = "-100dvh";
			cbStack.dispatch();

			isTransitioning = false;
			if (autoOverflow)
				HTML.dom().body.style.overflow = "initial";
		});
	}

	private static function reset(after:?Any->Void)
	{
		if (timer != null)
			timer.cancel();
		isTransitioning = false;
		play(after);
	}
}
