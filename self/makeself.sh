#!/bin/bash

rm -Rf self
mkdir self
mkdir self/rootfs
cp ../abc.sh self/rootfs/AppRun

# To be expanded upon

../abc.sh self self.app
rm -Rf self