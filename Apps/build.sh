#!/bin/bash

for f in *.ipakfile; do
	build-ipak "$f"
done