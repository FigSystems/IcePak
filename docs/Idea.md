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
Name: Example
EntryPoint: /usr/bin/example
recipe:
	- FetchSources:
		script: git clone --depth=1 https://github.com/example/example.git
	- Build:
		workdir: example/build
		script: |
			../configure --INSTALL_PREFIX="/usr"
			make install INSTALL_DIR="../../AppDir/"
```
