#!/bin/bash
set -e
cd modules
echo https://www.modulargrid.net/e/modules/view/{4000..5000}.xml | xargs -n 200 wget -c
