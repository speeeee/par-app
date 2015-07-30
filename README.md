Par-App: a language loosely based off of LISP
====

# What is Par-App?

Par-App is a language written using Racket.  The language focuses on concepts commonly used in point-free languages (e.g. forks).  Not many of the concepts are supported yet, but they will be.

Despite this, Par-App is not necessarily a point-free language itself.  Through lambdas, named parameters are possible.  However, the idea of the language is to minimize the need of variables as much as possible, while still offering them when necessary in a way that doesn't break the "flow" of the program.

The documentation (DOCS) gives a more in-depth look at the language

# What does the compiler do?

As mentioned before, the compiler is written in Racket.  Right now, the compiler outputs pseudo-code that very loosely resembles an untyped C-variant.  This is, of course, subject to change.

# What influenced Par-App?

The main language that influenced Par-App was LISP.  Par-App has a similar list-based structure, where the head of a list is the function and the tail are the arguments.

J, and other point-free languages, were also an influence, as mentioned before.  Concatenative languages (which often are also point-free) were also and influence.
The syntax of the language also somewhat resembles the syntax of the language, FP, though that is not on purpose.

In general, this project is mainly just for fun, and not much else.