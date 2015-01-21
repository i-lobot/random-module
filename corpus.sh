#!/bin/bash
set -e
ruby -r./module_logic.rb  -e "puts ModuleLogic.new.generateTitleCorpus " > corpus/title.txt
ebooks consume corpus/title.txt
