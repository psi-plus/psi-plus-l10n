#!/bin/sh

# Author:  Boris Pek <tehnick-8@mail.ru>
# License: GPLv2 or later
# Created: 2012-03-24
# Updated: 2016-04-06
# Version: N/A

export CUR_DIR="$(dirname $(realpath -s ${0}))"
export MAIN_DIR="${CUR_DIR}/.."
export PSIPLUS_DIR="${MAIN_DIR}/psi-plus-snapshots"

cd "${CUR_DIR}" || exit 1

case "${1}" in
"up")
    # Pulling changes from GitHub repo.

    git pull --all || exit 1

;;
"cm")
    # Creating correct git commit.

    git commit -a -m 'Translations were updated from Transifex.' || exit 1

;;
"tag")
    # Creating correct git tag.

    cd "${PSIPLUS_DIR}" || exit 1
    CUR_TAG="$(git tag -l  | sort -r -V | head -n1)"

    cd "${CUR_DIR}" || exit 1
    echo "git tag \"${CUR_TAG}\""
    git tag "${CUR_TAG}"

    echo ;
    echo "Last tags:"
    git tag | sort -V | tail -n 10

;;
"push")
    # Pushing changes into GitHub repo.

    git push || exit 1
    git push --tags || exit 1

;;
"make")
    # Making precompiled localization files.

    rm translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo translations/*.ts >> translations.pro

    lrelease ./translations.pro

    mkdir -p out
    mv translations/*.qm out/ || exit 1

;;
"install")
    # Installing precompiled localization files into default directory.

    if [ ${USER} != "root" ]; then
        echo "You are not a root now!"
        exit 1
    fi

    mkdir -p /usr/share/psi-plus/translations/
    cp out/*.qm /usr/share/psi-plus/translations/ || exit 1

;;
"tarball")
    # Generating tarball with precompiled localization files.

    CUR_TAG="$(git tag -l  | sort -r -V | head -n1)"

    rm -rf psi-plus-translations-*
    mkdir psi-plus-translations-${CUR_TAG} || exit 1
    cp out/*.qm psi-plus-translations-${CUR_TAG} || exit 1

    tar -cJf psi-plus-translations-${CUR_TAG}.tar.xz psi-plus-translations-${CUR_TAG} || exit 1
    echo "Tarball with precompiled translation files is ready for upload:"
    [ ! -z "$(which realpath)" ] && echo "$(realpath ${CUR_DIR}/psi-plus-translations-${CUR_TAG}.tar.xz)"
    echo "https://sourceforge.net/projects/psiplus/files/Translations/"

;;
"tr")
    # Pulling changes from Transifex.

    # Test Internet connection:
    host transifex.com > /dev/null || exit 1

    git status || exit 1

    LANG_DIR="${CUR_DIR}/translations"

    cd "${MAIN_DIR}/psi-plus-l10n_transifex" || exit 1
    tx pull -a -s || exit 1

    cd "translations/psi-plus.full/" || exit 1
    cp *.ts "${LANG_DIR}/"

    cd "${CUR_DIR}" || exit 1
    git status || exit 1

;;
"tr_up")
    # Full update of localization files.

    git status || exit 1

    if [ -d "${PSIPLUS_DIR}" ]; then
        echo "Updating ${PSIPLUS_DIR}"
        cd "${PSIPLUS_DIR}"
        git pull --all || exit 1
        echo;
    else
        echo "Creating ${PSIPLUS_DIR}"
        cd "${MAIN_DIR}"
        git clone https://github.com/psi-plus/psi-plus-snapshots.git || exit 1
        echo;
    fi

    # beginning of magical hack
    cd "${CUR_DIR}"
    rm -fr tmp
    mkdir tmp
    cd tmp/

    cp "${PSIPLUS_DIR}/patches"/*/*.diff ./ || exit 1
    cp "${PSIPLUS_DIR}/patches"/*/*.patch ./ || exit 1
    PATCHES=$(ls *.diff *.patch)
    FILES="$(grep '^--- a/' ${PATCHES} | sed -e 's|^.*:--- a/\(.*\)$|\1|' | sort -u)
           $(grep '^--- psi.orig/' ${PATCHES} | sed -e 's|^.*:--- psi.orig/\(.*\)$|\1|' | sort -u)"
    DIRS="$(dirname ${FILES} | sort -u | grep -v "^\.$")"
    for DIR in ${DIRS} ; do
        mkdir -p ${DIR}
    done
    for FILE in ${FILES} ; do
        cp -f ${PSIPLUS_DIR}/${FILE} "${FILE}" 2>/dev/null
    done
    for PATCH in ${PATCHES} ; do
        patch -f -p1 < "${PATCH}" > applied_patches.log
    done
    rm ${PATCHES}

    cd "${PSIPLUS_DIR}/src"
    python ../admin/update_options_ts.py ../options/default.xml > \
        "${CUR_DIR}/tmp/option_translations.cpp"
    # ending of magical hack

    cd "${CUR_DIR}"
    rm translations.pro

    echo "HEADERS = \\" >> translations.pro
    find "${PSIPLUS_DIR}/iris" "${PSIPLUS_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.h" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done

    echo "SOURCES = \\" >> translations.pro
    find "${PSIPLUS_DIR}/iris" "${PSIPLUS_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.cpp" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.cpp" >> translations.pro

    echo "FORMS = \\" >> translations.pro
    find "${PSIPLUS_DIR}/iris" "${PSIPLUS_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.ui" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.ui" >> translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo translations/*.ts >> translations.pro

    lupdate -verbose ./translations.pro

    git status || exit 1

;;
"tr_fu")
    # Fast update of localization files.

    git status || exit 1

    lupdate -verbose ./translations.pro

    git status || exit 1

;;
"tr_cl")
    # Cleaning update of localization files.

    git status || exit 1

    lupdate -verbose -no-obsolete ./translations.pro

    git status || exit 1

;;
"tr_push")
    # Pushing changes to Transifex.

    LANG_DIR="${MAIN_DIR}/psi-plus-l10n_transifex/translations/psi-plus.full"
    cd "${LANG_DIR}" || exit 1

    cd "${CUR_DIR}/translations/" || exit 1
    cp *.ts "${LANG_DIR}/"

    cd "${MAIN_DIR}/psi-plus-l10n_transifex/"
    if [ -z "${2}" ]; then
        echo "<arg> is not specified!"
        exit 1
    elif [ "${2}" = "src" ] ; then
        tx push -s || exit 1
    elif [ "${2}" = "all" ] ; then
        tx push -s -t || exit 1
    else
        tx push -t -l ${2} || exit 1
    fi

;;
"tr_co")
    # Cloning Transifex repo.

    if [ -d "${MAIN_DIR}/psi-plus-l10n_transifex" ]; then
        echo "${MAIN_DIR}/psi-plus-l10n_transifex"
        echo "directory already exists!"
    else
        echo "Creating ${MAIN_DIR}/psi-plus-l10n_transifex"
        mkdir -p "${MAIN_DIR}/psi-plus-l10n_transifex/.tx"
        cp "transifex.config" "${MAIN_DIR}/psi-plus-l10n_transifex/.tx/config"
        cd "${MAIN_DIR}/psi-plus-l10n_transifex" || exit 1
        tx pull -a -s || exit 1
    fi

;;
"tr_sync")
    # Syncing Transifex and Guthub repos.

    "${0}" up > /dev/null || exit 1
    "${0}" tr > /dev/null || exit 1

    if [ "$(git status | grep 'translations/' | wc -l)" -gt 0 ]; then
        "${0}" cm || exit 1
        "${0}" push || exit 1
    fi
    echo ;
;;
*)
    # Help.

    echo "Usage:"
    echo "  up cm tag push make install tarball"
    echo "  tr tr_up tr_fu tr_cl tr_co tr_sync"
    echo "  tr_push <arg> (arg: src, all or language code)"
    echo ;
    echo "Examples:"
    echo "  ./update-repo.sh tr_push src"
    echo "  ./update-repo.sh tr_push all"
    echo "  ./update-repo.sh tr_push ru"

;;
esac

exit 0
