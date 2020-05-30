#!/bin/bash

if [[ $(python3 --version 2>&1) =~ 3\.8 ]]
    then
        echo "Python 3.8 is installed"
    else
        apt-get install -y python3.8
fi
