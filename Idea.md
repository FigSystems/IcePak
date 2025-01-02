# Ideas for IcePak

> [!WARNING]
> It is not recomended that you view this file, as the information here is very volatile and (almost definitly) subject to change. If you decide to progress and read this document, take it with a grain of salt. This is not intended for consumer viewing!

AppImage patches the executable to make all instances of `/usr` point to `././`. Instead of IcePak doing it this way, we can just put the application in a (bubblewrapped) environment that has `/usr` pointing to our desired location. This way we can eliminate binary patching, while also ensuring that no other sub-applications will access an incorrect location.

Each application will be built and installed from source using instructions in a `.yaml` file.
 - Each recipe will be ran in a temporary directory, and is thus free to create any files/directories that it wants to.
 - The recipe can specify the path(s) to a source archive which will then be `wget`ed or `curl`ed.
 - A recipe can be made that extracts pre-built `.deb` packages and installs them in the app root, although this behaviour is discouraged.
 - All output should go to the directory `AppDir` which will be pre-created inside the temporary directory. This directory will be copied out and preserved. All other directories will be destroyed.

An example of the intended format is as follows. This is just a rough idea of the format and should not be followed as a reference for recipe developers. This is just for the IcePak developers to roughly follow this design.

```yaml
App:
  Name: Example
  OutputDirectory: build/example
Recipe:
  - CopyFiles:
	script: |
      cp $SRC/src src
      # There are multiple names for the source dir.
      cp $REPO_ROOT/example example
      # You can also just copy it all :)
      cp $SRC/* ./
  - Build:
    script: |
	  ./configure --prefix=/App
	  make -j $(nproc) install INSTALL_DIR="AppDir/"
  - Libraries:
    type: libraries
	files: /usr/bin/example /usr/bin/other-executable

Config:
  - entrypoint: /usr/bin/example
```

Each of the steps in the `recipe` section will be executed sequentally.
 - If the step contains a `workdir` key, the script will be executed in that directory,
  creating it if it does not already exist.
 - The script will be executed, line-by-line failing if an error is ecountered.

The `Libraries` section contains a list of files that will have their required libraries included.
The type field is used to distinguish between `standard` entries and other types, in this case `libraries`. The current types are (More to come in the future):
 - `standard`
 - `libraries`

In IcePak we should also attempt to provide absolute path support. `/usr` will be bind mounted inside the container giving the application the ability to reference its resources absolutely.
This helps solve the problem with AppImages that make it difficult to use like a traditional binary. An appimage needs to remember where it was executed from to access any resources, wheras with an IcePak, an application knows it will always be at `/usr` (Although, optionally, an application could have all it's data at `/App` for instance.)

IcePak should make it very easy for a team of developers to have an **IcePak** option without the fear of excessive maintainence work or fear of things breaking. It should be trivial to offer `.deb`, `.rpm`, and `.ipak` all without significantly different build process for each. If the portable app community wants developers to make applications in their format there should be a very simple, well defined, process for them getting started.

In an `AppDir` a config directory will be present under the name `.config/`. Files existing under here will be used like variables to hold config options. The list is as follows:
 - `entrypoint` Used to determine the entrypoint. Must be relative to `/`


The build script itself is run inside the build directory, usually inside `/tmp`. This may change in the future as I am not sure whether it is a better idea to build inside the repo root and make the application install to `$build_dir` or whether to build inside the build dir and make the project copy source files from `$src_dir`. Either is fine, but it was chosen to do it the way described above for now.

## Runtime

Inside each application's AppDir, any files and directories in that directory will be directely bind-mounted to `/$NAME` (e.g. `AppDir/usr` would be bind mounted to `/usr`). Most applications will opt to have their binaries installed under the `/usr` prefix, but theoretically you could put your applications files under `/App` too.

The config option `entrypoint` determines the file to be started upon application launch. In essence, the IcePak's starting point. If this config option is not set or the file is not found, then the runtime will use zenity to display an error message but if zenity is not installed then it will print an error to the terminal.

The runtime should just bubblewrap the entrypoint, with every directory in root bind-mounted, and then every directory in the app-root will be bind-mounted with the applications folders overiding the system ones. No libraries should be used from the base system unless if it is ABSOLUTELY GARANTEED to be in your target distros.

## Daemon

An area which is under active consideration is having a dedicated daemon to integrate compressed icepaks into the system and allow regular launching. This daemon would be run as root to take advantage of the kernel's squashfs mounting features. (squashfuse is kinda trash for anything serious)

A dedicated daemon does not invalidate the principal of *one file = one app*.