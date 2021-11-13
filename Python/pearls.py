# -*- coding: utf-8 -*-
"""
Created on Tue Nov  9 14:22:45 2021

@author: jpn3t
"""

import time

def clock(f):
  def d(*args): 
    t0 = time.perf_counter()       # marcar tempo antes de executar f
    resultado = f(*args)           # executar função original
    t  = time.perf_counter() - t0  # marcar quanto tempo decorreu

    arg_str = ', '.join(repr(arg) for arg in args)  # imprimir resultado 
    print('[%0.5f ms] %s(%s) -> %r' % (1000*t, f.__name__, arg_str, resultado))

    return resultado # devolver resultado da função original
  return d


#############################################################
# column 1, initial problem

class BitVector:
  """ bit vector with read/write access
      may be harder to add complex operations """  
  def __init__(self, n):
    self.bits = 1 << (n+1)   # highest bit (a 1) is not used
    
  def __setitem__(self, key, i):
    if i==0:
      self.bits &= ~(1<<key) # flip all bits then apply 'and'
    else:
      self.bits |= 1<<key

  def __getitem__(self, key):
    return 1 if self.bits & 1<<key else 0
    
  def __repr__(self):
    return bin(self.bits)[3:][::-1]
  
size = 8
input_file = '1 3 5 2 12 2 16 8'

b = BitVector(size)
for n in [int(i) for i in input_file.split(' ')]:
  b[n] = 1
  
output_file = [i for i,d in enumerate(str(b)) if d=='1']
# print(output_file)  

#############################################################
# column 2A, binary search to find missing element

# Given a sequential file that contains at most four billion 
# 32 bit integers in random order, find a 32-bit integer that
# isn't in the file (and there must be at least one missing)

def findMissing(xs, nbits=8):
  result = ''
  bits = [bin(x)[2:].rjust(nbits, '0') for x in xs]
  
  while bits:
    lower = [x[1:] for x in bits if x[0]=='0']
    upper = [x[1:] for x in bits if x[0]=='1']
    if len(lower) < len(upper):
      result += '0'
      bits = lower
    else:
      result += '1'
      bits = upper
      
  return int(result.ljust(nbits-len(result), '0'), 2)

# test
from random import shuffle

nbits = 8
for i in range(2**nbits):
  xs = list(range(2**nbits))
  del xs[i]
  shuffle(xs)
  assert findMissing(xs, nbits) == i

#############################################################
# column 2B, binary search to shift list

# i>0 shift left, i<0 sight right
def shift(xs, i):
  return (xs[:i][::-1] + xs[i:][::-1])[::-1]

#############################################################
# column 2C, find anagrams using a key that is shared by them

def anagrams(xs):
  def mk_key(word):
    return tuple(sorted(word))
  
  dic = {}
  for x in xs:
    if mk_key(x) in dic:
      dic[mk_key(x)].append(x)
    else:
      dic[mk_key(x)] = [x]
  return [xs for xs in dic.values()]


assert (anagrams(['and', 'dna', 'rome', 'emor', 'nad', 'xyz'])
        == [['and', 'dna', 'nad'], ['rome', 'emor'], ['xyz']])

#############################################################
# column 4, binary search

def binSearch(x, xs):
  """ my solution """
  a, b = 0, len(xs)-1
  
  while a<=b:
    mid = (a+b)//2
    if x == xs[mid]:
      return mid
    if x < xs[mid]:
      b = mid-1
    else:
      a = mid+1

  return None

xs = list(range(200))
for i in range(200):
  if binSearch(i,xs) is None:
    print("bug", i)
    
# 4.6.3, recursive version

def binSearch(x, xs, a=None, b=None):
  """ my solution """
  if a==None:
    a, b = 0, len(xs)-1
    
  if a>b:
    return None

  mid = (a+b)//2
  if x == xs[mid]:
    return mid
  
  if x < xs[mid]:
    return binSearch(x, xs, a, mid-1)  
  else :
    return binSearch(x, xs, mid+1, b)  
    
xs = list(range(200))
for i in range(200):
  if binSearch(i,xs) is None:
    print("bug", i)

#############################################################
# column 8, max sum of part of a vector

def maxSub1(xs):
  """ O(n^3) """
  result, n = 0, len(xs)
  for i in range(n):
    for j in range(i,n):
      result = max(result, sum(xs[i:j+1]))
  return result

def maxSub2(xs):
  """ O(n^2) """
  result, n = 0, len(xs)
  for i in range(n):
    sumSub = 0
    for j in range(i,n):
      sumSub += xs[j]
      result = max(result, sumSub)
  return result

from itertools import accumulate
def maxSub3(xs):
  """ O(n^2), uses a cumulative sum list """
  cumsum = [0]+list(accumulate(xs))  # first 0 is index -1 in book
  result, n = 0, len(xs)
  for i in range(n):
    for j in range(i,n):
      result = max(result, cumsum[j+1]-cumsum[i])
  return result

def maxSub4(xs, a=None, b=None):
  """ O(n log n), divide and conquer, recursive """
  if a is None:
    a, b = 0, len(xs)-1  # range to search for max sum
  
  if a>b:
    return 0
  if a==b:
    return max(0,xs[a])
  
  mid = (a+b)//2
  a_max = sumSub = 0
  for i in range(mid, a, -1): # search left
    sumSub += xs[i]
    a_max = max(a_max, sumSub)
  b_max = sumSub = 0
  for i in range(mid+1, b+1): # search right
    sumSub += xs[i]
    b_max = max(b_max, sumSub)
  
  return max(a_max+b_max, maxSub4(xs, a, mid), maxSub4(xs, mid+1, b))

def maxSub5(xs):
  """ O(n), scans list once """
  maxSoFar, runningSum = 0, 0
  for _,x in enumerate(xs):
    if runningSum < 0:
      runningSum = 0
    if maxSoFar < runningSum:
      maxSoFar = runningSum
    runningSum += x
    # runningSum  = max(runningSum + x, 0) # some many max calls
    # maxSoFar = max(maxSoFar, runningSum) # take much execution time
  return max(maxSoFar, runningSum)

# save state to avoid recomputation
# preprocess information into data structure (like cumsum)
# remember divide-and-conquer algorithms

####

xs = [31, -41, 59, 26, -53, 58, 97, -93, -23, 84]
assert maxSub1(xs) == 187
assert maxSub2(xs) == 187
assert maxSub3(xs) == 187
assert maxSub4(xs) == 187
assert maxSub5(xs) == 187

# check runtimes
from random import sample
xs = sample(range(-5000,5000), 1000)

@clock
def test1():
  return maxSub1(xs)

@clock
def test2():
  return maxSub2(xs)

@clock
def test3():
  return maxSub3(xs)

@clock
def test4():
  return maxSub4(xs)

@clock
def test5():
  return maxSub5(xs)

# test1(); test2(); test3(); test4(); test5()




















