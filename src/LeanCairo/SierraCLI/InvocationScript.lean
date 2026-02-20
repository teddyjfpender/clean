import LeanCairo.Pipeline.Sierra.EntryPoint
import LeanCairo.SierraCLI.Arguments

namespace LeanCairo.SierraCLI

private def escapeLeanStringLiteral (value : String) : String :=
  value.toList.foldl
    (fun acc c =>
      if c = '\\' then
        acc ++ "\\\\"
      else if c = '"' then
        acc ++ "\\\""
      else if c = '\n' then
        acc ++ "\\n"
      else
        acc.push c)
    ""

private def boolLiteral (value : Bool) : String :=
  if value then "true" else "false"

private def toTempSafeName (value : String) : String :=
  String.ofList <| value.toList.map (fun c => if c.isAlphanum then c else '_')

private def renderInvocationScript (options : CliOptions) : String :=
  let escapedOutDir := escapeLeanStringLiteral options.outDir
  let optimizeLiteral := boolLiteral options.optimize
  String.intercalate "\n"
    [
      "import LeanCairo.Pipeline.Sierra.EntryPoint",
      s!"import {options.moduleName}",
      "",
      "#eval",
      s!"  LeanCairo.Pipeline.Sierra.generateSierraProjectCheckedWithOptions {options.moduleName}.contract \"{escapedOutDir}\" {optimizeLiteral}",
      ""
    ]

private def runLake (args : Array String) (errorContext : String) : IO Unit := do
  let output <- IO.Process.output { cmd := "lake", args := args }
  if output.exitCode != 0 then
    throw
      <| IO.userError
          s!"{errorContext}\nstdout:\n{output.stdout}\nstderr:\n{output.stderr}"

def runGeneratorInvocation (options : CliOptions) : IO Unit := do
  runLake #["build", options.moduleName] s!"failed to build lake target '{options.moduleName}'"
  let tempName := s!".leancairo_generate_sierra_{toTempSafeName options.moduleName}.lean"
  let scriptPath := System.FilePath.mk tempName
  IO.FS.writeFile scriptPath (renderInvocationScript options)
  try
    runLake #["env", "lean", scriptPath.toString] "failed to execute generated Sierra module invocation script"
  finally
    try
      IO.FS.removeFile scriptPath
    catch _ =>
      pure ()

end LeanCairo.SierraCLI
