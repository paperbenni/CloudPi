#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/paperbenni/bash/master/import.sh)

pb cloudpie/cloudpie.sh
pb proton/proton.sh

function checkscript() {
    #statements
    if ! dialog --version >/dev/null; then
        echo "dialog must be installed in order for this to work"
        exit
    fi

    if ! curl cht.sh &>/dev/null; then
        echo "you need internet to do this"
        exit 1
    fi
}

checkscript

function mkcd() {
    if ! [ -e "$1" ]; then
        mkdir "$1"
    fi
    cd "$1"
}

function repoload() {
    # $1 is the link
    # $2 is the repo file name
    # $3 is the system name
    # $4 is the file extension
    rm "$2".txt
    echo "updating $3 repos"
    curl https://the-eye.eu/public/rom/$1/ >"$2".tmp

    #decodes spaces and other characters from html links
    urldecode() {
        : "${*//+/ }"
        echo -e "${_//%/\\x}"
    }

    getlink() {
        NOPREFIX=${1#*\<a href=\"}
        NOSUFFIX=${NOPREFIX%\">*\</a\>*}
        echo "$NOSUFFIX"
    }

    while read p; do
        # download links are <a> objects
        if ! echo "$p" | grep -q '<a href="'; then
            continue
        fi

        # filter out links like the discord of contact info
        if echo "$p" | grep -q 'https://'; then
            continue
        fi
        urldecode $(getlink "$p") >>"$2".txt
    done <"$2".tmp

    rm "$2".tmp

    # add the link prefix as the last line
    echo "https://the-eye.eu/public/rom/$1/" >>"$2".txt
    sleep 1

}

function romupdate() {
    if ! curl cht.sh &>/dev/null; then
        echo "no internet"
        exit
    fi
    mkdir -p ~/cloudpie/repos
    pushd ~/cloudpie/repos

    repoload 'Nintendo%2064/Roms' n64 "Nintendo 64" z64
    repoload 'SNES' snes "Super Nintendo Entertainment System" zip
    repoload 'Playstation/Games/NTSC' psx "Play Station 1" zip
    repoload 'Nintendo%20Gameboy%20Advance' gba "Game Boy Advance" zip
    repoload 'Nintendo%20DS' ds "Nintendo DS" 7z
    popd
}

function unpack() {
    echo "unpacking $1"
    if ! [ -e "$1" ]; then
        echo "file not found"
        exit 1
    fi
    FILEFORMAT=${1##*.}
    case "$FILEFORMAT" in
    zip)
        unzip -o "$1"
        ;;
    7z)
        7za x ./"$1"
        ;;
    rar)
        unrar x "$1"
        ;;
    *)
        DONTREMOVE=1
        ;;
    esac
    if [ -z "$DONTREMOVE" ]; then
        rm "$1"
    fi
}

#special commands that are not games
if ! [ -z "$1" ]; then
    case "$1" in
    update)
        romupdate
        ;;

    version)
        echo "veeery early beta"
        ;;
    help)
        curl https://raw.githubusercontent.com/paperbenni/CloudPie/master/help.txt
        ;;
    *)
        EXITTHIS=1
        ;;
    esac
    if [ -z "$EXITTHIS" ]; then
        exit 0
    else
        echo "installing game"
    fi
fi

if ! [ -e ~/cloudpie/repos/n64.txt ]; then
    romupdate
fi

cd ~/cloudpie

echo "for what console would you like your game?"
PS3="Select platform: "

console=$( ~/cloudpie/path/fzf < platforms.txt)
zerocheck "$console"

pushd repos
LINK=$(tail -1 < $console.txt)

game=$(~/cloudpie/path/fzf < "$console".txt)
zerocheck "$game"

popd

echo "downloading $game"

mkdir roms
pushd "roms"
mkcd "$console"
GAMENAME=${game%.*}

if ls ./"$GAMENAME".* 1>/dev/null 2>&1; then
    echo "game $GAMENAME already exists"
else
    echo "activating vpn"
    proton
    sleep 2
    wget "$LINK$game" -q --show-progress
    sudo pvpn -d
    unpack "$game"
fi

popd

echo "enjoy the game!"
sleep 3
