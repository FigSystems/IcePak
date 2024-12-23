# IcePak Creater

This is a shell script that creates a self extracting archive that sandboxes and runs an app. The benefit of this over AppImages is that you don't have to do intrusive binary patching to get the application to function correctly. This works by having a custom root directory for each application, removing compatability issues.

## Usage

```sh
./ipak-creater.sh directory output_file
```

The directory will be the build directory that must include the following files/directories

```
directory
├── rootfs
│   └── AppRun
├── icon
└── app.desktop
```

Pretty basic. `AppRun` is the file that will be executed when the bundle is run. It can be any file that can be  `./`ed (e.g. shell script with a shebang, binary executable, symlink, etc.). `icon` is the icon for the bundle which can be a(n) `svg`, `png`, or `jpg` file. Do not include the file extension in the name however. The name must be exactly `icon` or it won't get recognized. `app.desktop` is a regular desktop file, although the `Exec` field does not need to be filled out. For now `Name` is the only mandatory field. Just like with `icon` the filename is important for it to get recognized.

Most of the time, you will never need to manually create an IPak. The build-ipak script will
fetch distribution IPaks which can then be modified by adding packages, files, etc.