Finally

<code class="haskell">
-- Version 8
import Data.List (foldl')
evenSum :: Integral a => [a] -> a
evenSum l = foldl' (+) 0 (filter even l)
</code>

`foldl'` isn't the easiest function to intuit.
If you are not used to it, you should study it a bit.

To help you understand what's going on here, a step by step evaluation:

<pre>
  <span class="yellow">evenSum [1,2,3,4]</span>
⇒ foldl' (+) 0 (<span class="yellow">filter even [1,2,3,4]</span>)
⇒ <span class="yellow">foldl' (+) 0 <span class="blue">[2,4]</span></span>
⇒ <span class="blue">foldl' (+) (<span class="yellow">0+2</span>) [4]</span> 
⇒ <span class="yellow">foldl' (+) <span class="blue">2</span> [4]</span>
⇒ <span class="blue">foldl' (+) (<span class="yellow">2+4</span>) []</span>
⇒ <span class="yellow">foldl' (+) <span class="blue">6</span> []</span>
⇒ <span class="blue">6</span>
</pre>


Another useful higher order function is `(.)`.
The `(.)` function corresponds to the mathematical composition.

<code class="haskell">
(f . g . h) x ⇔  f ( g (h x))
</code>

We can take advantage of this operator to η-reduce our function:

<code class="haskell">
-- Version 9
import Data.List (foldl')
evenSum :: Integral a => [a] -> a
evenSum = (foldl' (+) 0) . (filter even)
</code>

Also, we could rename some parts to make it clearer:

> -- Version 10 
> import Data.List (foldl')
> sum' :: (Num a) => [a] -> a
> sum' = foldl' (+) 0
> evenSum :: Integral a => [a] -> a
> evenSum = sum' . (filter even)
>  

It is time to discuss a bit.
What did we gain by using higher order functions?

At first, you can say it is terseness.
But in fact, it has more to do with better thinking.
Suppose we want to modify slightly our function.
We want to get the sum of all even square of element of the list.

~~~
[1,2,3,4] ▷ [1,4,9,16] ▷ [4,16] ▷ 20
~~~

Update the version 10 is extremely easy:

> squareEvenSum = sum' . (filter even) . (map (^2))
> squareEvenSum' = evenSum . (map (^2))
> squareEvenSum'' = sum' . (map (^2)) . (filter even)

We just had to add another "transformation function"[^0216].

[^0216]: You should remark `squareEvenSum''` is more efficient that the two other versions. The order of `(.)` is important.

~~~
map (^2) [1,2,3,4] ⇔ [1,4,9,16]
~~~

The `map` function simply apply a function to all element of a list.

We didn't had to modify anything _inside_ the function definition.
It feels more modular.
But in addition you can think more mathematically about your function.
You can then use your function as any other one.
You can compose, map, fold, filter using your new function.

To modify version 1 is left as an exercise to the reader ☺.

If you believe we reached the end of generalization, then know you are very wrong.
For example, there is a way to not only use this function on lists but on any recursive type.
If you want to know how, I suggest you to read this quite fun article: [Functional Programming with Bananas, Lenses, Envelopes and Barbed Wire by Meijer, Fokkinga and Paterson](http://eprints.eemcs.utwente.nl/7281/0
1/db-utwente-40501F46.pdf).

This example should show you how great pure functional programming is.
Unfortunately, using pure functional programming isn't well suited to all usages.
Or at least such a language hasn't been found yet.

One of the great powers of Haskell is the ability to create DSLs
(Domain Specific Language)
making it easy to change the programming paradigm.

In fact, Haskell is also great when you want to write imperative style programming.
Understanding this was really hard for me when learning Haskell.
A lot of effort has been done to explain to you how much functional approach is superior.
Then when you start the imperative style of Haskell, it is hard to understand why and how.

But before talking about this Haskell super-power, we must talk about another
essential aspect of Haskell: _Types_.

<div style="display:none">

> main = print $ evenSum [1..10]

</div>
