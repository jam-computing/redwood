# Redwood
Mathmatical / Scripting language to create animations to be displayed on a tree with Evergreen.

TODO:

- [x] Design Language
- [x] Read in from file
- [ ] Some mathmatical lib cause no way am i being mathmatic
- [x] Lexer
- [x] Parser
- [ ] Spit output to a file ( no need to reinvent the wheel - use json )

- [ ] Without a led file, spit out a list of grids
- [ ] With a led file, convert list of grids to led colours


Lex one line at time - each line is a `component` of the animation


### Imporoting / Binding

- When importing, replace each occurance of the imported identifier with a unique identiifer

Code Example
```
import tick as t

define p plane

@p f(t) = t, t, t
```

### Creating animations

- With arguement flags?
- Do it in repl?
- Config file?


###  refacotrj
refactor code -> Make nice

### return values on functions ( technically methods ? )

### Seriosly considering getting rid of "node"s interely
