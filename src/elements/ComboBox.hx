package elements;

import js.html.CustomEvent;
import js.html.DivElement;
import js.html.Element;
import js.html.Node;
import js.html.NodeList;

class ComboBox extends ShadowElement
{
	private var container:DivElement = HTML.dom().createDivElement();
	private var header:DivElement = HTML.dom().createDivElement();
	private var list:DivElement = HTML.dom().createDivElement();
	private var items:DivElement = HTML.dom().createDivElement();
	private var indicator:DivElement = HTML.dom().createDivElement();

	public var value(get, null):String;

	@:noCompletion
	private function get_value():String
		return items.children.item(Std.parseInt(wrapper.dataset.curSelected)).dataset.value;

	public var visible(get, set):Bool;

	@:noCompletion
	private function get_visible()
	{
		return (wrapper.dataset.visible != null && wrapper.dataset.visible == "true");
	}

	@:noCompletion
	private function set_visible(state:Bool)
	{
		wrapper.dataset.visible = Std.string(state);

		if (state)
		{
			header.style.borderRadius = "2rem 2rem 0 0";
			list.style.borderRadius = "0 0 2rem 2rem";
			list.style.top = "100%";
			list.style.pointerEvents = "all";
			list.style.zIndex = "var(--combobox-topZ)";
			indicator.style.transform = "rotate(180deg)";
			items.style.display = "block";
			wrapper.dataset.transitioning = "true";
		}
		else
		{
			header.style.borderRadius = list.style.borderRadius = "2rem";
			list.style.top = "0%";
			list.style.pointerEvents = "none";
			list.style.zIndex = "0";
			indicator.style.transform = "rotate(0deg)";
			items.style.display = "none";
		}

		return state;
	}

	public function new(name:String, entries:Map<String, String>)
	{
		super("combo-box");

		loadStyle('./stylesheets/ComboBox.css');
		inheritFromParent(container, ["margin"]);

		list.style.visibility = "hidden";

		container.classList.add('container');
		header.classList.add('copycat1', "header");
		list.classList.add('copycat1', 'list');
		indicator.classList.add('indicator');

		setListener();

		header.textContent = name;

		list.append(items);
		indicator.insertAdjacentHTML('beforeend', Styling.arrowSVG("20px", "20px"));
		container.append(header, list, indicator);

		var oldAttribute = Reflect.field(wrapper, "setAttribute");
		Reflect.setField(wrapper, "setAttribute", (name:String, value:String) ->
		{
			switch (name)
			{
				case "entries":
					var parsedMap:Map<String, String> = new Map();
					for (entry in value.split(","))
					{
						var tEntry:String = StringTools.trim(entry);
						if (tEntry.charCodeAt(0) == "[".code)
							tEntry = tEntry.substring(1);

						if (tEntry.charCodeAt(tEntry.length - 1) == "]".code)
							tEntry = tEntry.substring(0, tEntry.length - 1);

						var rawA:Array<String> = tEntry.split("=>");
						parsedMap.set(StringTools.trim(rawA[0]), StringTools.trim(rawA[1]));
					}
					refreshEntries(parsedMap);

				case "initialindex" | "selectedindex":
					if (wrapper.dataset.initialindex != null && wrapper.dataset.initialindex == value)
						return;

					wrapper.dataset.curSelected = value;
					items.children.item(Std.parseInt(wrapper.dataset.curSelected)).click();
					header.click();

				case "visible":
					visible = (value == "true");

				default:
			}
			js.Syntax.code('{0}.call({1}, {2}, {3})', oldAttribute, wrapper, name, value);
		});

		wrapper.append(container);

		wrapper.setAttribute("entries", entries.toString());
		wrapper.setAttribute("initialindex", "0");
	}

	private function setListener()
	{
		header.addEventListener('click', () ->
		{
			this.visible = !this.visible;
		});

		container.addEventListener('transitionstart', (ev) ->
		{
			if ((ev.propertyName == "border-bottom-left-radius" || ev.propertyName == "border-bottom-right-radius")
				&& this.list.style.visibility == "hidden")
			{
				this.list.style.visibility = "visible";
			}
		});

		container.addEventListener('transitionrun', (ev) ->
		{
			if ((ev.propertyName == "border-bottom-left-radius" || ev.propertyName == "border-bottom-right-radius")
				&& this.list.style.visibility == "visible")
			{
				this.list.style.opacity = "1";
				wrapper.dataset.transitioning = "false";
			}
		});

		container.addEventListener('transitionend', (ev) ->
		{
			if (this.list.style.top != "100%")
			{
				if (ev.propertyName == "top")
				{
					this.list.style.opacity = "0";
				}

				if (ev.propertyName == "opacity")
				{
					this.list.style.visibility = "hidden";
				}
			}
		});
	}

	private function removeEntries()
	{
		var copycat:Node = items.cloneNode();
		items.replaceWith(copycat);
		items = cast copycat;
	}

	private function populate(entries:Map<String, String>)
	{
		var i:Int = 0;
		for (key => value in entries)
		{
			var option:DivElement = HTML.dom().createDivElement();
			option.classList.add('entry');
			option.textContent = StringTools.trim(key);
			option.dataset.value = StringTools.trim(value);
			option.dataset.index = Std.string(i);

			option.addEventListener('click', () ->
			{
				for (i in 0...items.children.length)
				{
					var child:Element = items.children.item(i);
					if (child.dataset.index == option.dataset.index)
					{
						child.dataset.selected = Std.string(true);
						child.style.backgroundColor = "var(--accent)";
						wrapper.dataset.curSelected = Std.string(i);

						if (wrapper.dataset.permamentHeader == null)
						{
							header.textContent = child.textContent;
						}

						wrapper.dispatchEvent(new CustomEvent("change", {
							bubbles: true,
							detail: {name: child.textContent, value: child.dataset.value, index: i}
						}));
						header.click();
					}
					else
					{
						child.dataset.selected = Std.string(false);
						child.style.backgroundColor = "transparent";
					}
				}
			});

			items.append(option);

			i++;
		}
	}

	private function refreshEntries(entries:Map<String, String>)
	{
		removeEntries();
		populate(entries);
	}

	public static function visibleCheck()
	{
		HTML.dom().body.addEventListener('click', (ev) ->
		{
			var children:NodeList = HTML.dom().body.querySelectorAll('.type-combo-box');
			for (child in children)
			{
				var el:Element = cast child;
				if ((ev.target == HTML.dom().body || ev.target != el)
					&& (el.dataset.visible != null && el.dataset.visible == "true")
					&& (el.dataset.transitioning != null && el.dataset.transitioning == "false"))
				{
					el.setAttribute("visible", "false");
				}
			}
		});
	}
}
