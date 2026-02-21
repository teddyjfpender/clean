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

lean_lib newton_u128 where
  srcDir := "../examples/Lean"

lean_lib scalar_core where
  srcDir := "../examples/Lean"

lean_lib u128_range_checked where
  srcDir := "../examples/Lean"

lean_lib fast_power_u128 where
  srcDir := "../examples/Lean"

lean_lib fast_power_u128_p63 where
  srcDir := "../examples/Lean"

lean_lib karatsuba_u128 where
  srcDir := "../examples/Lean"

lean_lib sq128x128_u128 where
  srcDir := "../examples/Lean"

lean_lib aggregate_payload_mix where
  srcDir := "../examples/Lean"

lean_lib circuit_gate_felt where
  srcDir := "../examples/Lean"

lean_lib crypto_round_felt where
  srcDir := "../examples/Lean"

@[default_target]
lean_exe «leancairo-gen» where
  root := `LeanCairo.CLI.Main

lean_exe «leancairo-sierra-gen» where
  root := `LeanCairo.SierraCLI.Main
