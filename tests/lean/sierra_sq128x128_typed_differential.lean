import LeanCairo.Compiler.Semantics.Eval
import LeanCairo.Core.Domain.Ty

open LeanCairo.Compiler.Semantics
open LeanCairo.Compiler.IR
open LeanCairo.Core.Domain

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

private def runExpr (ctx : EvalContext) (expr : IRExpr ty) :
    IO (Ty.denote ty) := do
  let state : SemanticState := { context := ctx, resources := {}, failure := none }
  match evalExprStateStrict state expr with
  | .ok (value, _) => pure value
  | .error err => throw <| IO.userError s!"unexpected strict evaluation error: {err}"

private def normalizeU128 (value : Nat) : Nat :=
  IntegerDomains.normalizeUnsigned 128 value

private def normalizeU64 (value : Nat) : Nat :=
  IntegerDomains.normalizeUnsigned 64 value

private def normalizeU32 (value : Nat) : Nat :=
  IntegerDomains.normalizeUnsigned 32 value

private def normalizeU16 (value : Nat) : Nat :=
  IntegerDomains.normalizeUnsigned 16 value

private def refAdd (lhs rhs : Nat) : Nat :=
  normalizeU128 (normalizeU128 lhs + normalizeU128 rhs)

private def refSub (lhs rhs : Nat) : Nat :=
  normalizeU128 (normalizeU128 lhs + IntegerDomains.pow2 128 - normalizeU128 rhs)

private def refMul (lhs rhs : Nat) : Nat :=
  normalizeU128 (normalizeU128 lhs * normalizeU128 rhs)

private def refAffine (a b c d e : Nat) : Nat :=
  let sum := refAdd a b
  let delta := refSub c d
  let mul := refMul sum delta
  refAdd mul e

private def refAddU64 (lhs rhs : Nat) : Nat :=
  normalizeU64 (normalizeU64 lhs + normalizeU64 rhs)

private def refSubU64 (lhs rhs : Nat) : Nat :=
  normalizeU64 (normalizeU64 lhs + IntegerDomains.pow2 64 - normalizeU64 rhs)

private def refMulU64 (lhs rhs : Nat) : Nat :=
  normalizeU64 (normalizeU64 lhs * normalizeU64 rhs)

private def refAffineU64 (a b c d e : Nat) : Nat :=
  let sum := refAddU64 a b
  let delta := refSubU64 c d
  let mul := refMulU64 sum delta
  refAddU64 mul e

private def refAddU32 (lhs rhs : Nat) : Nat :=
  normalizeU32 (normalizeU32 lhs + normalizeU32 rhs)

private def refSubU32 (lhs rhs : Nat) : Nat :=
  normalizeU32 (normalizeU32 lhs + IntegerDomains.pow2 32 - normalizeU32 rhs)

private def refMulU32 (lhs rhs : Nat) : Nat :=
  normalizeU32 (normalizeU32 lhs * normalizeU32 rhs)

private def refAffineU32 (a b c d e : Nat) : Nat :=
  let sum := refAddU32 a b
  let delta := refSubU32 c d
  let mul := refMulU32 sum delta
  refAddU32 mul e

private def refAddU16 (lhs rhs : Nat) : Nat :=
  normalizeU16 (normalizeU16 lhs + normalizeU16 rhs)

private def refSubU16 (lhs rhs : Nat) : Nat :=
  normalizeU16 (normalizeU16 lhs + IntegerDomains.pow2 16 - normalizeU16 rhs)

private def refMulU16 (lhs rhs : Nat) : Nat :=
  normalizeU16 (normalizeU16 lhs * normalizeU16 rhs)

private def refAffineU16 (a b c d e : Nat) : Nat :=
  let sum := refAddU16 a b
  let delta := refSubU16 c d
  let mul := refMulU16 sum delta
  refAddU16 mul e

private def typedAddExpr : IRExpr .u128 :=
  .addInt .u128 (.var (ty := .u128) "lhs") (.var (ty := .u128) "rhs")

