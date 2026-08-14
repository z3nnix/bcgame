# Common Mineclonia library functions

## Compatibility functions

### `mcl_util.log_deprecated_call(level, moreinfo)`
  Writes a luanti-style deprecation message to the log.
  When called from a function, it writes to the log the name of the function,
  stating it as a deprecated function, followed by the filename and the line
  number of the function calling the deprecated function.
  If a second argument is given, it is written to next line in the log after
  the deprecation message. This can be used to point to specifics of any
  updated APIs.

#### Arguments:
  level: log level, defaults to "warning".
  moreinfo: optional extra informative message.
