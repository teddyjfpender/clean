import LeanCairo.Pipeline.Sierra.BuildPlan

namespace LeanCairo.Pipeline.Sierra

private def writeFile (path : System.FilePath) (content : String) : IO Unit :=
  IO.FS.writeFile path content

def writeGeneratedSierraProject
    (outDir : System.FilePath)
    (project : GeneratedSierraProject) : IO Unit := do
  IO.FS.createDirAll outDir
  IO.FS.createDirAll (outDir / "sierra")
  writeFile (outDir / "sierra" / "program.sierra.json") project.programJson
  writeFile (outDir / "README.md") project.readme

end LeanCairo.Pipeline.Sierra
