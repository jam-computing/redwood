# Redwood
Mathmatical / Scripting language to create animations to be displayed on a tree with Evergreen.

TODO:

- [ ] Design Language
- [x] Read in from file
- [ ] Some mathmatical lib cause no way am i being mathmatic
- [ ] helper functions for parser and lexer
- [ ] Lexer
- [ ] Parser
- [ ] Spit output to a file ( no need to reinvent the wheel - use json )

- [ ] Without a led file, spit out a list of grids
- [ ] With a led file, convert list of grids to led colours


Lex one line at time - each line is a `component` of the animation


### Imporoting / Binding

- When importing, replace each occurance of the imported identifier with a unique identiifer


example
```
import tick as t

@node ini(t) = 0
```


