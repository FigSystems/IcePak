use serde_derive::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
pub struct Config {
    pub name: String,
    pub version: String,
    pub icon: String,
	pub cmd: String,
	pub categories: String,
	pub terminal: Option<bool>,
	pub build: Build,
	pub run: Run
}

#[derive(Serialize, Deserialize)]
pub struct Build {
	pub root: String,
	pub distro: String,
    pub build_script: String,
	pub arch: String,
}

#[derive(Serialize, Deserialize)]
pub struct Run {
	pub custom_root: Option<bool>
}

pub fn read_config(path: &String) -> Config {
	let config = std::fs::read_to_string(&path).unwrap();
	let config: Config = toml::from_str(&config).unwrap();

	config
}
