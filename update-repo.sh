#! /bin/bash

# Author:  Boris Pek <tehnick-8@mail.ru>
# License: GPLv2 or later
# Created: 2012-03-24
# Updated: 2012-05-20
# Version: N/A

export CUR_DIR="${PWD}/$(dirname ${0})"
export MAIN_DIR="${CUR_DIR}/.."
export PSIPLUS_DIR="${MAIN_DIR}/psi-plus"

git status

case "${1}" in
"up")

    git pull --all || exit 1

;;
"cm")

    git commit -a -m 'Translations were updated from Transifex.' || exit 1

;;
"tag")

    cd "${PSIPLUS_DIR}" || exit 1
    CUR_TAG="$(git tag -l  | sort -r -V | head -n1)"

    cd "${CUR_DIR}" || exit 1
    echo "git tag \"${CUR_TAG}\""
    git tag "${CUR_TAG}"

;;
"push")

    git push || exit 1
    git push --tags || exit 1

;;
"make")

    rm translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo translations/*.ts >> translations.pro

    lrelease ./translations.pro

    mkdir -p out
    mv translations/*.qm out/ || exit 1

;;
"install")

    if [ ${USER} != "root" ]; then
        echo "You are not a root now!"
        exit 1
    fi

    mkdir -p /usr/share/psi-plus/translations/
    cp out/*.qm /usr/share/psi-plus/translations/ || exit 1

;;
"tarball")

    CUR_TAG="$(git tag -l  | sort -r -V | head -n1)"

    rm -rf psi-plus_translations_*
    mkdir psi-plus_translations_${CUR_TAG} || exit 1
    cp out/*.qm psi-plus_translations_${CUR_TAG} || exit 1

    tar -cJf psi-plus_translations_${CUR_TAG}.tar.xz psi-plus_translations_${CUR_TAG} || exit 1
    echo "Tarball with precompiled translation files is ready for upload:"
    echo "https://github.com/tehnick/psi-plus-i18n/downloads"

;;
"tr")

    LANG_DIR="${CUR_DIR}/translations"

    cd "${MAIN_DIR}/psi-plus-i18n_transifex" || exit 1
    tx pull -a -s || exit 1

    cd "translations/psi-plus.full/" || exit 1
    cp *.ts "${LANG_DIR}/"

    cd "${CUR_DIR}"
    git status

;;
"tr_up")

    if [ -d "${PSIPLUS_DIR}" ]; then
        echo "Updating ${PSIPLUS_DIR}"
        cd "${PSIPLUS_DIR}"
        git pull --all || exit 1
        echo;
    else
        echo "Creating ${PSIPLUS_DIR}"
        cd "${MAIN_DIR}"
        git clone git://github.com/tehnick/psi-plus.git || exit 1
        echo;
    fi

    # beginning of magical hack
    cd "${CUR_DIR}"
    rm -fr tmp
    mkdir tmp
    cd tmp/

    cp "${PSIPLUS_DIR}/src/patches/mac/3030-psi-mac-sparkle.diff" ./ || exit 1
    cp "${PSIPLUS_DIR}/src/psiactionlist.cpp" ./ || exit 1
    cp "${PSIPLUS_DIR}/src/mainwin.cpp" ./ || exit 1
    patch -f -p2 < 3030-psi-mac-sparkle.diff > /dev/null

    cd "${PSIPLUS_DIR}/src"
    python ../admin/update_options_ts.py ../options/default.xml > \
        "${CUR_DIR}/tmp/option_translations.cpp"
    # ending of magical hack

    cd "${CUR_DIR}"
    rm translations.pro

    echo "HEADERS = \\" >> translations.pro
    find "${PSIPLUS_DIR}/iris" "${PSIPLUS_DIR}/src" -type f -name "*.h" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.h" >> translations.pro

    echo "SOURCES = \\" >> translations.pro
    find "${PSIPLUS_DIR}/iris" "${PSIPLUS_DIR}/src" -type f -name "*.cpp" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.cpp" >> translations.pro

    echo "FORMS = \\" >> translations.pro
    find "${PSIPLUS_DIR}/iris" "${PSIPLUS_DIR}/src" -type f -name "*.ui" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.ui" >> translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo translations/*.ts >> translations.pro

    lupdate -verbose ./translations.pro

;;
"tr_cl")

    lupdate -verbose -no-obsolete ./translations.pro

;;
"tr_push")

    LANG_DIR="${MAIN_DIR}/psi-plus-i18n_transifex/translations/psi-plus.full"
    cd "${LANG_DIR}" || exit 1

    cd "${CUR_DIR}/translations/" || exit 1
    cp *.ts "${LANG_DIR}/"

    cd "${MAIN_DIR}/psi-plus-i18n_transifex/"
    tx push -s -t || exit 1

;;
"tr_co")

    if [ -d "${MAIN_DIR}/psi-plus-i18n_transifex" ]; then
        echo "${MAIN_DIR}/psi-plus-i18n_transifex"
        echo "directory is already exists!"
    else
        echo "Creating ${MAIN_DIR}/psi-plus-i18n_transifex"
        mkdir -p "${MAIN_DIR}/psi-plus-i18n_transifex/.tx"
        cp "transifex.config" "${MAIN_DIR}/psi-plus-i18n_transifex/.tx/config"
        cd "${MAIN_DIR}/psi-plus-i18n_transifex" || exit 1
        tx pull -a -s || exit 1
    fi

;;
*)

    echo "Usage:"
    echo "  up cm tag push make install tarball"
    echo "  tr tr_up tr_cl tr_push tr_co"

;;
esac

exit 0
