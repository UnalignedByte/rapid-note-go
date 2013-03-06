#!/bin/bash

find . -name "*.[hm]" -print0 | xargs -0 wc -l
