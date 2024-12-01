

pub fn cmd(command: &str) -> Result<(), String> {
	let output = std::process::Command::new("bash")
		.arg("-c")
		.arg(command)
		.output()
		.expect("failed to execute process");

	if !output.status.success() {
		return Err(String::from_utf8_lossy(&output.stderr).to_string());
	}

	Ok(())
}

pub fn mv(from: &String, to: &String) -> Result<(), String> {
	cmd(&format!("mv {} {}", from, to))
}

pub fn cp(from: &String, to: &String) -> Result<(), String> {
	cmd(&format!("cp -r {} {}", from, to))
}

pub fn touch(file: &String) -> Result<(), String> {
	cmd(&format!("touch {}", file))
}

pub fn rm(file: &String) -> Result<(), String> {
	cmd(&format!("rm -rf {}", file))
}