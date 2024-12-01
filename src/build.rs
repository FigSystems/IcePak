use std::fs;

use crate::config;
use crate::config::Config;
use crate::utils;

pub fn build_bundle(c: Config) -> Result<(), String> {
	let app_dir = temp_dir::TempDir::new().unwrap().path();

	// Generate app.desktop
	utils::touch(app_dir.join("app.desktop").to_str().unwrap())?;
	fs::write(app_dir.join("app.desktop").to_str().unwrap(), "[Desktop Entry]\n");

	Ok(())
}