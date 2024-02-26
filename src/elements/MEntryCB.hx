package elements;

// Basically MEntry but has a ComboBox inside of it
class MEntryCB extends MEntry
{
	private var comboBox:ComboBox;

	public function new(header:String, entries:Map<String, String>, onCreate:ComboBox->Void, onChange:
		{
			parent:ComboBox,
			name:String,
			value:String,
			index:Int
		}->Void)
	{
		// the reason why i put true is cuz it centers stuff and disables some events
		// maybe it will look weird ig
		super("", true, null);

		container.removeChild(name);

		comboBox = new ComboBox(header, entries);

		@:privateAccess
		{
			HTML.dom().body.removeChild(comboBox.wrapper);
			container.append(comboBox.wrapper);

			// forced to keep consistency in the settings??
			comboBox.wrapper.dataset.permamentHeader = "";
			comboBox.refreshEntries(entries); // refresh to apply the permament header
			comboBox.header.textContent = header;
			onCreate(comboBox); // called so the dev can set something on init?

			comboBox.wrapper.style.width = "95%";
			comboBox.wrapper.addEventListener('change', (ev) ->
			{
				onChange({
					parent: comboBox,
					name: ev.detail.name,
					value: ev.detail.value,
					index: ev.detail.index
				});
			});
		}
	}
}
