# App Bundle Creator

This is a shell script that creates a self extracting archive that sandboxes and runs an app. The benefit of this over AppImages is that you don't have to do intrusive binary patching to get the application to function correctly. This works by overlaying the root directory `/` underneath the rootfs for the app, making the app think it is normally installed. AppBundles follow the **one file = one app** principle very strongly.

## Usage

```sh
./abc.sh directory output_file
```

The directory will be the build directory that must include the following files/directories

```
directory
├── rootfs
│   └── AppRun
├── app.png
└── app.desktop
```

Pretty basic. `AppRun` is the file that will be executed when the bundle is run. It can be any file that can be  `./`ed (e.g. Shell script with a shebang, binary executable, symlink, etc.). `app.png` is the icon for the bundle. The name must be exactly `app.png` or it won't get recognized. `app.desktop` is a regular desktop file, although the `Exec` field does not need to be filled out. For now `Name` is the only mandatory field. Just like with `app.png` the name is important for it to get recognized.
