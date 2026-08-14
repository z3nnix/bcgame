# mcl_jukebox

## mcl_jukebox.registered_records

Table indexed by item name containing record definitions


## mcl_jukebox.register_record_definition(record_definition)

record_definition:
```LUA
{
	title = "title", --title of the track
	author = "name", --author of the track
	id = "id", -- short string used in the item registration
	texture = "img.png", -- the texture of the track
	sound = "minetest_sound", -- sound file of the track
	exclude_from_creeperdrop = true, --set to true if this record should be excluded from the random drop when creepers get shot by skeletons.
}
```

### example

Let's pretend we have our own mod called `my_mod` with the following folder structure:

```
my_mod/
├── init.lua
├── mod.conf
├── sounds/
│   └── my_mod_awesome_music.ogg
└── textures/
    └── my_mod_record_awesome.png
```

My init.lua would contain the following:

```LUA
mcl_jukebox.register_record_definition({
	title = "Awesome Music",
	author = "Author McAuthor",
	id = "awesometrack",
	texture = "my_mod_record_awesome.png",
	sound = "my_mod_awesome_music",
	exclude_from_creeperdrop = true,
})
```

## mcl_jukebox.register_record(title, author, identifier, image, sound, nocreeper)
This is the old way to use the register function. It is still provided for backwards compatibility reasons. It will convert the arguments to the definition format.
