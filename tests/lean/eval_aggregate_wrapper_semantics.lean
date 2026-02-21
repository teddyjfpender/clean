import LeanCairo.Compiler.Semantics.Aggregates

open LeanCairo.Compiler.Semantics

private def assertCondition (ok : Bool) (message : String) : IO Unit := do
  if ok then
    pure ()
  else
    throw <| IO.userError message

#eval do
  -- Tuple constructor/destructor laws.
  let tupleValue := tuple2Construct 7 (-4)
  assertCondition (tuple2First tupleValue = 7) "tuple2 first projection should roundtrip constructor"
  assertCondition (tuple2Second tupleValue = -4) "tuple2 second projection should roundtrip constructor"

  -- Struct constructor/destructor laws.
  let structValue := structConstruct "Point" [3, 9]
  let structView := structDestruct structValue
  assertCondition (structView.fst = "Point") "struct roundtrip should preserve type name"
  assertCondition (structView.snd = [3, 9]) "struct roundtrip should preserve payload fields"

  -- Enum constructor/destructor laws.
  let enumValue := enumConstruct "Result" "ok" [42]
  let enumView := enumDestruct enumValue
  assertCondition (enumView.fst = "Result") "enum roundtrip should preserve type name"
  assertCondition (enumView.snd.fst = "ok") "enum roundtrip should preserve variant tag"
  assertCondition (enumView.snd.snd = [42]) "enum roundtrip should preserve variant payload"

  -- Wrapper semantics.
  assertCondition (nullableUnwrap (nullableWrap 12) = some 12) "nullable wrapper should preserve wrapped value"
  assertCondition (boxUnwrap (boxWrap 19) = 19) "box wrapper should preserve wrapped value"
  assertCondition (nonZeroCreate 0 = none) "nonZero wrapper must reject zero"
  match nonZeroCreate 3 with
  | some wrapped =>
      assertCondition (wrapped.value = 3) "nonZero wrapper should preserve non-zero payload"
  | none =>
      throw <| IO.userError "nonZero wrapper should accept non-zero payload"

  -- Collection invariants.
  let arr := arrayAppend [1, 2, 3] 4
  assertCondition (arrayLength arr = 4) "array append should increment length by one"
  let span : SpanValue Nat := { backing := [10, 11, 12, 13], offset := 1, length := 2, bound := by decide }
  assertCondition (spanToList span = [11, 12]) "span projection should preserve ordered typed elements"
  let dict := dictInsert ([] : DictValue String Nat) "k" 5
  assertCondition (dict = [("k", 5)]) "dict insert should preserve key/value typing and order"
