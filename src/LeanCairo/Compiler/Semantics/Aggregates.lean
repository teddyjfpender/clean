namespace LeanCairo.Compiler.Semantics

abbrev Tuple2Value := Int × Int

def tuple2Construct (fst snd : Int) : Tuple2Value :=
  (fst, snd)

def tuple2First (value : Tuple2Value) : Int :=
  value.fst

def tuple2Second (value : Tuple2Value) : Int :=
  value.snd

theorem tuple2_roundtrip_first (fst snd : Int) :
    tuple2First (tuple2Construct fst snd) = fst := by
  rfl

theorem tuple2_roundtrip_second (fst snd : Int) :
    tuple2Second (tuple2Construct fst snd) = snd := by
  rfl

structure StructValue where
  typeName : String
  fields : List Int
  deriving Repr, DecidableEq

def structConstruct (typeName : String) (fields : List Int) : StructValue :=
  { typeName := typeName, fields := fields }

def structDestruct (value : StructValue) : String × List Int :=
  (value.typeName, value.fields)

theorem struct_roundtrip (typeName : String) (fields : List Int) :
    structDestruct (structConstruct typeName fields) = (typeName, fields) := by
  rfl

structure EnumValue where
  typeName : String
  variant : String
  payload : List Int
  deriving Repr, DecidableEq

def enumConstruct (typeName variant : String) (payload : List Int) : EnumValue :=
  { typeName := typeName, variant := variant, payload := payload }

def enumDestruct (value : EnumValue) : String × String × List Int :=
  (value.typeName, value.variant, value.payload)

theorem enum_roundtrip (typeName variant : String) (payload : List Int) :
    enumDestruct (enumConstruct typeName variant payload) = (typeName, variant, payload) := by
  rfl

abbrev NullableValue (α : Type) := Option α
abbrev BoxedValue (α : Type) := α

def nullableWrap {α : Type} (value : α) : NullableValue α :=
  some value

def nullableUnwrap {α : Type} (value : NullableValue α) : Option α :=
  value

theorem nullable_wrap_unwrap {α : Type} (value : α) :
    nullableUnwrap (nullableWrap value) = some value := by
  rfl

def boxWrap {α : Type} (value : α) : BoxedValue α :=
  value

def boxUnwrap {α : Type} (value : BoxedValue α) : α :=
  value

theorem box_wrap_unwrap {α : Type} (value : α) :
    boxUnwrap (boxWrap value) = value := by
  rfl

structure NonZeroNat where
  value : Nat
  nonZero : value ≠ 0
  deriving Repr

def nonZeroCreate (value : Nat) : Option NonZeroNat :=
  if h : value = 0 then
    none
  else
    some { value := value, nonZero := h }

theorem nonZeroCreate_zero :
    nonZeroCreate 0 = none := by
  simp [nonZeroCreate]

theorem nonZeroCreate_nonzero (value : Nat) (h : value ≠ 0) :
    nonZeroCreate value = some { value := value, nonZero := h } := by
  simp [nonZeroCreate, h]

def arrayAppend {α : Type} (arr : List α) (value : α) : List α :=
  arr ++ [value]

def arrayLength {α : Type} (arr : List α) : Nat :=
  arr.length

theorem array_append_length {α : Type} (arr : List α) (value : α) :
    arrayLength (arrayAppend arr value) = arrayLength arr + 1 := by
  simp [arrayAppend, arrayLength]

structure SpanValue (α : Type) where
  backing : List α
  offset : Nat
  length : Nat
  bound : offset + length ≤ backing.length
  deriving Repr

def spanToList {α : Type} (span : SpanValue α) : List α :=
  (span.backing.drop span.offset).take span.length

theorem spanToList_length {α : Type} (span : SpanValue α) :
    (spanToList span).length ≤ span.length := by
  simp [spanToList, List.length_take]
  exact Nat.min_le_left span.length (span.backing.length - span.offset)

abbrev DictValue (κ υ : Type) := List (κ × υ)

def dictInsert {κ υ : Type} (dict : DictValue κ υ) (key : κ) (value : υ) : DictValue κ υ :=
  (key, value) :: dict

theorem dictInsert_preserves_value_type {κ υ : Type} (dict : DictValue κ υ) (key : κ) (value : υ) :
    ∃ inserted : DictValue κ υ, inserted = dictInsert dict key value := by
  exact ⟨dictInsert dict key value, rfl⟩

end LeanCairo.Compiler.Semantics
