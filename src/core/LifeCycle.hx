package core;

import core.DebugUI.DebugElement;
import core.DebugUI.IDebugComponent;
import core.TickerObject.TickerState;
import core.TimerObject;
import haxe.Timer;
import js.html.SpanElement;

// Ironic isn't it? A Debugable that is implemented into the owner of the Debug UI lmao
class LifeCycle implements IDebugComponent
{
	private static final FASTEST_TICK_LIMIT = 30; // below 30 ticks is very fast and might make the ui blink

	@:noCompletion
	private static var instance:LifeCycle;

	@:noCompletion
	private var d_added:Bool = false;

	@:noCompletion
	private var d_elements:Array<DebugElement> = [];

	private static var ui:DebugUI;
	private static var initialized:Bool = false;

	private static var timers:Array<TimerObject> = [];
	private static var tickers:Array<TickerObject> = []; // functions called on each tick, maybe find a better name lol

	public static var ticks:Int = 0;
	public static var fps:Float = 0;

	// public static var elapsed:Float = 0;
	@:noCompletion
	private static var frames:Int = 0;

	@:noCompletion
	private static var prevTime:Float = 0;

	private function new()
	{
		instance = this;
	}

	public static function initialize():Void
	{
		if (initialized)
			return;

		#if debug
		ui = new DebugUI();
		// needed, might move to instance for Main.loop.<func>
		new LifeCycle();
		ui.add(instance); // no way
		#end

		initialized = true;
		HTML.window().requestAnimationFrame(tick);
	}

	public static function timer(time:Int, func:?Any->Void, loops:Int = 1, arg:Any = null):TimerObject
	{
		var nTimer:TimerObject = new TimerObject(time, func, loops, arg);

		// dummy shit lmao
		var found:Bool = false;
		for (timer in timers)
		{
			if (timer.time == nTimer.time)
				found = true;
		}

		if (!found)
			timers.push(nTimer);

		return nTimer;
	}

	// add cuz its being added to the tick queue and will be called next tick
	public static function add(func:Int->TickerState):TickerObject
	{
		var nTicker:TickerObject = new TickerObject(func);

		if (!tickers.contains(nTicker))
			tickers.push(nTicker);

		return nTicker;
	}

	// First update the variables, next run the tickers, then run the timers and to finish update the debug ui and increase ticks also request a new animation frame
	// should unify the running classes into an interface and extend the usability in there???
	private static function tick(_:Float):Void
	{
		updateFPS();

		for (obj in tickers)
		{
			#if debug
			if (!obj.d_added)
				ui.add(obj);
			#end

			var res:TickerState = obj.func(ticks);
			obj.calls++;
			if (res == STOPPED || obj.state == STOPPED)
			{
				tickers.remove(obj);
				#if debug
				if (obj.d_added)
					ui.remove(obj);
				#end
				obj.dispose();
				obj = null;
				continue;
			}
		}

		for (obj in timers)
		{
			#if debug
			if (!obj.d_added && obj.time > FASTEST_TICK_LIMIT)
				ui.add(obj);
			#end

			if (obj.canceled)
			{
				timers.remove(obj);
				#if debug
				if (obj.d_added)
					ui.remove(obj);
				#end
				obj.dispose();
				obj = null;
				continue;
			}

			obj.ticks++;

			if (obj.ticks >= obj.time)
			{
				obj.ticks = 0;
				obj.runs++;
				obj.func(obj.arg);

				if (obj.onLoop != null)
					obj.onLoop(ticks);

				if (obj.loops != -1 && obj.runs >= obj.loops)
				{
					timers.remove(obj);
					obj.finished = true;
					if (obj.onFinish != null)
						obj.onFinish(obj.runs);
					#if debug
					if (obj.d_added)
						ui.remove(obj);
					#end
					obj.dispose();
					obj = null;
				}
			}
		}

		#if debug
		ui.update();
		#end

		ticks++;
		HTML.window().requestAnimationFrame(tick);
	}

	private static function updateFPS():Void
	{
		frames++;

		var ppTime:Float = prevTime;
		var time:Float = Timer.stamp();

		if (time > ppTime + 1)
		{
			// elapsed = (time - ppTime) / 100;
			fps = frames / (time - ppTime);
			prevTime = time;
			frames = 0;
		}
	}

	// DEBUG - sorry i keep laughing about adding debug stuff into the same class that has the debug ui in it, its 5 am please
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
			name: "FPS",
			element: HTML.dom().createSpanElement(),
			parent: d_elements[0].element
		});
		d_elements.push({
			name: "Ticks",
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

				case "FPS":
					cast(dbgEl.element, SpanElement).textContent = '[ ${dbgEl.name}: ${Math.ceil(fps)} |';

				case "Ticks":
					cast(dbgEl.element, SpanElement).textContent = ' ${dbgEl.name}: $ticks ]';
			}
		}
	}
}
