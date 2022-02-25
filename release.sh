#!/usr/bin/env bash

VERSION="$1"
if [ -z "${VERSION}" ]; then echo "VERSION is not set. Use ./release.sh 0.0.0 stage" >&2; exit 1; fi

STAGE="$2"
if [ -z "${STAGE}" ]; then STAGE="prod"; fi

MOD_NAME="LogExtender"
if [ "${STAGE}" == "test" ]; then MOD_NAME="${MOD_NAME}Test"; fi

RELEASE_NAME="${MOD_NAME}-${VERSION}"

rm -r release
mkdir release
touch release/checksum.txt

function make_release() {
    local dir_workshop="release/${RELEASE_NAME}"
    local dir="${dir_workshop}/Contents/mods/${MOD_NAME}"

    mkdir -p "${dir}"

    case $STAGE in
        test)
            cp workshop/test/workshop.txt "${dir_workshop}"
            cp workshop/test/mod.info "${dir}"
            ;;
        prod)
            cp workshop/workshop.txt "${dir_workshop}"
            cp workshop/mod.info "${dir}"
            ;;
        *)
            echo "incorrect stage" >&2
            exit 1
            ;;
    esac

    cp workshop/preview.png "${dir_workshop}/preview.png"
    cp workshop/poster.png "${dir}"
    cp src -r "${dir}/media"

    cp LICENSE "${dir}"
    cp README.md "${dir}"
    cp CHANGELOG.md "${dir}"

    cd "${dir_workshop}/Contents/mods/"
    tar -zcvf "../../../${RELEASE_NAME}.tar.gz" "${MOD_NAME}"
    zip -r "../../../${RELEASE_NAME}.zip" "${MOD_NAME}"

    cd ../../../ && {
        md5sum "${RELEASE_NAME}.tar.gz" >> checksum.txt;
        md5sum "${RELEASE_NAME}.zip" >> checksum.txt;
        cd ../;
    }
}

function install_release() {
    rm -r ~/Zomboid/Workshop/"${MOD_NAME}"

    cp -r  "release/${RELEASE_NAME}" ~/Zomboid/Workshop/"${MOD_NAME}"

    rm -r "release/${RELEASE_NAME}"
}

make_release && install_release
