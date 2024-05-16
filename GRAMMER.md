# Language Overview

Redwood is a functional programming language.

### Declaring a `node`:
A `node` is a `object` with some functions

```
define {node name} {object type}
```

### Importing Values:

Here are all the values that can be imported:

- Tick
- Tree width + height

```
import {value} as {import_name}
```

### Declaring a function

Functions in redwood are basically just math

Functions must be attached to a `node`, with the `@` syntax

```
@node_name func_name(input) = output
```


### Special functions

In redwood, there are 3 special functions, which every node has

- `ini` Runs at the start of the animation.
- `st` Runs every tick
- `col` Runs every tick and defines the colour

All of these functions return a v3


### Example, basic node

```
@import tick as t

define p plane

@p ini(_) = 0
@p st(t) = 0, t, 0
@p col(_) = 0, 255, 0
```

### Function Decorators

Each function can have some special properties attached.

If the `!` is on a line of one of the functions, it will be exported


### Tree specific functions

some functions can be applied to the entire tree.

For example, the `col` function can be applied to the whole tree.
