#![allow(dead_code)]

use log::info;

mod config;
mod build;
mod utils;

// #[derive(Parser)]
// struct Args {
//     #[clap(help = "Path to config file", required = true)]
//     config: std::path::PathBuf,
// }

fn main() {
    colog::init();

    // let args = Args::parse();
    let config_path: String = "config.toml".to_string();

	let config = config::read_config(&config_path);
	info!("{}", toml::to_string(&config).unwrap());

	build::build_bundle(config).unwrap();
}
