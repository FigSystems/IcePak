use serde_derive::Deserialize;

#[derive(Deserialize)]
pub struct Config {
    pub name: String,
    pub version: String,
    pub icon: String,
    pub root: String,
}

#[derive(Deserialize)]
pub struct Build {
    pub build_script: String,
}
