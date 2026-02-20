namespace LeanCairo.Pipeline.Generation

structure GeneratedProject where
  scarbToml : String
  cairoLib : String
  readme : String
  artifactHelperScript : String
  deriving Repr

end LeanCairo.Pipeline.Generation
