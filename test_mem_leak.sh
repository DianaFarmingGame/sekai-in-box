#!/bin/sh

clear && ./test/export/test.x86_64 --verbose | grep 'Leaked instance'
