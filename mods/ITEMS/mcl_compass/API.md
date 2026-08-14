# mcl_compass

# Compass API

##mcl_compass.register_compass(name, definition)

### Compass definition:
{
    name = "mycompass",
    name_fmt = "",
    overrides = { --item definition overrides e.g. description etc.
        _mcl_compass_img_fmt = "", --format string to build the item image from a compass frame number
        _mcl_compass_update = function(stack, player) end, --function to update the compass item, will be run regularily in player inventories, should return the updated itemstack
    }
}
