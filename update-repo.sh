#! /bin/bash

# Author:  Boris Pek <tehnick-8@mail.ru>
# License: GPLv2 or later
# Created: 2012-03-24
# Updated: 2012-03-24
# Version: N/A

export CUR_DIR="${PWD}/$(dirname ${0})"
export MAIN_DIR="${CUR_DIR}/.."
export PSIPLUS_DIR="${MAIN_DIR}/psi-plus"

git status

case "${1}" in
"up")

    git pull --all || exit 1

;;
"push")

    git push || exit 1
    git push --tags || exit 1

;;
"make")

    for FILE in translations/*.ts; do
        lrelease ${FILE}
    done

    mkdir -p out
    mv translations/*.qm out/ || exit 1

;;
"install")

    if [ ${USER} != "root" ]; then
        echo "You are not a root now!"
        exit 1
    fi

    cp out/*.qm /usr/share/psi-plus/ || exit 1

;;
"tr")

    LANG_DIR="${CUR_DIR}/translations/"

    cd "${MAIN_DIR}/psi-plus-i18n_transifex" || exit 1
    tx pull -a -s || exit 1

    cd "translations/psi-plus.full/" || exit 1
    for FILE_FROM in *.ts ; do
        FILE_TO="psi_${FILE_FROM}"
        echo "Copying '${FILE_FROM}' to '${FILE_TO}'"
        cp -f "${FILE_FROM}" "${LANG_DIR}/${FILE_TO}"
    done

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

    cd "${CUR_DIR}"
    rm translations.pro

    echo "HEADERS = \\" >> translations.pro
    find "${PSIPLUS_DIR}" -type f -name "*.h" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ." >> translations.pro

    echo "SOURCES = \\" >> translations.pro
    find "${PSIPLUS_DIR}" -type f -name "*.cpp" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ." >> translations.pro

    echo "FORMS = \\" >> translations.pro
    find "${PSIPLUS_DIR}" -type f -name "*.ui" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ." >> translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo "  translations/psi_en.ts\\" >> translations.pro
    echo "  translations/psi_ru.ts" >> translations.pro

    lupdate ./translations.pro

;;
"tr_push")

    LANG_DIR="${MAIN_DIR}/psi-plus-i18n_transifex/translations/psi-plus.full/"
    cd "${LANG_DIR}" || exit 1

    cd "${CUR_DIR}/translations/" || exit 1
    for FILE_FROM in *.ts ; do
        FILE_TO=$(echo ${FILE_FROM} | sed -e "s/psi_//")
        echo "Copying '${FILE_FROM}' to '${FILE_TO}'"
        cp -f "${FILE_FROM}" "${LANG_DIR}/${FILE_TO}"
    done

    cd "${MAIN_DIR}/psi-plus-i18n_transifex/"
    tx push -s -t || exit 1

;;
"tr_co")

    if [ -d "${MAIN_DIR}/psi-plus-i18n_transifex" ]; then
        echo "${MAIN_DIR}/psi-plus-i18n_transifex"
        echo "directory is already exists!"
    else
        echo "Creating ${MAIN_DIR}/psi-plus-i18n_transifex"
        mkdir -p "${MAIN_DIR}/psi-plus-i18n_transifex"
        cd "${MAIN_DIR}/psi-plus-i18n_transifex" || exit 1

        tx init
        tx set --auto-remote  https://www.transifex.net/projects/p/psi-plus/
        tx pull -a
    fi

;;
*)

    echo "Usage:"
    echo "  up push make install"
    echo "  tr tr_up tr_push tr_co"

;;
esac

exit 0
