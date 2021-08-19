Expressions
---

Rather than pre-calculating the sizes and positions of your shapes, you can get ShapeScript to compute the values for you using *expressions*.

Expressions are formed by combining [literal values](literals.md), [symbols](symbols.md) or [functions](functions.md) with *operators*.


## Operators

Operators are used in conjunction with individual values to perform calculations:

```swift
5 + 3 * 4
```

ShapeScript supports common [infix](https://en.wikipedia.org/wiki/Infix_notation) math operators such as +, -, * and /. Unary + and - are also supported:

```swift
-5 * +7
```

Operator precedence follows the standard [BODMAS](https://en.wikipedia.org/wiki/Order_of_operations#Mnemonics) convention, and you can use parentheses to override the order of evaluation:

```swift
(5 + 3) * 4
```

Because spaces are used as delimiters in [vector literals](literals.md), you need to take care with the spacing around operators to avoid ambiguity. Specifically, unary + and - must not have a space after them, and ordinary infix operators should have balanced space around them.

For example, these expressions would both evaluate to a single number with the value 4:

```swift
5 - 1
5-1
```

Whereas this expression would be interpreted as a 2D vector of 5 and -1:

```swift
5 -1
```


## Members

There are currently no vector or matrix math operators such as dot product or vector addition, but these are mostly not needed in practice due to the [relative transform](transforms.md#relative-transforms) commands.

It is however possible to use vector or [color](materials.md#color) values inside expressions by using the *dot* operator to access individual components:

```swift
define vector 0.5 0.2 0.4
define yComponent vector.y
print yComponent 0.2
```

Like other operators, the dot operator can be used as part of a larger expression:

```swift
define color 1 0.5 0.2
define averageColor (color.red + color.green + color.blue) / 3
print averageColor // 0.5667
```

---
[Index](index.md) | Next: [Functions](functions.md)