In order to specify fixed-point networks, .nn (for the network) and .int (for the interface) files are used.
This file documents their specification.


== Syntax ==

These files are given in s-expression format, where the whole file is an s-expression.
An s-expression is a list of whitespace-separated s-expressions and words. When an s-expression is inside
another s-expression, it is enclosed in parentheses. Words can either be strings containing any character
except spaces or parentheses, or quoted text ("...my text...") where you can have spaces and parentheses,
but you must escape the quote (") and backslash (\) characters by preceding them with a backslash (\) in order
to make them appear.

Words and s-expressions which appear in the file without being nested in further s-expressions will be referred
to as being at the "top level".


== General Semantics ==

The file is expected to start with an identifier word signifying the type of file ("nnet-codegen" for .nn files
and "int-codegen" for .int files). Afterward, any word appearing at the top level is ignored, like a comment.
If a top-level s-expression starting with the word "define" is encountered, then that corresponds to a macro definition.
The second element of the s-expr should be a word representing the name of the macro. The last element is a word or s-expr
(the "macro body"). Once the macro definition is encountered, the macro then immediately starts recursively searching through
every s-expression following itself (excluding itself) and replaces every word which is the concatenation of a sigil and the
macro name with the macro body. There are two sigils, '$' and '@'. '$' means that the body is pasted directly with its parentheses,
while '@' removes the enclosing parentheses before pasting.
For example:
"""
(define abc (hello (world !!! abc)))
(foo (bar abc $abc))
(baz @abc)
"""
becomes:
"""
(define abc (hello (world !!! abc)))
(foo (bar abc (hello (world !!! abc))))
(baz hello (world !!! abc))
"""

Similarly, if a top-level s-expression of the form (import macro-name filename) is encountered, then the file at "filename"
(path relative to the calling file) is read as one s-expression and pasted in the same way as with "define" in the next s-exprs.
For example, if we have "my-data.nn":
"""
a b c (d 11 22 33) x
"""
then, another file "wat.txt" in the same directory:
"""
(import wat "./my-data.nn")
(wat
  $wat
  @wat)
"""
becomes:
"""
(import wat "./my-data.nn")
(wat
  (a b c (d 11 22 33) x)
  a b c (d 11 22 33) x)
"""


== Network (.nn) Semantics ==

Other than what was mentionned previously, .nn files allow only s-expressions starting with the word "network" at the top level.
There can be as many of those as necessary, and each corresponds to a separate network architecture. The second element of the
network s-expr is expected to be an input clause of the form (input *n-inputs* *fixed-spec*) where *n-inputs* is a number giving
the number of input values and *fixed-spec* has the form (fixed *int-part* *frac-part*) where *int-part* is the number of bits
of the integer part of a fixed-point value (including the sign bit) and *frac-part* is the number of bits of the fraction part.
After the input clause, any number of layer clauses can be added (in order) inside the network s-expr.

=== Currently available layers ===

- Fully-connected layer, with the form (fc *output-clause* *weights-clause* *simd-clause* *neuron-clause*)
  - *output-clause* has the form (output *n-outputs* *fixed-spec*) where *n-outputs* is the number of neurons and *fixed-spec*
    is the fixed-point shape of each output value.
  - *weights-clause* has the form (output *data* [*fixed-spec* | *bits-spec* | ]) where *data* is an s-expr starting with
    the word "data" followed with arbitrarily many real. Another argument, which is either a *fixed-spec* (the fixed-point shape
    of each weight value) or a *bits-spec* (with form (bits *n-bits*), meaning that a *fixed-spec* is automatically calculated
    such that *int-part* + *frac-part* = *n-bits* and *int-part* is large enough to accomodate the weight with the largest
    absolute value), can optionally be added. If it is omitted, then an argument of (bits 8) is implicitly assumed.
  - *simd-clause* has the form (simd *simd-window-width*) where *simd-window-width* is the number of inputs processed in parallel
    (*n-outputs* of the previous layer (or *n-inputs* before the first layer) should be a multiple of this layer's *simd-window-width*).
  - *neuron-clause* is a pipeline of operations to perform on each value before they are sent. It has the form (neuron *ops*...),
    where "*ops*..." is a list of the operations detailed in the following "Currently available operations" section.

=== Currently available operations ===

- Bias, with the form (bias *data* [*fixed-spec* | *bits-spec* | ]) where *data* is the biases (like for the *data* of a *weights-clause*)
  and the other optional argument behaves like the one for the weights of a fully-connected layer, but with a default of (bits 12).
  This simply adds the input value with one of the bias values (indexed by the current output offset). The fixed-point shapes of the
  input and outputs of this operation are determined automatically based on the previous operation.
- Sigmoid, with the form (sigmoid *fixed-spec* *step-precision* *bit-precision*). *fixed-spec* is the fixed-point shape of the operation's
  output value. The operation is implemented by sampling a number of positive values and slopes of the sigmoid function below x = 6, and
  then interpolating between those samples using the real x value. *step-precision* is a number controlling the number of samples (so
  the distance between each sample is 2^-step_precision) and *bit-precision* is the number of bits used to store the fraction part of
  each sample.

Example of a .nn file:
"""
nnet-codegen
(import w "toynetwork-w.nn")
(define b (data
  -0.932403 1.964976 0.849697
))
(network
  (input 6 (fixed 1 8))
  (fc (output 3 (fixed 2 8)) (weights (data @w)) (simd 2)
      (neuron
        (bias $b (fixed 4 8))
        (sigmoid (fixed 2 8) 2 16)))
  (fc (output 2 (fixed 2 8)) (weights (data 0.2 0.4 -0.12 0.0 -0.75 0.67) (fixed 4 4)) (simd 1)
      (neuron
        (bias (data -1.4 2.1) (bits 12))
        (sigmoid (fixed 2 8) 2 16)))
  (fc (output 2 (fixed 2 8)) (weights (data 1.1 -0.1 -0.75 0.45) (bits 8)) (simd 2)
      (neuron
        (bias (data 1.4 -3.0))
        (sigmoid (fixed 2 8) 2 16))))
"""

== Interface (.int) Semantics ==

A .int file can contain everything mentionned in the General Semantics section, plus a top-level interface clause with the form
(interface *interface-type* *args*...). If there are several interface clauses, then only the last is retained. *interface-type*
can be anything in the "Currently available interfaces" section, and "*args*..." depends on the *interface-type*.

=== Currently available interfaces ===

- Block, with the form (interface block). This generates a module with as many inputs and as many outputs as there are in the network.
- Sim, with the form (interface sim *data*), where *data* lists the input values. This is used for simulations where the input data
  is kept fixed, and all the outputs of the network are outputs of the module so they can be verified in a test bench.
- Test, with the form (interface test *data*), where *data* lists the input values. This is used for real testing on a zedboard
  where the middle button starts the process, the 8 switches are used to select the output value and the 8 leds display the 8 lowest bits
  of the selected output value.