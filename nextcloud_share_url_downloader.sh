#!/bin/bash

# Copyright (c) 2018-2019 - Gert Hulselmans
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
#
# Purpose: Download files from and list content of NextCloud
#          (password protected) share from the command line.



usage () {
    printf '\nUsage:    %s <nextcloud_share_url>\n' "${0}";
    printf '          %s <nextcloud_share_url> <nextcloud_share_password>\n\n' "${0}";
    printf 'Purpose:  Download files from and list content of NextCloud (password protected) share.\n\n';
    printf 'Examples:\n\n';
    printf '    Download/list password protected file(s) by providing the password as argument:\n'
    printf '        %s \\\n' "${0}";
    printf '            "https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT" \\\n';
    printf '            "my_nextcloud_share_password"\n\n';
    printf '    Download/list password protected file(s) by providing the password when being prompted for it:\n'
    printf '        %s \\\n' "${0}";
    printf '            "https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT"\n\n';
    printf '    Download/list unprotected file(s) by providing an empty password as argument:\n'
    printf '        %s \\\n' "${0}";
    printf '            "https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT" \\\n';
    printf '            ""\n\n';
    printf '    Download/list unprotected file(s) by providing an empty password when being prompted for it:\n'
    printf '        %s \\\n' "${0}";
    printf '            "https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT"\n\n';
    printf '    Download/list password protected file(s) from a subdirectory:\n';
    printf '        %s \\\n' "${0}";
    printf '            "https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT?path=subdir" \\\n';
    printf '            "my_nextcloud_share_password"\n\n';
}



parse_nextcloud_share_url () {
    # Extract the following information from NextCloud share URL ("${nextcloud_share_url}"):
    #   - NextCloud host URL:      "${nextcloud_host_url}"
    #   - NextCloud share token:   "${nextcloud_share_token}"
    #   - NextCloud share subdir:  "${nextcloud_share_subdir}"

    if [ "${nextcloud_share_url:0:4}" != "http" ] ; then
        printf '\nError: "%s"\n' "${nextcloud_share_url}";
        printf '       is not an URL.\n\n';
        return 1;
    fi


    # Extract NextCloud host name with http(s) prefix from URL (if ugly URL: with "/index.php/").
    nextcloud_host_url="${nextcloud_share_url%/index.php/s/*}";

    # Extract NextCloud host name with http(s) prefix from URL (if pretty URL: without "/index.php/").
    nextcloud_host_url="${nextcloud_host_url%/s/*}";

    if [ "${#nextcloud_host_url}" = "${#nextcloud_share_url}" ] ; then
        printf '\nError: "%s"\n' "${nextcloud_share_url}";
        printf '       is not a NextCloud shared URL as it does not contain a "/s/" part.\n\n';
        return 1;
    fi


    # Extract NextCloud share token from the URL.
    local nextcloud_share_token_part="${nextcloud_share_url#${nextcloud_host_url}*/s/}"

    if [ $(expr index "${nextcloud_share_token_part}" '/?') -eq 16 ] ; then
        # Extract NextCloud share token till "/" or "?" character.
        nextcloud_share_token="${nextcloud_share_token_part:0:15}";
    elif [ "${#nextcloud_share_token_part}" -ne 15 ] ; then
        printf '\nError: Share token "%s" is not 15 characters long.\n\n' "${nextcloud_share_token_part}";
        return 1;
    else
        nextcloud_share_token="${nextcloud_share_token_part}";
    fi

    # Fix NextCloud share URL in case the URL contained charachters after the NextCloud share token.
    nextcloud_share_url="${nextcloud_share_url%${nextcloud_share_token_part}}${nextcloud_share_token}";

    if [ $(expr match "${nextcloud_share_token_part:16}" 'path=[^?]\+') -gt 0 ] ; then
        # Extract NextCloud share subdir from URL if provided ("?path=subdir").
        nextcloud_share_subdir=$(expr match "${nextcloud_share_token_part:21}" '\([^?]\+\)');
    fi

    return 0;
}



