Lean -> Cairo (-> Sierra/CASM) MVP engineering specification

Status note (2026-02-20):

1. This file is the historical MVP baseline spec.
2. Active implementation planning and progress tracking now live in:
- `roadmap/README.md`
- `roadmap/executable-issues/INDEX.md`
3. This file remains in-repo for audit/history and backward traceability.

0. Document metadata
	•	Project name: LeanCairoMVP
	•	Status: engineering spec (implementation-ready)
	•	Primary outcome: generate a deployable Starknet contract (Cairo source) from a Lean-defined contract spec, then compile it to Sierra (and optionally CASM) using Scarb.  ￼
	•	Target audience: engineers implementing the generator + CI pipeline

⸻

1. Problem statement

We want a repeatable pipeline that lets developers:
	1.	define a small, pure subset of contract logic in Lean 4,
	2.	generate Cairo contract code,
	3.	compile it with Scarb into a Sierra contract class artifact (and optionally a CASM compiled class artifact), and
	4.	have automated checks that the generated ABI matches the Lean spec and the output compiles cleanly.  ￼

Sierra exists specifically as a safety layer between user code and execution/proving: it’s meant to ensure contract execution is provable and avoid “unprovable” programs.  ￼

⸻

2. Goals and success criteria

2.1 Goals (MVP)

G1 — Lean-defined contract DSL: Provide a Lean EDSL for a small subset of functions and expressions (no state, no syscalls).

G2 — Deterministic Cairo codegen: Generate Cairo contract source using the canonical Starknet pattern:
	•	#[starknet::interface] trait
	•	#[starknet::contract] module
	•	#[abi(embed_v0)] impl embedding the interface implementation into the ABI  ￼

G3 — Scarb compilation pipeline: Output a Scarb package that compiles via scarb build, producing:
	•	Sierra artifact: [target]_[contract].contract_class.json (default)  ￼
	•	Optional CASM artifact: [package]_[contract].compiled_contract_class.json when casm = true  ￼

G4 — ABI + compilation checks in CI: In CI, validate:
	•	The generated Scarb project compiles.
	•	The contract artifact ABI contains the expected function signatures.

2.2 Explicit MVP success criteria

You can run:

lake exe leancairo-gen --module MyLeanContract --out ./generated_contract
cd generated_contract
scarb build

…and end up with:
	•	target/dev/<something>.contract_class.json for the contract, matching Scarb’s contract target naming rules  ￼
	•	A machine-readable artifact index file <target>.starknet_artifacts.json that points to the generated artifacts  ￼
	•	CI passing on clean clone with only Lean + Scarb installed

⸻

3. Non-goals (MVP)

