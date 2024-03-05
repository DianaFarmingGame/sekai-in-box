#!/bin/sh

clear && ./export/test.x86_64 --verbose | grep 'Leaked instance'
