# Mutable Write Extension Design Note

Date: 2026-02-20
Status: Implemented extension

## 1. Scope

Extend the LeanCairo DSL/codegen from view-only entrypoints to include mutable Starknet entrypoints with storage writes.

## 2. Inputs/outputs

### Inputs

- `ContractSpec.storage`: declared storage fields (`name`, `type`)
- `FuncSpec.mutability`: either `view` or `externalMutable`
- `FuncSpec.writes`: typed write actions (`field`, `type`, `value-expression`)
- `Expr.storageRead`: typed storage read expression

### Outputs

Generated Cairo includes:

- storage struct with declared fields
- view and external entrypoints in ABI
- mutable function bodies containing `self.<field>.write(...)` statements

## 3. Invariants

- Storage field names are valid identifiers and unique.
- Storage reads target declared fields and use matching types.
- Storage writes target declared fields and use matching types.
- Only `externalMutable` functions may contain writes.
- Existing deterministic ordering properties remain unchanged.

## 4. Failure modes

Validation fails when:

- storage field name is invalid or duplicated
- storage read/write references unknown storage field
- storage read/write type mismatches field declaration
- a view function includes write actions

## 5. Compatibility

- Existing view-only specs remain valid.
- Existing CLI and workflow scripts remain unchanged.
- ABI checker already supports per-function `state_mutability`; fixture files now include `external` where relevant.
