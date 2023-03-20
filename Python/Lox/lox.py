# -*- coding: utf-8 -*-

import sys

from __version__ import __version__
from Scanner import Scanner

class Lox:
  
  def __init__(self):
    self.had_error = False  
    

  @staticmethod
  def main():  # pragma: no cover
    """
    Run from console. Accepts one argument as a file to execute,
    or no arguments for REPL mode.
    """
    if len(sys.argv) > 2:
      print(f"Usage: {sys.argv[0]} [script]")
      sys.exit(64)
    elif len(sys.argv) == 2:
      Lox().run_file(sys.argv[1])
    else:
      Lox().run_prompt()


  def run_file(self, file):
    """
    Execute Lox `file` as filename for the source input
    """
    with open(file) as f:
      lines = "\n".join(f.readlines())
    self.run(lines)
    

  def run_prompt(self):  # pragma: no cover
    """
    Run a REPL prompt. This prompt can be quit by pressing CTRL-C or CTRL-D
    """
    print(f"Welcome to Lox {__version__}")
    print("Press CTRL-C or CTRL-D to exit")

    while True:
      try:
        str_input = input("> ")
        if str_input and str_input[0] == chr(4):
          # Catch ctrl-D and raise as error
          raise EOFError
        self.run(str_input)
        self.had_error = False
      except (KeyboardInterrupt, EOFError):
        # Catch CTRL-C or CTRL-D (EOF)
        print("Adieu!")
        sys.exit(0)


  def error(self, line, message):
    print(line, ": ", message)
    self.had_error = True

        
  def run(self, source):
    scanner = Scanner(source, on_error=self.error)
    tokens = scanner.scan_tokens()
    
    for token in tokens:
      print(token)
      
    if self.had_error:
      sys.exit(65)
      