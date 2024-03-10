package core;

import core.DebugUI.DebugElement;
import core.DebugUI.IDebugComponent;
import js.html.SpanElement;

enum TickerState
{
	RUNNING;
	STOPPED;
}

@:allow(core.LifeCycle)
class TickerObject implements IDebugComponent
{
	@:noCompletion
	private var d_added:Bool = false;

	@:noCompletion
	private var d_elements:Array<DebugElement> = [];

	@:noCompletion
	private var calls:Int = 0;

	private var func:Int->TickerState;

	// Modify this to stop the ticker outside the function, it will stop on the next tick (obviously)
	public var state:TickerState = RUNNING;

	public function new(func:Int->TickerState)
	{
		this.func = func;
	}

	public function dispose()
	{
		Console.debug('Disposed Ticker [ $calls call(s) ]');
		calls = 0;
		func = null;
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
			name: "Calls",
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

				case "Calls":
					cast(dbgEl.element, SpanElement).textContent = '[ ${dbgEl.name}: $calls ]';
			}
		}
	}
}
