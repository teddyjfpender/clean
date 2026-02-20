import Lake
open Lake DSL

package «leancairo-mvp» where
  srcDir := "src"

lean_lib LeanCairo where

lean_lib Examples where

lean_lib MyLeanContract where

lean_lib MyLeanContractCSEBench where

lean_lib MyLeanFixedPointBench where

lean_lib MyLeanSierraSubset where

lean_lib MyLeanSierraSubsetUnsupportedU128Arith where

lean_lib MyLeanSierraSubsetUnsupportedU256Sig where

lean_lib MyLeanSierraScalar where

lean_lib MyLeanSierraU128RangeChecked where

@[default_target]
lean_exe «leancairo-gen» where
  root := `LeanCairo.CLI.Main

lean_exe «leancairo-sierra-gen» where
  root := `LeanCairo.SierraCLI.Main
