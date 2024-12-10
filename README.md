# IcePak Creater

This is a shell script that creates a self extracting archive that sandboxes and runs an app. The benefit of this over AppImages is that you don't have to do intrusive binary patching to get the application to function correctly. This works by overlaying the root directory `/` underneath the rootfs for the app, making the app think it is normally installed. IcePaks follow the **one file = one app** principle very strongly.

## Usage

```sh
./abc.sh directory output_file
```

The directory will be the build directory that must include the following files/directories

```
directory
├── rootfs
│   └── AppRun
├── icon
├── icon
└── app.desktop
```

Pretty basic. `AppRun` is the file that will be executed when the bundle is run. It can be any file that can be  `./`ed (e.g. shell script with a shebang, binary executable, symlink, etc.). `icon` is the icon for the bundle which can be a(n) `svg`, `png`, or `jpg` file. Do not include the file extension in the name however. The name must be exactly `icon` or it won't get recognized. `app.desktop` is a regular desktop file, although the `Exec` field does not need to be filled out. For now `Name` is the only mandatory field. Just like with `icon` the filename is important for it to get recognized.
