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
App: Example
  EntryPoint: /usr/bin/example
  OutputDirectory: build/example
Recipe:
  - FetchSources:
      script: git clone --depth=1 https://github.com/example/example.git
  - Build:
      workdir: example/build
      script: |
        ../configure --INSTALL_PREFIX="/usr"
        make install INSTALL_DIR="../../AppDir/"
  - Libraries:
      type: libraries
      files: /usr/bin/example /usr/bin/example-resource
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

IcePak should make it very easy for a team of developers to have an **IcePak** option without the fear of excessive maintainence work or fear of things breaking. It should be trivial to offer `.deb`, `.rpm`, and `.ipak` all without significantly different build process for each. If the portable app community wants developers to make applications in their format there should be a very simple, well defined, process of getting started.