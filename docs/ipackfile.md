# IPakFile documentation

The `your-app.ipakfile` file should follow this format
```
< distro
> out.ipak
& --ipak-some-arg

shell pkg update
shell pkg install cool-app
set-entrypoint cool-app
cp /usr/share/resource /usr/share/resource

```

The `< ` means "Use this distribution". The `> ` means "Set the output file to this". "&" specifies an arg to be passed to the ipak (only during build).
All other lines are directly passed on to the underlying IPak. Currently the commands supported are:
 - `shell ...` Run the following command inside the IPak.
 - `set-entrypoint <path>` Run the following command when the IPak is ran normally.
 - `cp source dest` The `source` argument is relative to the path outside the container, but the `dest` argument is for **inside** the container.