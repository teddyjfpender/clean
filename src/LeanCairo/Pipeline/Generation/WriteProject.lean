import LeanCairo.Pipeline.Generation.BuildPlan

namespace LeanCairo.Pipeline.Generation

private def writeFile (path : System.FilePath) (content : String) : IO Unit :=
  IO.FS.writeFile path content

def writeGeneratedProject (outDir : System.FilePath) (project : GeneratedProject) : IO Unit := do
  IO.FS.createDirAll outDir
  IO.FS.createDirAll (outDir / "src")
  IO.FS.createDirAll (outDir / "scripts")
  writeFile (outDir / "Scarb.toml") project.scarbToml
  writeFile (outDir / "src" / "lib.cairo") project.cairoLib
  writeFile (outDir / "README.md") project.readme
  writeFile (outDir / "scripts" / "find_contract_artifact.py") project.artifactHelperScript

end LeanCairo.Pipeline.Generation
