Documentation
====

# Using the compiler

Simply run the program and a REPL will appear.  Type the expression `(1 2)` into the REPL.  If `{1,2}` is returned, then it works properly.  Essentially, what is returned is the corresponding code (written in the loose C-variant as mentioned in the README).

# Syntax of LISP

Par-App is loosely based off of LISP.

In most LISP-variants, function-calls are written like this:

```
(name args)
```

`name` is the name of the function, while `args` is a list of arguments for the function.  For example, the function `+` can be used on two arguments: `(+ 1 2)`.  However, the expression, `(name args)`, suggests a list of two elements, while `(+ 1 2)` suggests 3.  This is because the size does not matter.  Lists, instead, have two properties, the *head*  (the first element of the list) and the *tail* (the rest of the elements in the list).

To show this, the expression, `(+ 1 2)`, can be written like this:

```
(+ . (1 2))
```

where `+` is the head and `(1 2)` is the tail.  The `.` is an infix operator that concatenates the head and tail.  (Note that this can go farther, the most simplefied form would be `(+ . (1 . (2 . ())))`.

# Syntax of Par-App

What is discussed in the previous section also applies to Par-App, though with differing syntax.

While LISP processes expressions as `(head . tail)`, Par-App processes them as this:

```
head:tail

+:(1 2)
```

The expression, `+:(1 2)` is the exact same as its LISP counterpart, where the `+` is the head, and the `(1 2)` is the tail.  Something to note, however, is that while it may seem as though `:` is the same as `.`, it is **not**.  `:` can be thought of as an infix operator which applies the left as a function to the right, unlike `.` where that just concatenates them.

This may seem, at first, like an unnecessary change in syntax.  However, this will make sense in the next section.

An equivalent for `1 + 2` has been given, but what about for more complex expressions like `(1 + 2) * (1 - 2)`.  This is not difficult to translate, fortunately:

```
*:(+:(1 2) -:(1 2))
```

Because everything (except `:`) is in prefix-notation, the mathematical operations must follow this.  This also shows that it is possible to nest expressions within others.

# Examples of the list-based arguments

To those who are experienced with any C-variant, the expressions `+:(1 2)` and `+(1 2);`, do appear very similar, given that there exists the same function in the C-variant.  However, this is untrue.  As explained in the previous section, functions in Par-App are written as `head:tail`.  It should be remembered that the `tail` is a *list*.

This can be shown with this example:

```
var:(x (1 2))

+:x
rev:(x)
```
**NOTE:** variable definition does not exist yet in the actual language.

What happens here, is that first, global variable `x` is assigned to the list, `(1 2)`.  Notice that this variable is directly used as the arguments for the first function, `+`.  What is produced is `+:(1 2)`.  The second function, `rev`, takes one argument; it takes a list.  Here, `rev` is applied to `((1 2))`, where `x` *is* the argument of `rev`, where with `+`, the list `(1 2)` *itself* was the argument list.  With most C-variants, only the second function-call, `rev:(x)` is reproducible, while the first is impossible.

Using LISP-style syntax, these expressions can be written as `(+ . x)` and `(rev x)`.

# Lambdas & Functions

Lambdas are a very important concept in Par-App in that they are used to build functions.  Lambdas can be seen as having two parts: the arguments and the body.  The arguments are a list of named parameters while the body is any expression using these arguments.  Here is an example of a lambda that increments something by 1:

```
la:((x) +:(x 1))
```

Notice that `la` is a function itself taking two arguments.  As mentioned before, the first arguments is a list of symbols while the body is the application of these symbols.

Here is an example of a lambda in use:

```
[la:((x) +:(x 1))]:(2)
```
**NOTE:** the brackets will be explained in the next section.

This is the same as `+:(2 1)`.  In this case, it is somewhat useless.  However, it is possible to create a *function* that increments something by 1.  Luckily, this is easy to do, because in Par-App, functions are just named lambdas:

```
def:(inc la:((x) +:(x 1)))
```

Again, `def` is its own function, and it takes a symbol representing a name and a lambda, which is what the name represents.

With this new function, the earlier expression can be written like this:

```
inc:(2 1)
```

# Explicit grouping

Earlier, it was mentioned that all infix operations (that is, anything using `:`, since it is the only infix operator) are right-associative.  This can be explained with this example:

```
print:+:(1 2)
```

This is grouped from right-to-left, so `+:(1 2)` is read first, then `print` is applied to the result of that.  Using brackets, the order of evaluation of these can be changed, though changing the order of evaluation has no use with this expression.  In the last section, there was a function call containing brackets.  It can be seen why these are needed when they are taken away:

```
la:((x) +:(x 1)):(2)
```

Using right-to-left associativity, an error immediately shows.  The first function-call would be `((x) +:(x 1)):(2)`, which is not correct.  What should be the arguments to `la` are applied to `(2)` instead.  Brackets prevent this error, as with brackets, the `la` is first applied to `((x) +:(x 1))`:

```
[la:((x) +:(x 1))]:(2)
```

# Forks

This is where the somewhat awkward syntax of Par-App is explained.  As mentioned in the README, Par-App aims to use concepts from point-free style languages.  One of these concepts is the fork.

A fork in Par-App is best described by showing the syntax:

```
(+ -):(1 2)
```

Note this is the exact same as a function call, but the head is a list of functions instead of a single function.  Essentially, *both* functions are applied to the arguments, producing the list of `(+:(1 2) -:(1 2))`.  The list produced acts like any other list, meaning it can be applied to another function.

This allows the previous expression, `*:(+:(1 2) -:(1 2))`, to be written like this:

```
*:(+ -):(1 2)
```

It should be noted here that the expressions are read from right-to-left, meaning that `(+ -):(1 2)` is read first, then `*` is applied to the result of that.

What this means is that it is not necessary to make a variable when more than one function needs to use the same thing.

For example, the list `(1 2)` must be translated into a new list, `(3 2 1)`.
The example isn't really practical, nor is it difficult, but it can show some of the possibilities of forks.  One way to complete this is by concatenating the sum of the list with the reverse of the list.  This can be done like this:

```
cons:(+ la:((x y) (rev:(x y)))):(1 2)
```
**NOTE:** `cons` doesn't exist yet.

Notice the use of the lambda to take both arguments and construct a new list for `rev`.  Without a fork, `(1 2)` would need its own variable.

Something to remember is that all functions in a list to be applied are required to have the *same* number of arguments.  The above fork is an example; both `+` and the lambda require two arguments.

Another thing to note is that the compiler actually processes a list of functions being applied to something as calling the function, `fork`, on the list of functions.  `fork` takes the list of functions and produces a lambda out of them that returns the list of results as mentioned before.  `(+ -)` is actually processed as `fork:(+ -)`, and returns 

`la:((x y) (+:(x y) -:(x y)))`.

This is the reason for the somewhat awkward syntax.  In LISP, the expression, `*:(+ -):(1 2)` would be written as 

`(* . ((+ -) 1 2))` given that LISP processed a list of functions in the same way.

Finally, despite being called forks, they do have their differences from forks in languages like J.  Due to everything in J taking at most two arguments, a fork in J can have only two functions, where the result is applied to another 2-argument function.  In Par-App, a fork can have as many functions with as many arguments given that they all have the same amount of arguments.

# Partial application

When doing something like defining a function, it may be unnecessary and sometimes verbose  to explicitly write variables into the definition.  Sometimes, this can make definitions more clear to read.  One example is when making an alias:

```
def:(alias+ la:((x y) +:(x y)))
def:(alias+ +)
```

The second definition is much more concise and also more readable.  In this specific instance, nothing special happens, considering functions are named lambdas (as mentioned before).  This also holds in most LISP dialects.  However, aliases are not the only instance where implicit variables can be more readable.

Consider that not only is it needed that two numbers are added together, but also the result is printed.  Here is the definition with a lambda:

```
def:(prnsum la:((x y) prn:+:(x y)))
```

This can also be done without parameters as well:

```
def:(prnsum prn:+)
```
**NOTE**: `prn` doesn't exist yet.

At first, it may look as if the lambda `+` itself is being printed, though that would be
`prn:(+)`.  `:` has a special case for when the right argument is a lambda.  Here is the example rewritten with explicit variables:

```
def:(prnsum prn:la:((x y) +:(x y)))
```

What happens, is that when this case is found, the lambda is essentially 'lifted' to the top of the expression.  The above is rewritten as this:

```
def:(prnsum la:((x y) prn:+:(x y)))
```

What this means is that given that the right argument of `:` is a lambda, the result will be another lambda.  This means that `:` acts exactly as it would, just with an amount of required arguments.  This is the final definition of `prnsum`.  

# Partial application and forks

It was mentioned earlier that a list of functions is not by default parsed as a fork.  It only is when it is the left argument of `:` that it is changed to a fork.  This actually introduces a small issue when using partial application.  Consider the expression,
`f(x,y) = (x + y) * (x - y)`.  At first, it may seem possible to write it like this:

```
def:(f +:(+ -))
```

This is actually incorrect.  Because it is not on the left side of `:` and because it is not, itself, a lambda, `(+ -)` is parsed as a list.  This is, of course, problamatic because this results in `+` actually adding the two functions together, which is not possible.  However, there is a function that is used to explicitly make a list into a fork, called `#`.

```
[#:(+ -)]:(1 2)
(+ -):(1 2)
```

These two expressions are the exact same.  One uses the `#` function while the other satisfies the requirements of `:` for it to make it a fork.  Using `#`, the expression,
`f(x,y) = (x + y) * (x - y)`, is written *correctly* as this:

```
def:(f +:#:(+ -))
```

This creates the correct lambda.


**NOTE:** this is the end of the documentation for now, but there should be more later.