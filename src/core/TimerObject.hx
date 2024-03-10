package core;

import core.DebugUI.DebugElement;
import core.DebugUI.IDebugComponent;
import js.html.SpanElement;

@:allow(core.LifeCycle)
class TimerObject implements IDebugComponent
{
	@:noCompletion
	private var d_added:Bool = false;

	@:noCompletion
	private var d_elements:Array<DebugElement> = [];

	@:noCompletion
	private var ticks:Int = 0;

	@:noCompletion
	private var runs:Int = 0;

	@:noCompletion
	private var canceled:Bool = false;

	private var time:Int;
	private var func:?Any->Void;
	private var arg:Any;
	private var loops:Int;

	public var onFinish:Int->Void = null;
	public var onLoop:Int->Void = null;

	public var finished:Bool = false;

	public function new(time:Int, func:?Any->Void, loops:Int = 1, arg:Any = null)
	{
		this.time = time;
		this.func = func;
		this.arg = arg;
		this.loops = loops;
	}

	// only sets the flag lmao
	public function cancel()
	{
		canceled = true;
		dispose();
	}

	public function dispose()
	{
		Console.debug('Disposed Timer [ $time tick(s) | $loops loop(s) ]');
		finished = true;
		time = 0;
		func = null;
		arg = null;
		loops = 0;
		onFinish = null;
		onLoop = null;
	}

	private function init():Void
	{
		d_elements.push({
			name: "Unifier",
			element: HTML.dom().createParagraphElement()
		});
		d_elements.push({
			name: "Identifier",
			element: HTML.dom().createSpanElement(),
			parent: d_elements[0].element
		});
		d_elements.push({
			name: "Ticks",
			element: HTML.dom().createSpanElement(),
			parent: d_elements[0].element
		});
		d_elements.push({
			name: "Target Time",
			element: HTML.dom().createSpanElement(),
			parent: d_elements[0].element
		});
	}

	private function update():Void
	{
		for (dbgEl in d_elements)
		{
			switch (dbgEl.name)
			{
				case "Identifier":
					cast(dbgEl.element, SpanElement).textContent = '${Type.getClassName(Type.getClass(this))} · ';

				case "Ticks":
					cast(dbgEl.element, SpanElement).textContent = '[ ${dbgEl.name}: $ticks |';

				case "Target Time":
					cast(dbgEl.element, SpanElement).textContent = ' ${dbgEl.name}: $time ]';
			}
		}
	}
}
