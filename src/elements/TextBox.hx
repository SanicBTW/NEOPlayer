package elements;

import js.html.DivElement;
import js.html.InputElement;
import js.html.LabelElement;
import js.html.SpanElement;

class TextBox extends ShadowElement
{
	private var container:DivElement = HTML.dom().createDivElement();
	private var label:LabelElement = HTML.dom().createLabelElement();
	private var input:InputElement = HTML.dom().createInputElement();
	private var span:SpanElement = HTML.dom().createSpanElement();

	public var value(get, set):String;

	@:noCompletion
	private function get_value():String
		return this.input.value;

	@:noCompletion
	private function set_value(newValue:String):String
	{
		return this.input.value = newValue;
	}

	public function new(name:String)
	{
		super("text-box");

		loadStyle('./stylesheets/TextBox.css');
		inheritFromParent(container, ["margin"]);

		input.placeholder = " ";
		input.type = wrapper.getAttribute("type") ?? "text";
		if (input.type != "text" || input.type != "password")
			input.type = "text";
		span.textContent = name;

		label.append(input, span);
		container.append(label);

		wrapper.append(container);
	}
}
