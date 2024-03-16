#!/bin/bash

if [ -z "$1" ]; then
    ansible-playbook main.yml -K
else
    ansible-playbook main.yml -K --tags ""$1""
fi