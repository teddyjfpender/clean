use std::fs;
use std::path::PathBuf;

use anyhow::{Context, Result};
use cairo_lang_sierra::extensions::core::{CoreLibfunc, CoreType};
use cairo_lang_sierra::program::{Program, VersionedProgram};
use cairo_lang_sierra::program_registry::ProgramRegistry;
use cairo_lang_sierra_to_casm::compiler::{compile, SierraToCasmConfig};
use cairo_lang_sierra_to_casm::metadata::calc_metadata_ap_change_only;
use cairo_lang_sierra_type_size::ProgramRegistryInfo;
use clap::{Parser, Subcommand};
use serde_json::json;

#[derive(Debug, Parser)]
#[command(name = "sierra_toolchain")]
#[command(about = "Validate and compile Sierra programs using pinned official cairo crates.")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Validate Sierra program structure and specialization against ProgramRegistry.
    Validate {
        /// Path to VersionedProgram JSON.
        #[arg(long)]
        input: PathBuf,
    },
    /// Compile Sierra JSON to textual CASM.
    Compile {
        /// Path to VersionedProgram JSON.
        #[arg(long)]
        input: PathBuf,
        /// Output path for CASM text.
        #[arg(long = "out-casm")]
        out_casm: PathBuf,
        /// Enable gas usage check in Sierra->CASM compiler.
        #[arg(long, default_value_t = false)]
        gas_check: bool,
    },
}

fn load_program(input: &PathBuf) -> Result<Program> {
    let raw = fs::read_to_string(input)
        .with_context(|| format!("failed reading Sierra JSON: {}", input.display()))?;
    let versioned: VersionedProgram =
        serde_json::from_str(&raw).context("failed parsing VersionedProgram JSON")?;
    let artifact = versioned
        .into_v1()
        .context("unsupported Sierra program version for pinned toolchain")?;
    Ok(artifact.program)
}

fn run_validate(input: &PathBuf) -> Result<()> {
    let program = load_program(input)?;
    let _registry = ProgramRegistry::<CoreType, CoreLibfunc>::new(&program)
        .context("ProgramRegistry validation failed")?;
    println!(
        "{}",
        json!({
            "validated": true,
            "type_declarations": program.type_declarations.len(),
            "libfunc_declarations": program.libfunc_declarations.len(),
            "statements": program.statements.len(),
            "functions": program.funcs.len(),
        })
    );
    Ok(())
}

fn run_compile(input: &PathBuf, out_casm: &PathBuf, gas_check: bool) -> Result<()> {
    let program = load_program(input)?;
    let program_info =
        ProgramRegistryInfo::new(&program).context("failed creating ProgramRegistryInfo")?;
    let metadata = calc_metadata_ap_change_only(&program, &program_info)
        .context("failed computing metadata (ap-change only)")?;
    let compiled = compile(
        &program,
        &program_info,
        &metadata,
        SierraToCasmConfig {
            gas_usage_check: gas_check,
            max_bytecode_size: usize::MAX,
        },
    )
    .context("Sierra->CASM compilation failed")?;
    if let Some(parent) = out_casm.parent() {
        fs::create_dir_all(parent).with_context(|| {
            format!(
                "failed creating CASM output directory: {}",
                parent.display()
            )
        })?;
    }
    fs::write(out_casm, format!("{compiled}\n"))
        .with_context(|| format!("failed writing CASM output: {}", out_casm.display()))?;
    println!(
        "{}",
        json!({
            "compiled": true,
            "out_casm": out_casm,
            "instructions": compiled.instructions.len(),
            "const_segments": compiled.consts_info.segments.len(),
            "gas_check": gas_check,
        })
    );
    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Command::Validate { input } => run_validate(&input),
        Command::Compile {
            input,
            out_casm,
            gas_check,
        } => run_compile(&input, &out_casm, gas_check),
    }
}
