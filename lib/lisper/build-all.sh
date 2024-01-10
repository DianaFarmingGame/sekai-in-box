#!/bin/sh

cd rustlib

cross build -r --target x86_64-unknown-linux-gnu
cross build -r --target x86_64-pc-windows-gnu
