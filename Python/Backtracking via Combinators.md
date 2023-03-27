## Backtracking via Combinators


[Allison90](http://www.allisons.org/ll/Publications/1990BCJ/) uses the term _generator_ as a function that transforms continuations. The paper uses this concept to simulate non-deterministic computations.

Herein, a _continuation_ is a function from a (partial) state to a list of (partial) states, and a _generator_ is a function from a continuation to a continuation,

    cont :: state -> [state]

    gen :: cont -> cont

In the following examples, a state will be a list of integers.

<!-- original ML code for what follows (run at https://sosml.org/editor)
fun ret a = [a];

fun fail h a = [];

fun run g = g ret [];

(******************)

fun literal c h a = h( c::a );
print (run (literal 3));

fun pipe g1 g2 h a = g1(g2 h)a;
print (run (pipe (literal 1) (literal 2)));

fun success h a = h a;

fun do_ n g = if n=0 
                then success
                else pipe (do_ (n-1) g) g;
print (run (do_ 5 (literal 1) ));

fun either g1 g2 h a = (g1 h a) @ (g2 h a);

print (run (either (pipe (literal 1) (literal 2))
                   (literal 3) ) );

fun choice n = if n=0 
                 then fail
                 else either (literal n) (choice (n-1));

print ( run( do_ 3 (choice 2) ));

fun filter p h a = if p a 
                     then h a
                     else [];

fun first_one (h::t) = h=1;

print (run (pipe (do_ 3 (choice 2)) 
                 (filter first_one)));

--> 

Let's consider the generator `literal` that, for a given value, prepends that value to a (partial) state:


```python
literal = lambda value: lambda cont: lambda state: cont([value]+state)
```

To observe states, let's add

+ `ret` a continuation that just returns the given state as a list

+ `run` a function that executes a generator and returns the list of all list of states


```python
ret = lambda x: [x]

run = lambda gen: gen(ret)([])
```

Let's try them with `literal`,


```python
run(literal(1))
```




    [[1]]



Generator `pipe` is used to create a generator that is a sequence of two generators,


```python
def pipe(gen1, gen2):
  return lambda cont: lambda state: gen1(gen2(cont))(state)
```


```python
g1 = literal(1)
g2 = literal(2)
g3 = pipe(g1, g2) # g1 only after g2, like function composition

run(g3)
```




    [[2, 1]]



We can also implement a n-ary pipe (while gladly taking the chance to use `reduce`):


```python
from functools import reduce

def pipes(*gens):
  def f(cont):
    def g(state, gens=gens):
      gen, *gens = gens
    # new_cont = gen2(gen3(gen4(...genN(cont))))
      new_cont = reduce(lambda acc, g: g(acc), gens[::-1], cont)
      return gen(new_cont)(state)
    return g
  return f
```


```python
g4 = pipes(g2, g1, literal(4), g3)
run(g4)
```




    [[2, 1, 4, 1, 2]]



The next two generators will be useful for backtracking purposes in defining a successful branch and a failed branch,


```python
success = lambda cont: lambda state: cont(state)
fail    = lambda cont: lambda state: []
```

Generator `do` pipes a given generator a given number of times,


```python
def do(gen, n):
  if n==0:
    return success
  return pipe(do(gen, n-1), gen)
```


```python
g5 = do(g3, 5)  
run(g5)
```




    [[2, 1, 2, 1, 2, 1, 2, 1, 2, 1]]



Generator `either` is the one introducing non-determinism into the computation. It receives a list of generators and produces a generator which behaves as a non-determinist choice between all given generators.

The continuation is passed to all generators, in depth-first search style.


```python
from operator import add

# def either(gen1, gen2):
#   """ just two generators """
#   return lambda cont: lambda state: gen1(cont)(state) + gen2(cont)(state)

def either(*gens):
  return lambda cont: lambda state: add(*[gen(cont)(state) for gen in gens])
```

One use case of `either`: generator `choice` prepends values $n$ to $1$ to all given states,


```python
def choice(n):
  if n==0:
    return fail
  return either(literal(n), choice(n-1))
```

To produce the cartesian product of values $1,2,3$


```python
g6 = do(choice(3), 3)
run(g6)
```




    [[3, 3, 3],
     [2, 3, 3],
     [1, 3, 3],
     [3, 2, 3],
     [2, 2, 3],
     [1, 2, 3],
     [3, 1, 3],
     [2, 1, 3],
     [1, 1, 3],
     [3, 3, 2],
     [2, 3, 2],
     [1, 3, 2],
     [3, 2, 2],
     [2, 2, 2],
     [1, 2, 2],
     [3, 1, 2],
     [2, 1, 2],
     [1, 1, 2],
     [3, 3, 1],
     [2, 3, 1],
     [1, 3, 1],
     [3, 2, 1],
     [2, 2, 1],
     [1, 2, 1],
     [3, 1, 1],
     [2, 1, 1],
     [1, 1, 1]]



The next generator filters states by predicate:


```python
def filt(p):
  return lambda cont: lambda state: cont(state) if p(state) else []
```

The next use case filters the previous cartesian product by selecting only those states starting with value $1$,


```python
first_one_only = lambda st: st[0]==1

run(pipe(g6, filt(first_one_only)))
```




    [[1, 3, 3],
     [1, 2, 3],
     [1, 1, 3],
     [1, 3, 2],
     [1, 2, 2],
     [1, 1, 2],
     [1, 3, 1],
     [1, 2, 1],
     [1, 1, 1]]



Let's produce the Pythagorean triples up to a certain limit:


```python
def less_than(state):
  return len(state)<2 or state[0]<state[1]

def is_pyth(state):
  a,b,c = state
  return a*a + b*b == c*c

def pyth_triples(limit):
  pick_number = pipe(choice(limit), filt(less_than))
  pick_3 = do(pick_number, 3)
  return run(pipe(pick_3, filt(is_pyth)))

%timeit pyth_triples(50)  
```

    96.7 ms ± 29.2 ms per loop (mean ± std. dev. of 7 runs, 10 loops each)
    

### The n-Queen problem

Let's check how to use these combinators to solve the famous n-queen problem.

The next standard Python function will be used to prune invalid branches,


```python
def valid(state):
  """ checks if first queen does not threat the other queens """
  for i in range(1,len(state)):
    if ( state[0] == state[i] or       # if same line
         abs(state[0]-state[i]) == i): # or same diagonal
      return False
  return True
```

With all these tools, backtracking the n-queen problem can be solved by applying the following combinators:


```python
def queens(n):
  place_a_queen = pipe(choice(n), filt(valid))
  return run(do(place_a_queen, n))

print(*queens(6), sep='\n')
```

    [2, 4, 6, 1, 3, 5]
    [3, 6, 2, 5, 1, 4]
    [4, 1, 5, 2, 6, 3]
    [5, 3, 1, 6, 4, 2]
    
