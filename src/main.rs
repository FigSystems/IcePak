#![allow(dead_code)]

use clap::Parser;
use log::info;

mod config;
mod build;
mod utils;

#[derive(Parser)]
struct Args {
    #[clap(help = "Path to config file", required = true)]
    config: std::path::PathBuf,
}

fn main() {
    colog::init();

    let args = Args::parse();
    let config_path = args.config;

	let config = config::read_config(&config_path.to_string_lossy().to_string());
	info!("{}", toml::to_string(&config).unwrap());

	build::build_bundle(config).unwrap();
}
