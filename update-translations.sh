#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: GPLv2 or later
# Created: 2012-03-24
# Updated: 2020-06-03
# Version: N/A

set -e

export CUR_DIR="$(dirname $(realpath -s ${0}))"
export MAIN_DIR="$(realpath -s ${CUR_DIR}/..)"

PSIPLUS_DIR="${MAIN_DIR}/psi-plus-snapshots"
LANG_DIR="${MAIN_DIR}/psi-plus-l10n_transifex"

cd "${CUR_DIR}"

case "${1}" in
"up")
    # Pulling changes from GitHub repo.

    git pull --all

;;
"cm")
    # Creating correct git commit.

    git commit -a -m 'Translations were updated from Transifex.'

;;
"tag")
    # Creating correct git tag.

    cd "${PSIPLUS_DIR}"
    CUR_TAG="$(git tag -l  | sort -r -V | head -n1)"

    cd "${CUR_DIR}"
    echo "git tag \"${CUR_TAG}\""
    git tag "${CUR_TAG}"

    echo ;
    echo "Last tags:"
    git tag | sort -V | tail -n 10

;;
"push")
    # Pushing changes into GitHub repo.

    git push
    git push --tags

;;
"make")
    # Making precompiled localization files.

    rm -f translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo translations/*.ts >> translations.pro

    lrelease ./translations.pro

    mkdir -p out
    mv translations/*.qm out/

;;
"install")
    # Installing precompiled localization files into ${DESTDIR}.

    [ -z "${DESTDIR}" ] && DESTDIR="/usr"
    
    mkdir -p "${DESTDIR}/share/psi-plus/translations/"
    cp out/*.qm "${DESTDIR}/share/psi-plus/translations/"

;;
"tarball")
    # Generating tarball with precompiled localization files.

    CUR_TAG="$(git tag -l  | sort -r -V | head -n1)"

    rm -rf psi-plus-translations-*
    mkdir psi-plus-translations-${CUR_TAG}
    cp out/*.qm psi-plus-translations-${CUR_TAG}

    tar -cJf psi-plus-translations-${CUR_TAG}.tar.xz psi-plus-translations-${CUR_TAG}
    echo "Tarball with precompiled translation files is ready for upload:"
    [ ! -z "$(which realpath)" ] && echo "$(realpath ${CUR_DIR}/psi-plus-translations-${CUR_TAG}.tar.xz)"
    echo "https://sourceforge.net/projects/psiplus/files/Translations/"

;;
"tr")
    # Pulling changes from Transifex.

    # Test Internet connection:
    host transifex.com > /dev/null

    git status

    cd "${LANG_DIR}"
    tx pull -a -s

    cd "${LANG_DIR}/translations/psi-plus.full/"
    cp *.ts "${CUR_DIR}/translations/"

    cd "${LANG_DIR}/translations/psi-plus.desktop-file/"
    cp *.desktop "${CUR_DIR}/desktop-file/"

    cd "${CUR_DIR}"
    git status

;;
"tr_up")
    # Full update of localization files.

    git status

    if [ -d "${PSIPLUS_DIR}" ]; then
        echo "Updating ${PSIPLUS_DIR}"
        cd "${PSIPLUS_DIR}"
        git pull --all
        echo;
    else
        echo "Creating ${PSIPLUS_DIR}"
        cd "${MAIN_DIR}"
        git clone https://github.com/psi-plus/psi-plus-snapshots.git
        echo;
    fi

    # beginning of magical hack
    cd "${CUR_DIR}"
    rm -fr tmp
    mkdir tmp
    cd tmp/

    cp "${PSIPLUS_DIR}/patches"/*/*.diff ./
    cp "${PSIPLUS_DIR}/patches"/*/*.patch ./
    PATCHES=$(ls *.diff *.patch)
    FILES="$(grep '^--- a/' ${PATCHES} | sed -e 's|^.*:--- a/\(.*\)$|\1|' | sort -u)
           $(grep '^--- psi.orig/' ${PATCHES} | sed -e 's|^.*:--- psi.orig/\(.*\)$|\1|' | sort -u)"
    DIRS="$(dirname ${FILES} | sort -u | grep -v "^\.$")"
    for DIR in ${DIRS} ; do
        mkdir -p ${DIR}
    done
    for FILE in ${FILES} ; do
        cp -f ${PSIPLUS_DIR}/${FILE} "${FILE}" 2>/dev/null || true
    done
    for PATCH in ${PATCHES} ; do
        patch -f -p1 < "${PATCH}" > applied_patches.log || true
    done
    rm ${PATCHES}

    cd "${PSIPLUS_DIR}/src"
    python ../admin/update_options_ts.py ../options/default.xml > \
        "${CUR_DIR}/tmp/option_translations.cpp"
    # ending of magical hack

    cd "${CUR_DIR}"
    rm -r translations.pro

    echo "HEADERS = \\" >> translations.pro
    find "${PSIPLUS_DIR}/iris" "${PSIPLUS_DIR}/plugins" "${PSIPLUS_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.h" | \
        grep -v "/builddir/" | \
        grep -v "/plugins/generic/psimedia/demo" | \
        grep -v "/plugins/generic/psimedia/gstplugin"| \
        grep -v "/plugins/generic/psimedia/gstprovider" | \
        grep -v "/plugins/generic/psimedia/psimedia" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done

    echo "SOURCES = \\" >> translations.pro
    find "${PSIPLUS_DIR}/iris" "${PSIPLUS_DIR}/plugins" "${PSIPLUS_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.cpp" | \
        grep -v "/builddir/" | \
        grep -v "/plugins/generic/psimedia/demo" | \
        grep -v "/plugins/generic/psimedia/gstplugin"| \
        grep -v "/plugins/generic/psimedia/gstprovider" | \
        grep -v "/plugins/generic/psimedia/psimedia" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.cpp" >> translations.pro

    echo "FORMS = \\" >> translations.pro
    find "${PSIPLUS_DIR}/iris" "${PSIPLUS_DIR}/plugins" "${PSIPLUS_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.ui" | \
        grep -v "/builddir/" | \
        grep -v "/plugins/generic/psimedia/demo" | \
        grep -v "/plugins/generic/psimedia/gstplugin"| \
        grep -v "/plugins/generic/psimedia/gstprovider" | \
        grep -v "/plugins/generic/psimedia/psimedia" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.ui" >> translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo translations/*.ts >> translations.pro

    lupdate -verbose ./translations.pro

    cp "${PSIPLUS_DIR}"/*.desktop "${CUR_DIR}/desktop-file/"

    git status

;;
"tr_fu")
    # Fast update of localization files.

    git status

    lupdate -verbose ./translations.pro

    cp "${PSIPLUS_DIR}"/*.desktop "${CUR_DIR}/desktop-file/"

    git status

;;
"tr_cl")
    # Cleaning update of localization files.

    git status

    lupdate -verbose -no-obsolete ./translations.pro

    cp "${PSIPLUS_DIR}"/*.desktop "${CUR_DIR}/desktop-file/"

    git status

;;
"tr_push")
    # Pushing changes to Transifex.

    cd "${LANG_DIR}/translations"

    cp "${CUR_DIR}"/translations/*.ts psi-plus.full/
    cp "${CUR_DIR}"/desktop-file/*.desktop psi-plus.desktop-file/

    cd "${LANG_DIR}"
    if [ -z "${2}" ]; then
        echo "<arg> is not specified!"
        exit 1
    elif [ "${2}" = "src" ] ; then
        tx push -s
    elif [ "${2}" = "all" ] ; then
        tx push -s -t --skip
    else
        tx push -t -l ${2} --skip
    fi

;;
"tr_co")
    # Cloning Transifex repo.

    if [ -d "${MAIN_DIR}/psi-plus-l10n_transifex" ]; then
        echo "\"${MAIN_DIR}/psi-plus-l10n_transifex\" directory already exists!"
        exit 1
    else
        echo "Creating ${MAIN_DIR}/psi-plus-l10n_transifex"
        mkdir -p "${MAIN_DIR}/psi-plus-l10n_transifex/.tx"
        cp "transifex.config" "${MAIN_DIR}/psi-plus-l10n_transifex/.tx/config"
        cd "${MAIN_DIR}/psi-plus-l10n_transifex"
        tx pull -a -s
    fi

;;
"tr_sync")
    # Syncing Transifex and GitHub repos.

    "${0}" up > /dev/null
    "${0}" tr > /dev/null

    if [ "$(git status | grep 'translations/' | wc -l)" -gt 0 ]; then
        "${0}" cm
        "${0}" push
    fi
    echo ;

;;
"desktop_up")
    # Update main .desktop file

    GENERICNAME_FULL_DATA=$(grep -r "GenericName\[" "${CUR_DIR}/desktop-file/" | grep -v '/psi.desktop:' | grep -v '/psi_en.desktop:')
    GENERICNAME_FILTERED_DATA=$(echo "${GENERICNAME_FULL_DATA}" | sed -ne 's|^.*/psi_.*.desktop:\(.*\)$|\1|p')
    GENERICNAME_SORTED_DATA=$(echo "${GENERICNAME_FILTERED_DATA}" | sort -uV)

    COMMENT_FULL_DATA=$(grep -r "Comment\[" "${CUR_DIR}/desktop-file/" | grep -v '/psi.desktop:' | grep -v '/psi_en.desktop:')
    COMMENT_FILTERED_DATA=$(echo "${COMMENT_FULL_DATA}" | sed -ne 's|^.*/psi_.*.desktop:\(.*\)$|\1|p')
    COMMENT_SORTED_DATA=$(echo "${COMMENT_FILTERED_DATA}" | sort -uV)

    DESKTOP_FILE="${CUR_DIR}/desktop-file/psi.desktop"
    grep -v "GenericName\[" "${DESKTOP_FILE}" > "${DESKTOP_FILE}.tmp"
    mv -f "${DESKTOP_FILE}.tmp" "${DESKTOP_FILE}"
    grep -v "Comment\[" "${DESKTOP_FILE}" > "${DESKTOP_FILE}.tmp"
    mv -f "${DESKTOP_FILE}.tmp" "${DESKTOP_FILE}"
    echo "${GENERICNAME_SORTED_DATA}" >> "${DESKTOP_FILE}"
    echo "${COMMENT_SORTED_DATA}" >> "${DESKTOP_FILE}"

    # Update .desktop file for English localization
    cp -f "${CUR_DIR}/desktop-file/psi.desktop" \
          "${CUR_DIR}/desktop-file/psi_en.desktop"

;;
*)
    # Help.

    echo "Usage:"
    echo "  up cm tag push make install tarball"
    echo "  tr tr_up tr_fu tr_cl tr_co tr_sync desktop_up"
    echo "  tr_push <arg> (arg: src, all or language code)"
    echo ;
    echo "Examples:"
    echo "  ./update-translations.sh tr_push src"
    echo "  ./update-translations.sh tr_push all"
    echo "  ./update-translations.sh tr_push ru"

;;
esac

exit 0
