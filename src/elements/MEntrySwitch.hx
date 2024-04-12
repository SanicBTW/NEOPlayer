package elements;

// Text - Right: 210px/13.5rem
// Switch - Left: -185px/11.5rem
// TODO: Mobile Support
class MEntrySwitch extends MEntry
{
	private var eSwitch:Switch;

	public function new(header:String, startChecked:Bool = false, onChange:Bool->Void)
	{
		super(header, true, null);

		eSwitch = new Switch(startChecked);

		@:privateAccess
		{
			HTML.dom().body.removeChild(eSwitch.wrapper);
			container.append(eSwitch.wrapper);
			eSwitch.onChange = onChange;

			container.classList.remove("flex-col");
			container.classList.add("flex-row");

			name.style.position = eSwitch.wrapper.style.position = "relative";
			name.style.right = "13.5rem";
			eSwitch.wrapper.style.left = "11.5rem";
		}
	}
}
