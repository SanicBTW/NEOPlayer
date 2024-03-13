package core;

import core.DebugUI.DebugElement;
import core.DebugUI.IDebugComponent;
import js.Syntax;
import js.html.SpanElement;

// Memory Debug Component
class MemoryDebug implements IDebugComponent
{
	@:noCompletion
	private var d_added:Bool = false;

	@:noCompletion
	private var d_elements:Array<DebugElement> = [];

	public function new() {}

	private inline function getMemory():Dynamic
		return Syntax.code("window.performance.memory.usedJSHeapSize");

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
			name: "Memory",
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

				case "Memory":
					var mem = Utils.parseSize(Utils.roundDecimal(getMemory(), 2));
					cast(dbgEl.element, SpanElement).textContent = '[ ${dbgEl.name}: ${mem.size} ${mem.unit} ]';
					mem = null;
			}
		}
	}
}
