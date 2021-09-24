#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "${SCRIPT_DIR}/.." &>/dev/null

echo "Publishing changes from the Escoria demo game to the individual plugins"
echo

if [ ! -e "escoria-demo-game" ] || [ ! -e "escoria-core" ] || [ ! -e "escoria-ui-9verbs" ] || [ ! -e "escoria-ui-simplemouse" ] || [ ! -e "escoria-game-template" ]
then
    echo "This script requires the following directories:"
    echo "* escoria-demo-game"
    echo "* escoria-core"
    echo "* escoria-ui-9verbs"
    echo "* escoria-ui-simplemouse"
    echo "* escoria-game-template"
    echo
    echo "One or more directories were not found. Please check out the corresponding repositories."
    exit 1 
fi

git version &>/dev/null || ( echo "Did not find the git executable. Please install git." && exit 1 )
rsync --version &>/dev/null || ( echo "Did not find the rsync executable. Please install rsync." && exit 1 )

echo "Syncing source files"
echo "===================="

echo "Syncing escoria-core addon..."
if ! OUTPUT=$(rsync -av --del --exclude=plugin.cfg escoria-demo-game/addons/escoria-core/ escoria-core/addons/escoria-core/ 2>&1)
then
    echo "Error syncing escoria-core:"
    echo
    echo $OUTPUT
    exit 1
fi

echo "Syncing escoria-ui-9verbs addon..."
if ! OUTPUT=$(rsync -av --del --exclude=plugin.cfg escoria-demo-game/addons/escoria-ui-9verbs/ escoria-ui-9verbs/addons/escoria-ui-9verbs/ 2>&1)
then
    echo "Error syncing escoria-ui-9verbs:"
    echo
    echo $OUTPUT
    exit 1
fi

echo "Syncing escoria-ui-simplemouse addon..."
if ! OUTPUT=$(rsync -av --del --exclude=plugin.cfg escoria-demo-game/addons/escoria-ui-simplemouse/ escoria-ui-simplemouse/addons/escoria-ui-simplemouse/ 2>&1)
then
    echo "Error syncing escoria-ui-simplemouse:"
    echo
    echo $OUTPUT
    exit 1
fi

echo "Syncing escoria game template..."
if ! OUTPUT=$(rsync -av --del escoria-demo-game/addons/escoria-core/ escoria-game-template/addons/escoria-core/ >&1)
then
    echo "Error syncing escoria game template"
    echo
    echo $OUTPUT
    exit 1
fi

