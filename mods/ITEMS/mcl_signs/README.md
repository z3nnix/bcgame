# `mcl_signs`

* Originally based on reworked signs mod by PilzAdam (<https://forum.luanti.org/viewtopic.php?t=3289>)
* Adapted for MineClone2 by Wuzzy
* Later massively extended by Michieal
* Mostly rewritten for Mineclonia and simplified by cora
* Reworked for VoxeLibre with UTF-8 support by rudzik8
* Word wrap algorithm improved by kno10

## Characters

All characters are mapped to their textures in `characters.tsv`. See section
below for technical details.

Currently supported character sets:

* [ASCII](https://en.wikipedia.org/wiki/ASCII)
* [Latin-1](https://en.wikipedia.org/wiki/ISO/IEC_8859-1) (Western European)
* [Latin-2](https://en.wikipedia.org/wiki/ISO/IEC_8859-2) (Central/Eastern European)
* [Latin-3](https://en.wikipedia.org/wiki/ISO/IEC_8859-3) (South European)
* [Latin-4](https://en.wikipedia.org/wiki/ISO/IEC_8859-4) (North European)
* [Latin-5/Cyrillic](https://en.wikipedia.org/wiki/ISO/IEC_8859-5)
  * with additional glyphs and diacritics
* [Latin-7/Greek](https://en.wikipedia.org/wiki/ISO/IEC_8859-7)
* Other math-related/miscellaneous characters

## Character map (`characters.tsv`)

It's a UTF-8 encoded text file that contains metadata for all supported
characters. Despite its file extension and the theoretical possibility of
opening it in a spreadsheet editor, it's still plaintext values separated by
`\t` (tab idents). The separated values are _columns_, and the lines they are
located at are _rows_. It's customary that different character sets are
separated with an empty line for readability.

The format expects 1 row with 3 columns per character:

* **Column 1:** The literal (as-is) glyph. Only [precomposed characters](https://en.wikipedia.org/wiki/Precomposed_character)
  are supported for diacritics
* **Column 2:** Name of the texture file for this character minus the ".png"
  suffix (found in the `textures/` sub-directory in root)
* **Column 3:** Currently ignored. This is reserved for character width in
  pixels in case the font will be made proportional

All character textures must be 12 pixels high and 5 or 6 pixels wide (5
is preferred).

Can be accessed by other mods via `mcl_signs.charmap[<utf-8 codepoint>]`.

## Internals

The signs code internally uses Lua lists (array tables) of UTF-8 codepoints to
process text, as Lua 5.1 makes too many assumptions about strings that don't
apply to Unicode text.

From [Lua 5.1 Reference Manual, §2.2](https://www.lua.org/manual/5.1/manual.html#2.2):

> _String_ represents arrays of characters. Lua is 8-bit clean: strings can
> contain any 8-bit character, including embedded zeros (`'\0'`).

This is OK when all you have is ASCII, where each character really does take up
just 8 bits, or 1 byte. And the code prior to the rework even made some
workarounds to support 2 byte values for the Latin-1 character set. But a UTF-8
character can be up to 4 bytes in size! And when we try to treat a 4 byte
character as a 2 byte one, we get 2 invalid characters! Unthinkable!

Luckily, modlib's `utf8.lua` comes to rescue with its codepoint handlers. We
use `utf8.codes` to cycle through user input strings and convert them to the
codepoint lists mentioned previously, which will be referred to here as
_UTF-8 strings_, or _u-strings_ for short.

## License

**Code:** MIT
* `utf8.lua` is from `modlib`, by Lars Mueller alias LMD or appguru(eu) [(source)](https://github.com/appgurueu/modlib/blob/master/utf8.lua)
* See `LICENSE` file for details

**Font:** CC0
* Originally by PilzAdam (WTFPL)
* Modified and massively extended by rudzik8
* Can be found in the `/textures` sub-directory of game root, prefixed with `_`
* See <https://creativecommons.org/publicdomain/zero/1.0/> for details

**Models:** GPLv3
* by 22i: <https://github.com/22i/amc>
* See <https://www.gnu.org/licenses/gpl-3.0.html> for details
