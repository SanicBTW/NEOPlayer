package elements;

import js.html.DivElement;
import js.html.InputElement;
import js.html.LabelElement;
import js.html.SpanElement;

class Switch extends ShadowElement
{
	private var container:DivElement = HTML.dom().createDivElement();
	private var label:LabelElement = HTML.dom().createLabelElement();
	private var input:InputElement = HTML.dom().createInputElement();
	private var slider:SpanElement = HTML.dom().createSpanElement();
	private var handle:SpanElement = HTML.dom().createSpanElement();

	public var checked(get, set):Bool;

	@:noCompletion
	private function get_checked():Bool
		return this.input.checked;

	@:noCompletion
	private function set_checked(state:Bool):Bool
		return this.input.checked = state;

	public var onChange:Bool->Void = null;

	public function new(startChecked:Bool = false)
	{
		super("switch");

		loadStyle("./stylesheets/Switch.css");
		inheritFromParent(container, ["margin"]);

		input.type = "checkbox";
		input.defaultChecked = startChecked;

		slider.classList.add("slider");
		handle.classList.add("handle");

		label.append(input, slider, handle);
		container.append(label);

		input.addEventListener('change', () ->
		{
			if (onChange != null)
				onChange(checked);
		});

		wrapper.append(container);
	}
}
