# `mcl_signs` API Reference

## Functions

* `mcl_signs.register_sign(name, color, [definition])`
    * `name` is the part of the namestring that will follow `"mcl_signs:"`
    * `color` is the HEX color value to color the greyscale sign texture with.
      **Hint:** use `""` or `"#ffffff"` if you're overriding the texture fields
      in sign definition
    * `definition` is optional, see section below for reference

## Sign definition

```lua
{
    -- This can contain any node definition fields which will ultimately make
    -- up the sign nodes.
    -- Usually you'll want to at least supply `description`:
    description = S("My Sign"),

    -- If you don't want to use texture coloring, you'll have to supply the
    -- textures yourself:
    tiles = {"my_sign.png"},
    inventory_image = "my_sign_inv.png",
    wield_image = "my_sign_inv.png",
}
```