Out of scope for MVP:
	•	Storage/stateful contracts (no #[storage] fields other than an empty placeholder)
	•	Events, L1 handlers, syscalls, cross-contract calls
	•	Maps, arrays/spans, structs/enums beyond trivial scalars
	•	Re-entrancy modeling, access control, upgradeability
	•	Formal proof that codegen is semantics-preserving (we’ll leave a seam for it)
	•	Direct emission of Sierra IR (we’ll generate Cairo source and compile it)

⸻

4. External toolchain assumptions

4.1 Scarb + Starknet contract target
	•	We rely on Scarb’s starknet-contract target to compile contracts and emit artifacts.  ￼
	•	The generated Scarb.toml must include [[target.starknet-contract]] and a dependency on the starknet package with a version compatible with Scarb’s bundled Cairo version.  ￼

4.2 Sierra / CASM
	•	Sierra is the standard intermediate contract representation; CASM is the low-level assembly used for execution/proving.  ￼
	•	For local CASM output, Scarb can emit it by setting casm = true in the target config.  ￼
	•	Tooling note: Starkli can declare using Scarb’s .contract_class.json and will compile Sierra → CASM internally to compute required hashes.  ￼

4.3 Type semantics
	•	felt252 is computed modulo the Stark field prime P = 2^{251} + 17⋅2^{192} + 1. If we support arithmetic on felt252, Lean semantics must match modular arithmetic.  ￼
	•	u256 serialization/ABI expectations matter if/when we expose u256 in the ABI: it serializes as two felts (low 128 bits, high 128 bits).  ￼

⸻

5. Developer experience and workflow (MVP)

5.1 Lean authoring model

Developers write a Lean module that defines a ContractSpec value using the EDSL, e.g.:
	•	Contract name
	•	List of externally callable functions
	•	Each function has:
	•	name
	•	typed arguments
	•	typed return
	•	expression body

Important design choice (MVP):
	•	We do not attempt to “extract arbitrary Lean code.”
	•	Instead, the contract is defined as data (an AST) in Lean, so codegen is predictable.

5.2 CLI

Provide an executable:
	•	Command: lake exe leancairo-gen
	•	Inputs:
	•	--module <LeanModule>: module containing a def contract : ContractSpec
	•	--out <dir>: output directory for generated Scarb project
	•	--emit-casm (true|false) default false
	•	Outputs:
	•	Scarb package with Cairo sources + manifest

5.3 Build steps
	•	scarb build compiles contract and emits artifacts in target/dev.  ￼

⸻

6. System architecture

6.1 Components

A. Lean frontend (EDSL + validator)
	•	Defines:
	•	Cairo-like types
	•	expression AST
	•	function AST
	•	contract AST
	•	Provides:
	•	static validation (closed terms, no unsupported ops, etc.)
	•	optional interpreter for Lean-side testing (see §10)

B. Lean backend (Cairo code generator)
	•	Pretty prints:
	•	Cairo interface trait
	•	Cairo contract module wrapper
	•	Cairo impl block(s)
	•	helper imports

C. Scarb project generator
	•	Writes:
	•	Scarb.toml
	•	src/lib.cairo
	•	optional README.md
	•	Optionally writes snfoundry.toml + minimal tests later (post-MVP)

D. CI pipeline
	•	Builds Lean generator
	•	Generates Cairo project from an example contract
	•	Runs scarb build
	•	Parses artifact JSON and checks ABI surface

⸻

7. Lean EDSL specification

7.1 Supported types (MVP)

Define a Lean inductive Ty with a very small set:
	•	felt252
	•	u128
	•	u256
	•	bool

Notes:
	•	MVP can choose to avoid felt arithmetic entirely (only allow equality + pass-through) to reduce semantics risk; or support it but then implement modular semantics in Lean.  ￼

7.2 Supported expressions (MVP)

Expression forms (typed AST):
	•	Variables
	•	Literals:
	•	u128 literals
	•	bool literals
	•	felt252 literals (optional)
	•	Binary ops (type-directed):
	•	+, -, * for u128 and u256 (subject to Cairo availability)
	•	== for all supported scalar types
	•	comparisons <, <= for unsigned ints only (optional)
	•	if cond then a else b (same type on branches)
	•	Local bindings:
	•	let x = e1; e2

Explicitly disallowed (MVP):
	•	recursion
	•	loops
	•	dynamic memory structures
	•	pattern matching on enums/structs

7.3 Function model

FuncSpec:
	•	name : Ident
	•	args : List (Ident × Ty)
	•	ret  : Ty
	•	body : Expr ret (typed body)

7.4 Contract model

ContractSpec:
	•	contractName : Ident
	•	functions : List FuncSpec
	•	mutability : FuncSpec → (View|ExternalMutable) (MVP default: View only)

⸻

8. Cairo code generation specification

8.1 Output Cairo contract shape

Generate Cairo using the structure shown in Starknet’s HelloStarknet quickstart (interface trait + contract module + #[abi(embed_v0)] impl).  ￼

8.1.1 Interface trait
For contract Foo, generate:
	•	#[starknet::interface]
	•	pub trait IFoo<TContractState> { ... }

Each function is declared with a state parameter:
	•	For MVP view functions: self: @TContractState
	•	If later supporting state mutation: ref self: TContractState

Cairo distinguishes ref vs @ usage for contract state in external/view contexts.  ￼

8.1.2 Contract module
Generate:
	•	#[starknet::contract]
	•	mod Foo { ... }

Inside module:
	•	#[storage] struct Storage { } (empty for MVP; required boilerplate in many patterns)
	•	#[abi(embed_v0)] impl FooImpl of super::IFoo<ContractState> { ... }  ￼

The #[abi(embed_v0)] marker indicates functions are exposed as entry points / ABI-embedded.  ￼

8.2 Imports

MVP import policy:
	•	Only import from Cairo corelib / starknet core packages as needed.
	•	Keep imports minimal to avoid disallowed libfunc usage.

Implementation rule:
	•	If the generated AST uses type u256, import required u256 utilities (exact module paths can be pinned by compiler errors during implementation).

8.3 Name mangling rules

Lean identifiers → Cairo identifiers:
	•	Convert camelCase/PascalCase → snake_case for functions (or keep as-is but ensure valid Cairo identifiers).
	•	Escape/reserve keywords:
	•	If name collides with Cairo keywords (mod, trait, impl, etc.), append _.
	•	Deterministic ordering:
	•	Preserve function order from Lean spec.

8.4 Expression lowering rules

Implement a total function:
	•	emitExpr : Expr τ → CairoExprString

Constraints:
	•	Ensure parentheses to preserve precedence.
	•	Ensure all intermediate values have explicit types if Cairo inference is insufficient (MVP can over-annotate to keep compilation robust).

8.5 Mutability mapping (MVP)

All MVP functions are view (no state writes):
	•	Use self: @ContractState in impl function signatures.

⸻

9. Scarb project generation specification

9.1 Generated directory layout

Output directory generated_contract/:

generated_contract/
  Scarb.toml
  src/
    lib.cairo

Optional later:
	•	tests/ for snforge tests (post-MVP)

9.2 Scarb.toml requirements

At minimum:
	•	Package section
	•	Dependencies:
	•	starknet = ">=2.16.0" (or whatever floor you choose; version is coupled to Scarb’s Cairo version)  ￼
	•	Contract target:
	•	[[target.starknet-contract]]
	•	sierra = true (default)
	•	casm = <bool> controlled by --emit-casm

Scarb defines:
	•	Sierra artifact naming: [target]_[contract].contract_class.json
	•	CASM artifact naming (if enabled): [package]_[contract].compiled_contract_class.json  ￼

9.3 Artifact discovery

After build, also consume:
	•	[target].starknet_artifacts.json which lists built contracts and their artifact paths.  ￼

MVP requirement: generator provides a helper script or documented steps to locate the emitted .contract_class.json using this artifacts index (instead of hardcoding filenames).

9.4 Allowed libfunc validation

Scarb’s Starknet contract target runs allowed-libfunc validation by default and can be configured. MVP should aim to pass the default allowlist by keeping the generated code minimal and idiomatic.  ￼

⸻

10. Testing strategy (MVP)

10.1 Build-only tests (required)

T1 — Codegen determinism snapshot
	•	Given a fixed Lean contract spec, generated src/lib.cairo should match a checked-in golden file (exact string match).
	•	Run in CI.

T2 — Scarb build
	•	In CI: scarb build must succeed.
	•	This is the main “end-to-end health check.”  ￼

10.2 ABI surface tests (required)

T3 — ABI matches Lean signatures
	•	Parse the produced .contract_class.json
	•	Extract ABI function list
	•	Check:
	•	function names exist
	•	arg count and types match
	•	return types match

(Implementation detail: ABI schema is inside the contract class JSON; the MVP can treat it as JSON and check key fields.)

10.3 Semantics tests (optional but recommended)

Because MVP restricts to pure functions, you can add a Lean interpreter and cross-check against Cairo execution later. Two realistic options:

Option A: Cairo unit tests via Starknet Foundry
	•	Generate a tests/ file that calls the contract’s internal pure functions and asserts expected outputs.
	•	Requires dev-dependency on snforge_std.  ￼

Option B: Generate a Cairo “executable harness” package
	•	Separate Scarb package using executable target
	•	Run with scarb execute
	•	Note: executable targets typically require disabling gas tracking.  ￼

MVP can skip both and stick to build+ABI checks.

⸻

11. Sierra/CASM “benefit points” in the MVP

Even though we generate Cairo source, Sierra/CASM enter in practical ways:
	1.	Sierra is the deployment artifact produced by Scarb’s contract target and used for class declaration/deployment flows.  ￼
	2.	CASM output is optional locally; Scarb can emit it when casm = true.  ￼
	3.	For advanced workflows, you can compile Sierra → CASM using:
	•	cairo-lang-sierra-to-casm crate as a backend in Rust tooling  ￼
	•	or a version-bridging tool like Universal Sierra Compiler for “any ever-existing Sierra version → CASM” (useful when Sierra versions evolve).  ￼
	4.	Starkli can compile Sierra to CASM internally and requires a CASM hash for declaring, so you’re not forced to emit CASM yourself in MVP.  ￼

⸻

12. Security & correctness considerations (MVP)

12.1 Felt arithmetic semantics

If MVP supports felt252 arithmetic:
	•	Lean interpreter semantics must be modulo P (field arithmetic), not unbounded integers.  ￼

If you don’t want to commit to that yet:
	•	Restrict felt252 usage in MVP to:
	•	equality checks
	•	passing through inputs/outputs
	•	no + - * on felts

12.2 Integer overflow behavior
	•	For u128/u256, ensure the generated operations use Cairo’s integer ops (which are not the same as felt modular arithmetic).
	•	Keep the subset small and test compilation + basic behavior.

12.3 Avoid disallowed libfuncs
	•	Rely on Scarb’s default allowed-libfunc validation to catch accidental use of un-audited libfuncs.  ￼

⸻

13. Implementation plan and milestones

Milestone M0 — Repo scaffolding (1–2 days)
	•	Create Lean project (lake) with:
	•	LeanCairo/AST.lean
	•	LeanCairo/Codegen.lean
	•	LeanCairo/CLI.lean (executable)
	•	Add example contract spec in Examples/Hello.lean
	•	Add CI skeleton running Lean build

Milestone M1 — AST + validator (2–4 days)
	•	Implement Ty, typed Expr, FuncSpec, ContractSpec
	•	Validator checks:
	•	no unsupported ops
	•	no duplicate names
	•	closed expressions (all vars bound)

Milestone M2 — Cairo codegen backend (3–6 days)
	•	Implement pretty printer:
	•	interface trait generation
	•	contract module generation
	•	function body expression lowering
	•	Ensure generated structure matches the standard Starknet pattern.  ￼

Milestone M3 — Scarb project emitter (1–3 days)
	•	Write output files and manifest:
	•	[[target.starknet-contract]] with sierra=true, casm flag
	•	starknet dependency per Scarb docs  ￼

Milestone M4 — End-to-end CI checks (2–4 days)
	•	CI job:
	•	run generator
	•	scarb build
	•	parse ABI from target/dev/*.contract_class.json or from *.starknet_artifacts.json  ￼

Milestone M5 — Optional tests (future)
	•	Add generated Cairo tests (snforge) or executable harness

⸻

14. Deliverables checklist (MVP)
	•	leancairo-gen CLI executable
	•	Lean EDSL + validator
	•	Cairo contract codegen producing:
	•	interface trait
	•	contract module
	•	#[abi(embed_v0)] impl  ￼
	•	Scarb project generator
	•	Example Lean contract + generated Cairo output
	•	CI: codegen snapshot + scarb build + ABI checks

⸻

15. Post-MVP extensions (explicitly planned, not implemented)
	•	Storage + events
	•	Contract-to-contract calls
	•	Direct Sierra emission (Lean → Sierra), with Rust tooling for Sierra validation/compilation  ￼
	•	Proofs: semantics-preserving compilation from Lean EDSL to Cairo (and/or to Sierra)

⸻

If you want, I can also include an exact JSON schema target for the ABI validation step (what fields to read from .contract_class.json) and a canonical naming policy (how to map Lean namespaces/modules into Cairo module names) so different teams don’t diverge.