private def typedSubExpr : IRExpr .u128 :=
  .subInt .u128 (.var (ty := .u128) "lhs") (.var (ty := .u128) "rhs")

private def typedMulExpr : IRExpr .u128 :=
  .mulInt .u128 (.var (ty := .u128) "lhs") (.var (ty := .u128) "rhs")

private def legacyAddExpr : IRExpr .u128 :=
  .addU128 (.var (ty := .u128) "lhs") (.var (ty := .u128) "rhs")

private def legacySubExpr : IRExpr .u128 :=
  .subU128 (.var (ty := .u128) "lhs") (.var (ty := .u128) "rhs")

private def legacyMulExpr : IRExpr .u128 :=
  .mulU128 (.var (ty := .u128) "lhs") (.var (ty := .u128) "rhs")

private def typedAffineExpr : IRExpr .u128 :=
  .letE
    "sum_ab"
    .u128
    (.addInt .u128 (.var (ty := .u128) "a") (.var (ty := .u128) "b"))
    (.letE
      "delta_cd"
      .u128
      (.subInt .u128 (.var (ty := .u128) "c") (.var (ty := .u128) "d"))
      (.letE
        "mul_term"
        .u128
        (.mulInt .u128 (.var (ty := .u128) "sum_ab") (.var (ty := .u128) "delta_cd"))
        (.addInt .u128 (.var (ty := .u128) "mul_term") (.var (ty := .u128) "e"))))

private def legacyAffineExpr : IRExpr .u128 :=
  .letE
    "sum_ab"
    .u128
    (.addU128 (.var (ty := .u128) "a") (.var (ty := .u128) "b"))
    (.letE
      "delta_cd"
      .u128
      (.subU128 (.var (ty := .u128) "c") (.var (ty := .u128) "d"))
      (.letE
        "mul_term"
        .u128
        (.mulU128 (.var (ty := .u128) "sum_ab") (.var (ty := .u128) "delta_cd"))
        (.addU128 (.var (ty := .u128) "mul_term") (.var (ty := .u128) "e"))))

private def typedAddExprU64 : IRExpr .u64 :=
  .addInt .u64 (.var (ty := .u64) "lhs") (.var (ty := .u64) "rhs")

private def typedSubExprU64 : IRExpr .u64 :=
  .subInt .u64 (.var (ty := .u64) "lhs") (.var (ty := .u64) "rhs")

private def typedMulExprU64 : IRExpr .u64 :=
  .mulInt .u64 (.var (ty := .u64) "lhs") (.var (ty := .u64) "rhs")

private def typedAffineExprU64 : IRExpr .u64 :=
  .letE
    "sum_ab"
    .u64
    (.addInt .u64 (.var (ty := .u64) "a") (.var (ty := .u64) "b"))
    (.letE
      "delta_cd"
      .u64
      (.subInt .u64 (.var (ty := .u64) "c") (.var (ty := .u64) "d"))
      (.letE
        "mul_term"
        .u64
        (.mulInt .u64 (.var (ty := .u64) "sum_ab") (.var (ty := .u64) "delta_cd"))
        (.addInt .u64 (.var (ty := .u64) "mul_term") (.var (ty := .u64) "e"))))

private def typedAddExprU32 : IRExpr .u32 :=
  .addInt .u32 (.var (ty := .u32) "lhs") (.var (ty := .u32) "rhs")

private def typedSubExprU32 : IRExpr .u32 :=
  .subInt .u32 (.var (ty := .u32) "lhs") (.var (ty := .u32) "rhs")

private def typedMulExprU32 : IRExpr .u32 :=
  .mulInt .u32 (.var (ty := .u32) "lhs") (.var (ty := .u32) "rhs")

