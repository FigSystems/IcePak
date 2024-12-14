# IPakFile documentation

The file should follow this format
```
< distro
> out.ipak

shell pkg update
shell pkg install cool-app
set-entrypoint /path/to/cool-app
cp /usr/bin/resource /usr/bin/resource
commit

```

The `< ` means "Use this distribution". The `> ` means "Set the output file to this".
All other lines are directly passed on to the underlying IPak. Currently the commands supported are:
 - `shell ...` Run the following command inside the IPak.
 - `set-entrypoint <path>` Run the following command when the IPak is ran normally.
 - `commit` Finalize all changes and make the IPak immutable.
 - `cp source dest` The `source` argument is relative to the path outside the container, but the `dest` argument is for **inside** the container.