package elements;

// Basically MEntry but has a TextBox inside of it
class MEntryTB extends MEntry
{
	private var textBox:TextBox;

	public function new(header:String, onChange:String->Void, ?onCreate:TextBox->Void)
	{
		// the reason why i put true is cuz it centers stuff and disables some events
		// maybe it will look weird ig
		super("", true, null);

		container.removeChild(name);

		textBox = new TextBox(header);

		@:privateAccess
		{
			HTML.dom().body.removeChild(textBox.wrapper);
			container.append(textBox.wrapper);
			if (onCreate != null)
				onCreate(textBox);

			textBox.wrapper.style.width = "95%";
			container.classList.remove('min-h-[90px]');
			container.classList.add('min-h-[118px]');
			textBox.input.addEventListener('change', () ->
			{
				onChange(textBox.value);
			});
		}
	}
}
