# cppia

Load and run [cppia](https://haxe.org/manual/target-cppia.html) scripts in hxcpp games. Scripts are compiled Haxe, so they run much faster than interpreted scripting and can use the game's own classes.

- Entry classes: the class named like the file, `Main` or `Script` is created when the script starts, or the script's `main` runs
- Calls into every script instance, static calls, fields
- Groups with priorities, stop values, folder loading and hot reload
- Error reporting with the script path, the function and the stack
- `haxelib run cppia` tool to create and build scripts
- Safe no-ops on targets without cppia support

## Install

```
haxelib git cppia https://github.com/BrenninhoTools/cppia
```

## Host (the game)

The game must be built with `scriptable`. `dll_export` writes the list of game classes that scripts can use without compiling them again:

```
--macro cppia.macro.Host.setup('export_classes.info', ['my.game'])
```

or by hand:

```
-D scriptable
-D dll_export=export_classes.info
```

Keep the classes scripts need from being removed by dead code elimination, for example with `-dce std` or the keep list above.

```haxe
import cppia.Cppia;
import cppia.CppiaGroup;

Cppia.onError = function(error) showError(Cppia.describe(error));

var scripts = new CppiaGroup();
scripts.hotReload = true;
scripts.loadFolder('mods/scripts');
scripts.call('onCreate');

function update(elapsed:Float)
{
	scripts.update();
	scripts.call('onUpdate', [elapsed]);
}
```

A single file:

```haxe
var module = Cppia.load('mods/scripts/Boss.cppia');
module.call('onBeat', [16]);
module.set('speed', 2);
module.callStatic('Boss', 'spawn', []);
module.destroy();
```

## Scripts

```
haxelib run cppia new MyScript scripts/MyScript
```

```haxe
class MyScript extends cppia.CppiaScript
{
	public function new()
	{
		super();
	}

	public function onCreate():Void {}

	public function onUpdate(elapsed:Float):Void {}
}
```

Build it with the game's `export_classes.info` next to it:

```
haxelib run cppia build MyScript -cp scripts/MyScript -o MyScript.cppia --host export_classes.info
```

Scripts built against an older `export_classes.info` should be rebuilt when the game's classes change.

## License

MIT
