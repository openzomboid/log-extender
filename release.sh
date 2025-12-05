#!/usr/bin/env bash

# TODO: Add Makefile.

VERSION="$1"
if [ -z "${VERSION}" ]; then echo "VERSION is not set. Use ./release.sh 0.0.0 stage" >&2; exit 1; fi

STAGE="$2"
if [ -z "${STAGE}" ]; then STAGE="prod"; fi

MOD_NAME="LogExtender"
if [ "${STAGE}" == "test" ]; then MOD_NAME="${MOD_NAME}Test"; fi

RELEASE_NAME="${MOD_NAME}-${VERSION}"

RELEASE_DIR_WORKSHOP=".tmp/release/${RELEASE_NAME}"
RELEASE_DIR_MOD_HOME="${RELEASE_DIR_WORKSHOP}/Contents/mods/${MOD_NAME}"

rm -r .tmp/release
mkdir .tmp/release
touch .tmp/release/checksum.txt

function make_release() {
  local dir_workshop="${RELEASE_DIR_WORKSHOP}"
  local dir_mod_home="${RELEASE_DIR_MOD_HOME}"

    mkdir -p "${dir_mod_home}"

    case ${STAGE} in
      local|test|prod)
        cp workshop/${STAGE}/workshop.txt "${dir_workshop}"
        cp workshop/${STAGE}/mod.info "${dir_mod_home}"
        ;;
      *)
        echo "incorrect stage" >&2
        exit 1
        ;;
    esac

    cp workshop/preview.png "${dir_workshop}/preview.png"
    cp workshop/poster.png "${dir_mod_home}"
    cp src -r "${dir_mod_home}/media"

    cp LICENSE "${dir_mod_home}"
    cp README.md "${dir_mod_home}"
    cp CHANGELOG.md "${dir_mod_home}"
}

function compress_release() {
  local dir_workshop=${RELEASE_DIR_WORKSHOP}

  cd "${dir_workshop}/Contents/mods/" && {
    tar -zcvf "../../../${RELEASE_NAME}.tar.gz" "${MOD_NAME}"
    zip -r "../../../${RELEASE_NAME}.zip" "${MOD_NAME}"
  }

  cd ../../../ && {
    md5sum "${RELEASE_NAME}.tar.gz" >> checksum.txt;
    md5sum "${RELEASE_NAME}.zip" >> checksum.txt;
    cd ../../;
  }
}

function install_release() {
    rm -r ~/Zomboid/Workshop/"${MOD_NAME}"
    cp -r  .tmp/release/"${RELEASE_NAME}" ~/Zomboid/Workshop/"${MOD_NAME}"
    rm -r .tmp/release/"${RELEASE_NAME}"
}

make_release && compress_release && install_release