list_content_nextcloud_share_url () {
    # List content of NextCloud share URL ("${nextcloud_share_url}?path=${nextcloud_share_subdir}").
    # The results are stored in "${nextcloud_dir_listing_array[@]}".

    if [ $(type curl >/dev/null 2>&1; echo $?) -ne 0 ] ; then
        printf '\nError: "curl" is not installed.\n\n';
        return 1;
    fi


    printf '\nListening content of "%s" via WebDAV:\n' "${nextcloud_share_url}?path=${nextcloud_share_subdir}";
    printf '  - NextCloud host URL:      nextcloud_host_url="%s"\n' "${nextcloud_host_url}";
    printf '  - NextCloud share token:   nextcloud_share_token="%s"\n' "${nextcloud_share_token}";
    printf '  - NextCloud share subdir:  nextcloud_share_subdir="%s"\n\n' "${nextcloud_share_subdir}";

    # List content of NextCloud share via WebDAV:
    #   - Do a PROPFIND request via cURL.
    #   - Remove unneeded XML tags / replace XML tags with TABs.
    #   - Extract interesting columns with cut.
    #   - Remove lines which do not contain a file/folder path.
    #   - Construct full URLs for each file/folder path. 
    mapfile  nextcloud_dir_listing_array < <(
    curl \
        -s \
        -u "${nextcloud_share_token}:${nextcloud_share_password}" \
        -H 'X-Requested-With: XMLHttpRequest' \
        -X PROPFIND \
        --data \
            '<?xml version="1.0" encoding="UTF-8"?>
            <d:propfind xmlns:d="DAV:">
                <d:prop xmlns:oc="http://owncloud.org/ns">
                    <d:getlastmodified/>
                    <d:getcontentlength/>
                    <d:getcontenttype/>
                </d:prop>
            </d:propfind>' \
        "${nextcloud_host_url}/public.php/webdav/${nextcloud_share_subdir}" \
      | sed \
          -e '/^<?xml version="1.0"?>/d' \
          -e 's@</\?d:response>@\n@g' \
      | sed \
          -e '/^<d:multistatus/d' \
          -e 's@<d:[a-z]\+/>@@g' \
          -e 's@&quot;@@g' \
          -e 's@</\?\(d\|oc\):[a-z]\+>@\t@g' \
      | cut -f 2,6,8,10 \
      | sed \
          -e '/^\// ! d' \
          -e 's@.*/public.php/webdav@@';
    )

    # Print each file/subdir info line with a ascending number in front of it.
    for i in $(seq 0 $(( ${#nextcloud_dir_listing_array[@]} - 1 )) ) ; do
        printf '%d:\t%s\n' "${i}" "${nextcloud_dir_listing_array[${i}]}";
    done | column -t -s $'\t';

    printf '\n';
}



download_file_from_nextcloud_share () {
    # Download file from NextCloud share.

    local nextcloud_webdav_file_url="${1}";
    local output_filename="${2}";
    local resume_or_restart='';

    if [ $(type curl >/dev/null 2>&1; echo $?) -ne 0 ] ; then
        printf '\nError: "curl" is not installed.\n\n';
        return 1;
    fi


    printf '\nDownloading "%s/%s" from "%s" via WebDAV:\n' "${nextcloud_share_subdir}" "${output_filename}" "${nextcloud_share_url}";
    printf '  - NextCloud host URL:      nextcloud_host_url="%s"\n' "${nextcloud_host_url}";
    printf '  - NextCloud share token:   nextcloud_share_token="%s"\n' "${nextcloud_share_token}";
    printf '  - NextCloud share subdir:  nextcloud_share_subdir="%s"\n' "${nextcloud_share_subdir}";
    printf '  - Output filename:         output_filename="%s"\n\n' "${output_filename}";

    if [ -e "${output_filename}" ] ; then
        printf 'Warning: Output filename "%s" already exists.\n\n' "${output_filename}";

        while [[ "${resume_or_restart}" != 'R'  && "${resume_or_restart}" != 'S' ]] ; do
            read -p 'Do you want to (R)esume or re(S)tart the download or (C)ancel? ' resume_or_restart;

            # Convert answer to uppercase.
            resume_or_restart=$(printf '%s' "${resume_or_restart}" | tr '[a-z]' '[A-Z]');

            if [ "${resume_or_restart}" = 'C' ] ; then
                printf '\n';

                return 1;
            fi
        done

        printf '\n';
    fi

    if [ "${resume_or_restart}" = 'R' ] ; then
        # Resume download.
        curl \
            -C - \
            -u "${nextcloud_share_token}:${nextcloud_share_password}" \
            -H 'X-Requested-With: XMLHttpRequest' \
            -o "${output_filename}" \
            "${nextcloud_webdav_file_url}";

        exit_code=$?;
    else
        if [ "${resume_or_restart}" = 'S' ] ; then
            # Remove old output file before retrying to download the file.
            rm "${output_filename}";
        fi

        # Download file.
        curl \
            -u "${nextcloud_share_token}:${nextcloud_share_password}" \
            -H 'X-Requested-With: XMLHttpRequest' \
            -o "${output_filename}" \
            "${nextcloud_webdav_file_url}";

        exit_code=$?;
    fi

    printf '\n';

    return ${exit_code};
}



nextcloud_share_url_downloader () {
    if ( [ "${#@}" -ne 1 ] && [ "${#@}" -ne 2 ] ) ; then
        usage;
        return 1;
    fi

    nextcloud_share_url="${1}";

    if [ "${#@}" -eq 2 ] ; then
        nextcloud_share_password="${2}";
    else
        read -s -p "Enter NextCloud share password: " nextcloud_share_password;
        printf '\n\n';
    fi

    # Extract the following information from NextCloud share URL ("${nextcloud_share_url}"):
    #   - NextCloud host URL:     "${nextcloud_host_url}"
    #   - NextCloud share token:  "${nextcloud_share_token}"
    #   - NextCloud share subdir:  "${nextcloud_share_subdir}"
    parse_nextcloud_share_url "${nextcloud_share_url}" || return 1;

    # List content of NextCloud subdir "${nextcloud_share_subdir}" share URL ("${nextcloud_share_url}").
    # The results are stored in "${nextcloud_dir_listing_array[@]}".
    list_content_nextcloud_share_url;

    read -a file_or_dir_numbers -p 'Give list of file numbers to download and or directories to list: '

    local -a nextcloud_share_list_selected_subdirs;

    for file_or_dir_number_str in "${file_or_dir_numbers[@]}" ; do
        # Remove all non-numeric characters.
        file_or_dir_number=$(echo ${file_or_dir_number_str} | tr -c -d '0-9');

        if [[ "${file_or_dir_number_str}" != "${file_or_dir_number}" || "${file_or_dir_number}" -ge ${#nextcloud_dir_listing_array[@]} ]] ; then
            printf '\nError: File or dir number "%s" does not exist.\n\n' "${file_or_dir_number_str}";
            return 1;
        fi

        # Get NextCloud download URL for the file from the first column.
        nextcloud_file_or_dir_name="${nextcloud_dir_listing_array[${file_or_dir_number}]}";
        nextcloud_file_or_dir_name="${nextcloud_file_or_dir_name%%$'\t'*}";

        if [ "${nextcloud_file_or_dir_name:$(( ${#nextcloud_file_or_dir_name} - 1 ))}" = '/' ] ; then
            # Store subdirectory for later listening of content.
            nextcloud_share_list_selected_subdirs+=("${nextcloud_file_or_dir_name}");
        else
	    # Download file from NextCloud share.
	    download_file_from_nextcloud_share "${nextcloud_host_url}/public.php/webdav${nextcloud_file_or_dir_name}" $(basename "${nextcloud_file_or_dir_name}");
        fi
    done

    # List content of selected subdirectories.
    for nextcloud_share_list_selected_subdir in "${nextcloud_share_list_selected_subdirs[@]}" ; do
        # Set NextCloud share subdir.
        nextcloud_share_subdir="${nextcloud_share_list_selected_subdir}";

        # List content of NextCloud share subdir.
        list_content_nextcloud_share_url;
    done

    # If exactly 1 directory was selected for listing content, restart
    # nextcloud_share_url_downloader in that subdirectory.
    if [ "${#nextcloud_share_list_selected_subdirs[@]}" -eq 1 ] ; then
        nextcloud_share_url_downloader "${nextcloud_share_url}?path=${nextcloud_share_subdir}" "${nextcloud_share_password}";
    fi

    return 0;
}



nextcloud_share_url_downloader "${@}";