private def typedAffineExprU32 : IRExpr .u32 :=
  .letE
    "sum_ab"
    .u32
    (.addInt .u32 (.var (ty := .u32) "a") (.var (ty := .u32) "b"))
    (.letE
      "delta_cd"
      .u32
      (.subInt .u32 (.var (ty := .u32) "c") (.var (ty := .u32) "d"))
      (.letE
        "mul_term"
        .u32
        (.mulInt .u32 (.var (ty := .u32) "sum_ab") (.var (ty := .u32) "delta_cd"))
        (.addInt .u32 (.var (ty := .u32) "mul_term") (.var (ty := .u32) "e"))))

private def typedAddExprU16 : IRExpr .u16 :=
  .addInt .u16 (.var (ty := .u16) "lhs") (.var (ty := .u16) "rhs")

private def typedSubExprU16 : IRExpr .u16 :=
  .subInt .u16 (.var (ty := .u16) "lhs") (.var (ty := .u16) "rhs")

private def typedMulExprU16 : IRExpr .u16 :=
  .mulInt .u16 (.var (ty := .u16) "lhs") (.var (ty := .u16) "rhs")

private def typedAffineExprU16 : IRExpr .u16 :=
  .letE
    "sum_ab"
    .u16
    (.addInt .u16 (.var (ty := .u16) "a") (.var (ty := .u16) "b"))
    (.letE
      "delta_cd"
      .u16
      (.subInt .u16 (.var (ty := .u16) "c") (.var (ty := .u16) "d"))
      (.letE
        "mul_term"
        .u16
        (.mulInt .u16 (.var (ty := .u16) "sum_ab") (.var (ty := .u16) "delta_cd"))
        (.addInt .u16 (.var (ty := .u16) "mul_term") (.var (ty := .u16) "e"))))

