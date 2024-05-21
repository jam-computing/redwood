# Redwood
Mathmatical / Scripting language to create animations to be displayed on a tree with Evergreen.

TODO:

- [x] Design Language
- [x] Read in from file
- [x] Lexer
- [x] Parser
- [ ] Math lexer + parser ( so fun )
- [ ] Spit output to a file ( no need to reinvent the wheel - use json )
- [ ] Without a led file, spit out a list of grids
- [ ] With a led file, convert list of grids to led colours

Code Example

```
import tick as t

let p: node{ plane }

@p f(t): v3 = t, t, t
```

### Creating animations

- With arguement flags?
- Do it in repl?
- Config file?
