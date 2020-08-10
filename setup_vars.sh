#!/bin/bash
source <(grep -v '^ *#' ./.env | grep '[^ ] *=' | awk '{split($0,a,"="); print gensub(/\./, "_", "g", "export " a[1]) "=" a[2]}')