#eval do
  let maxU128 := IntegerDomains.pow2 128 - 1

  let binaryCases : List (Nat × Nat) :=
    [
      (0, 0),
      (1, 2),
      (maxU128, 1),
      (maxU128, maxU128),
      (maxU128 + 7, maxU128 + 11),
      (999999, 123456)
    ]

  binaryCases.forM (fun pair => do
    let (lhsRaw, rhsRaw) := pair
    let ctx : EvalContext :=
      {
        u128Vars := fun name =>
          if name = "lhs" then lhsRaw
          else if name = "rhs" then rhsRaw
          else 0
      }

    let addTyped <- runExpr ctx typedAddExpr
    let addLegacy <- runExpr ctx legacyAddExpr
    let addExpected := refAdd lhsRaw rhsRaw
    assertCondition (addTyped = addLegacy)
      s!"sq128 typed add/legacy mismatch for lhs={lhsRaw}, rhs={rhsRaw}"
    assertCondition (addTyped = addExpected)
      s!"sq128 typed add reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"

    let subTyped <- runExpr ctx typedSubExpr
    let subLegacy <- runExpr ctx legacySubExpr
    let subExpected := refSub lhsRaw rhsRaw
    assertCondition (subTyped = subLegacy)
      s!"sq128 typed sub/legacy mismatch for lhs={lhsRaw}, rhs={rhsRaw}"
    assertCondition (subTyped = subExpected)
      s!"sq128 typed sub reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"

    let mulTyped <- runExpr ctx typedMulExpr
    let mulLegacy <- runExpr ctx legacyMulExpr
    let mulExpected := refMul lhsRaw rhsRaw
    assertCondition (mulTyped = mulLegacy)
      s!"sq128 typed mul/legacy mismatch for lhs={lhsRaw}, rhs={rhsRaw}"
    assertCondition (mulTyped = mulExpected)
      s!"sq128 typed mul reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"
  )

  let affineCases : List (Nat × Nat × Nat × Nat × Nat) :=
    [
      (1000, 2000, 700, 200, 9),
      (12345, 54321, 5000, 1234, 42),
      (maxU128, 1, maxU128, 7, 19),
      (maxU128 + 13, maxU128 + 21, maxU128 + 3, maxU128 + 9, maxU128 + 5)
    ]

  affineCases.forM (fun row => do
    let (aRaw, bRaw, cRaw, dRaw, eRaw) := row
    let ctx : EvalContext :=
      {
        u128Vars := fun name =>
          if name = "a" then aRaw
          else if name = "b" then bRaw
          else if name = "c" then cRaw
          else if name = "d" then dRaw
          else if name = "e" then eRaw
          else 0
      }

    let typedObserved <- runExpr ctx typedAffineExpr
    let legacyObserved <- runExpr ctx legacyAffineExpr
    let expected := refAffine aRaw bRaw cRaw dRaw eRaw
    assertCondition (typedObserved = legacyObserved)
      s!"sq128 typed affine/legacy mismatch for row={row}"
    assertCondition (typedObserved = expected)
      s!"sq128 typed affine reference mismatch for row={row}"
  )

  let maxU64 := IntegerDomains.pow2 64 - 1

  let binaryCasesU64 : List (Nat × Nat) :=
    [
      (0, 0),
      (1, 2),
      (maxU64, 1),
      (maxU64, maxU64),
      (maxU64 + 7, maxU64 + 11),
      (999999, 123456)
    ]

  binaryCasesU64.forM (fun pair => do
    let (lhsRaw, rhsRaw) := pair
    let ctx : EvalContext :=
      {
        u64Vars := fun name =>
          if name = "lhs" then lhsRaw
          else if name = "rhs" then rhsRaw
          else 0
      }

    let addTyped <- runExpr ctx typedAddExprU64
    let addExpected := refAddU64 lhsRaw rhsRaw
    assertCondition (addTyped = addExpected)
      s!"sq128 typed u64 add reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"

    let subTyped <- runExpr ctx typedSubExprU64
    let subExpected := refSubU64 lhsRaw rhsRaw
    assertCondition (subTyped = subExpected)
      s!"sq128 typed u64 sub reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"

    let mulTyped <- runExpr ctx typedMulExprU64
    let mulExpected := refMulU64 lhsRaw rhsRaw
    assertCondition (mulTyped = mulExpected)
      s!"sq128 typed u64 mul reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"
  )

  let affineCasesU64 : List (Nat × Nat × Nat × Nat × Nat) :=
    [
      (1000, 2000, 700, 200, 9),
      (12345, 54321, 5000, 1234, 42),
      (maxU64, 1, maxU64, 7, 19),
      (maxU64 + 13, maxU64 + 21, maxU64 + 3, maxU64 + 9, maxU64 + 5)
    ]

  affineCasesU64.forM (fun row => do
    let (aRaw, bRaw, cRaw, dRaw, eRaw) := row
    let ctx : EvalContext :=
      {
        u64Vars := fun name =>
          if name = "a" then aRaw
          else if name = "b" then bRaw
          else if name = "c" then cRaw
          else if name = "d" then dRaw
          else if name = "e" then eRaw
          else 0
      }

    let typedObserved <- runExpr ctx typedAffineExprU64
    let expected := refAffineU64 aRaw bRaw cRaw dRaw eRaw
    assertCondition (typedObserved = expected)
      s!"sq128 typed u64 affine reference mismatch for row={row}"
  )

  let maxU32 := IntegerDomains.pow2 32 - 1

  let binaryCasesU32 : List (Nat × Nat) :=
    [
      (0, 0),
      (1, 2),
      (maxU32, 1),
      (maxU32, maxU32),
      (maxU32 + 7, maxU32 + 11),
      (999999, 123456)
    ]

  binaryCasesU32.forM (fun pair => do
    let (lhsRaw, rhsRaw) := pair
    let ctx : EvalContext :=
      {
        u32Vars := fun name =>
          if name = "lhs" then lhsRaw
          else if name = "rhs" then rhsRaw
          else 0
      }

    let addTyped <- runExpr ctx typedAddExprU32
    let addExpected := refAddU32 lhsRaw rhsRaw
    assertCondition (addTyped = addExpected)
      s!"sq128 typed u32 add reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"

    let subTyped <- runExpr ctx typedSubExprU32
    let subExpected := refSubU32 lhsRaw rhsRaw
    assertCondition (subTyped = subExpected)
      s!"sq128 typed u32 sub reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"

    let mulTyped <- runExpr ctx typedMulExprU32
    let mulExpected := refMulU32 lhsRaw rhsRaw
    assertCondition (mulTyped = mulExpected)
      s!"sq128 typed u32 mul reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"
  )

  let affineCasesU32 : List (Nat × Nat × Nat × Nat × Nat) :=
    [
      (1000, 2000, 700, 200, 9),
      (12345, 54321, 5000, 1234, 42),
      (maxU32, 1, maxU32, 7, 19),
      (maxU32 + 13, maxU32 + 21, maxU32 + 3, maxU32 + 9, maxU32 + 5)
    ]

  affineCasesU32.forM (fun row => do
    let (aRaw, bRaw, cRaw, dRaw, eRaw) := row
    let ctx : EvalContext :=
      {
        u32Vars := fun name =>
          if name = "a" then aRaw
          else if name = "b" then bRaw
          else if name = "c" then cRaw
          else if name = "d" then dRaw
          else if name = "e" then eRaw
          else 0
      }

    let typedObserved <- runExpr ctx typedAffineExprU32
    let expected := refAffineU32 aRaw bRaw cRaw dRaw eRaw
    assertCondition (typedObserved = expected)
      s!"sq128 typed u32 affine reference mismatch for row={row}"
  )

  let maxU16 := IntegerDomains.pow2 16 - 1

  let binaryCasesU16 : List (Nat × Nat) :=
    [
      (0, 0),
      (1, 2),
      (maxU16, 1),
      (maxU16, maxU16),
      (maxU16 + 7, maxU16 + 11),
      (9999, 12345)
    ]

  binaryCasesU16.forM (fun pair => do
    let (lhsRaw, rhsRaw) := pair
    let ctx : EvalContext :=
      {
        u16Vars := fun name =>
          if name = "lhs" then lhsRaw
          else if name = "rhs" then rhsRaw
          else 0
      }

    let addTyped <- runExpr ctx typedAddExprU16
    let addExpected := refAddU16 lhsRaw rhsRaw
    assertCondition (addTyped = addExpected)
      s!"sq128 typed u16 add reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"

    let subTyped <- runExpr ctx typedSubExprU16
    let subExpected := refSubU16 lhsRaw rhsRaw
    assertCondition (subTyped = subExpected)
      s!"sq128 typed u16 sub reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"

    let mulTyped <- runExpr ctx typedMulExprU16
    let mulExpected := refMulU16 lhsRaw rhsRaw
    assertCondition (mulTyped = mulExpected)
      s!"sq128 typed u16 mul reference mismatch for lhs={lhsRaw}, rhs={rhsRaw}"
  )

  let affineCasesU16 : List (Nat × Nat × Nat × Nat × Nat) :=
    [
      (1000, 2000, 700, 200, 9),
      (12345, 54321, 5000, 1234, 42),
      (maxU16, 1, maxU16, 7, 19),
      (maxU16 + 13, maxU16 + 21, maxU16 + 3, maxU16 + 9, maxU16 + 5)
    ]

  affineCasesU16.forM (fun row => do
    let (aRaw, bRaw, cRaw, dRaw, eRaw) := row
    let ctx : EvalContext :=
      {
        u16Vars := fun name =>
          if name = "a" then aRaw
          else if name = "b" then bRaw
          else if name = "c" then cRaw
          else if name = "d" then dRaw
          else if name = "e" then eRaw
          else 0
      }

    let typedObserved <- runExpr ctx typedAffineExprU16
    let expected := refAffineU16 aRaw bRaw cRaw dRaw eRaw
    assertCondition (typedObserved = expected)
      s!"sq128 typed u16 affine reference mismatch for row={row}"
  )
