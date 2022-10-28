import numpy as np 
import matplotlib.pyplot as plt

def criar_grelha(xmin, xmax, grelha):
  x, dx, xs = xmin, abs(xmax-xmin)/grelha, []
  while x <= xmax:
    xs.append(x)
    x += dx
  return xs



def desenhar_funcoes(fs, xmin, xmax, grelha=256, figsize=(5,5)):
  fig, ax = plt.subplots(figsize=figsize)
  ax.spines['left'].set_position('center')
  ax.spines['right'].set_color('none')
  ax.spines['top'].set_color('none')
  
  xs = criar_grelha(xmin, xmax, grelha)
  for f, color in zip(fs, 'bgrcmyk'): # b é azul, g é verde, r é vermelho, etc.
    ys = [f(x) for x in xs] 
    plt.plot(xs, ys, color)
  
  plt.show()
  


def tab_sinal(poly):
  """ tabela de variação de sinal """
  roots = sorted(np.roots(poly))
  rs = [roots[0]-1] + roots + [roots[-1]+1] # add extra extreme vals 
    
  result = []
  for i in range(1,len(rs)):
    if np.polyval(poly, (rs[i-1]+rs[i])/2) > 0:
      result.append('++')
    else:
      result.append('--')
    result.append(np.round(rs[i],6))
  
  return '  '.join(str(i) for i in result[:-1])



def tab_monotonia(poly): 
  poly_deriv = [] # criar derivada
  for grau,coef in enumerate(poly[:-1]):
    poly_deriv.append(coef*(len(poly)-grau-1))
  
  roots = sorted(np.roots(poly_deriv))
  rs = [roots[0]-1] + roots + [roots[-1]+1] # add extra extreme vals 
    
  result = []
  for i in range(1,len(rs)):
    dx = abs(abs(rs[i-1])-abs(rs[i])) # interval size btw two extremes
    y1 = np.polyval(poly, rs[i-1]+dx/3)
    y2 = np.polyval(poly, rs[i-1]+dx/2)
    if y1 < y2:
      result.append('🡽')
    else:
      result.append('🡾')
    result.append(np.round(rs[i],6))
  
  return '  '.join(str(i) for i in result[:-1])



from itertools import cycle

def argand_gauss(zs, colors='b'):
  """Creates complex plane and shows complex numbers as vectors (complexors)
  ref: https://github.com/osnove/other/blob/master/complex_plane.py"""
  fig, ax = plt.subplots(figsize=(5,5))
  ax.spines['left'].set_position('center')
  ax.spines['bottom'].set_position('center')
  ax.spines['right'].set_color('none')
  ax.spines['top'].set_color('none')

  w = max(np.abs(zs))
  plt.xlim(-w, w)
  plt.ylim(-w, w)
  plt.arrow(0, -w, 0, 1.95*w, head_width=w/20, head_length=w/20, fc='k', ec='k')
  plt.arrow(-w, 0, 1.95*w, 0, head_width=w/20, head_length=w/20, fc='k', ec='k')

  for z,c in zip(zs, cycle(colors)):
    x = z.real - abs(w)/20*np.cos(np.angle(z))
    y = z.imag - abs(w)/20*np.sin(np.angle(z))
    plt.arrow(0, 0, x, y, head_width=w/20, head_length=w/20, fc=c, ec=c)

  plt.show()
  
  
  
from math import floor

def stemplot(stem_data, scale):
  """ https://www.rosettacode.org/wiki/Stem-and-leaf_plot#Python """
  d = []
  for data in sorted(stem_data):
    stm, lf = divmod(int(floor(data)), scale)
    d.append( (int(stm), int(lf)) )
  stems, leafs = list(zip(*d))
  stemwidth = max(len(str(x)) for x in stems)
  leafwidth = max(len(str(x)) for x in leafs)
  laststem, out = min(stems) - 1, []
  for s,l in d:
    while laststem < s:
      laststem += 1
      out.append('\n%*i |' % ( stemwidth, laststem))
    out.append(' %0*i' % (leafwidth, l))
  out.append('\n\nLegenda:\n X | Y  =>  %i*X+Y\n' % scale)
  return ''.join(out)  