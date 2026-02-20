namespace LeanCairo.Backend.Cairo

def indent (depth : Nat) : String :=
  String.ofList <| List.replicate (depth * 4) ' '

def indentLines (depth : Nat) (text : String) : String :=
  String.intercalate "\n" <| (text.splitOn "\n").map (fun line => indent depth ++ line)

end LeanCairo.Backend.Cairo
