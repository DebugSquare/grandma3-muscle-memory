## Installaion
Copy this folder into the `res://addons` folder of your godot project.

Enable the plugin to setup the autoload for `OSCManager` otherwise the plugin will not work.


## Documentation

Classes documented via comments

Any class with the name 'Fetcher' will have this signature:
``` gdscript
signal received(args) # signal with results
func fetch(): # function to request the respective data
	...

```
