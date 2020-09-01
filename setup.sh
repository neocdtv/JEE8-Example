#!/bin/bash
grep JEE8_EXAMPLE_HOME ~/.bashrc &>/dev/null
if [ $? == 1 ] 
then
    echo 'Adding jee8_example configuration to .bashrc'
    echo '' >> $HOME/.bashrc
    echo "export JEE8_EXAMPLE_HOME='$(pwd)'" >> $HOME/.bashrc
    echo 'source $JEE8_EXAMPLE_HOME/functions.sh' >> $HOME/.bashrc
    echo 'setup_shortcuts' >> $HOME/.bashrc
    . $HOME/.bashrc
else
    echo 'jee8_example configuration already present in .bashrc'
fi