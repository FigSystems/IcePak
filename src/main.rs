#![allow(dead_code)]

use clap::Parser;

mod config;

#[derive(Parser)]
struct Args {
    #[clap(help = "Path to config file", required = true)]
    config: std::path::PathBuf,
}

fn main() {
    colog::init();

    let args = Args::parse();
    let config_path = args.config;
}
