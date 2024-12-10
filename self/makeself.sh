#!/bin/bash

rm -Rf self
mkdir self
mkdir self/rootfs
cp ../ipak-creater.sh self/rootfs/AppRun

# To be expanded upon

../ipak-creater.sh self self.app
rm -Rf self