import Lake
open Lake DSL

package «leancairo-mvp» where
  srcDir := "src"

lean_lib LeanCairo where

lean_lib Examples where

lean_lib MyLeanContract where

lean_lib MyLeanContractCSEBench where

@[default_target]
lean_exe «leancairo-gen» where
  root := `LeanCairo.CLI.Main
