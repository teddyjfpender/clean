import LeanCairo.SierraCLI.Arguments
import LeanCairo.SierraCLI.InvocationScript

open LeanCairo.SierraCLI

def main (args : List String) : IO UInt32 := do
  if args.contains "--help" then
    IO.println usage
    return 0
  match parseCliOptions args with
  | .error err =>
      IO.eprintln s!"error: {err}"
      IO.eprintln usage
      return 1
  | .ok options =>
      try
        runGeneratorInvocation options
        return 0
      catch ex =>
        IO.eprintln s!"error: {ex.toString}"
        return 1
