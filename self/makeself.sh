#!/bin/bash

mkdir -p self

cp ../dist-to-ipak.sh self/dist-to-ipak.sh
cp ../ipak-creater.sh self/ipak-creater.sh
cp ../build.sh self/build.sh

read -p "Make the changes and press enter to continue..."

cd ..
./build.sh --file self/self.ipakfile