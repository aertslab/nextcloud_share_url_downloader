#!/bin/bash

# Copyright (c) 2018 - Gert Hulselmans
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
# Purpose: Download Nextcloud (password protected) shared links
#          from the command line.


if ( [ "${#@}" -ne 2 ] && [ "${#@}" -ne 3 ] ) ; then
    printf '\nUsage:    %s <nextcloud_shared_download_url> <output_filename>\n' "${0}";
    printf '          %s <nextcloud_shared_download_url> <output_filename> <nextcloud_share_password>\n\n' "${0}";
    printf 'Purpose:  Download Nextcloud (password protected) shared links.\n\n';
    printf 'Examples:\n\n';
    printf '    Download password protected file by providing the password as argument:\n'
    printf '        %s \\\n' "${0}";
    printf '            https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT \\\n';
    printf '            test_download.zip \\\n';
    printf '            my_nextcloud_share_password\n\n';
    printf '    Download password protected file by providing the password when being prompted for it:\n'
    printf '        %s \\\n' "${0}";
    printf '            https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT \\\n';
    printf '            test_download.zip\n\n';
    printf '    Download unprotected file by providing an empty password as argument:\n'
    printf '        %s \\\n' "${0}";
    printf '            https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT \\\n';
    printf '            test_download.zip \\\n';
    printf '            ""\n\n';
    printf '    Download unprotected file by providing an empty password when being prompted for it:\n'
    printf '        %s \\\n' "${0}";
    printf '            https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT \\\n';
    printf '            test_download.zip\n\n';
    exit 1;
fi

nextcloud_shared_download_url="${1}"
output_filename="${2}";

if [ "${#@}" -eq 3 ] ; then
    nextcloud_share_password="${3}";
else
    read -s -p "Enter Nextcloud share password: " nextcloud_share_password;
    printf '\n\n';
fi


if [ "${nextcloud_shared_download_url:0:4}" != "http" ] ; then
    printf 'Error: "%s"\n' "${nextcloud_shared_download_url}";
    printf '       is not an URL.\n';
    exit 1;
fi


# Extract Nextcloud host name with http(s) prefix from URL (if ugly URL: with "/index.php/").
nextcloud_host_url="${nextcloud_shared_download_url%/index.php/s/*}";

# Extract Nextcloud host name with http(s) prefix from URL (if pretty URL: without "/index.php/").
nextcloud_host_url="${nextcloud_host_url%/s/*}";

if [ "${#nextcloud_host_url}" = "${#nextcloud_shared_download_url}" ] ; then
    printf 'Error: "%s"\n' "${nextcloud_shared_download_url}";
    printf '       is not a Nextcloud shared URL as it does not contain a "/s/" part.\n';
    exit 1;
fi


# Extract Nextcloud share token from the URL.
nextcloud_share_token="${nextcloud_shared_download_url#${nextcloud_host_url}*/s/}"
nextcloud_share_token="${nextcloud_share_token%/download}";

if [ "${#nextcloud_share_token}" -ne 15 ] ; then
    printf 'Error: Share token "%s" is not 15 characters long.\n' "${nextcloud_share_token}";
    exit 1;
fi


if [ -e "${output_filename}" ] ; then
    printf 'Error: Output filename "%s" already exists.\n' "${output_filename}";
    exit 1;
fi


if [ $(type curl >/dev/null 2>&1; echo $?) -ne 0 ] ; then
    printf 'Error: "curl" is not installed.\n';
    exit 1;
fi


printf 'Downloading "%s" via WebDAV:\n' "${nextcloud_shared_download_url}";
printf '  - Nextcloud host URL: %s\n' "${nextcloud_host_url}";
printf '  - Share token:        %s\n' "${nextcloud_share_token}";
printf '  - Output filename:    %s\n\n' "${output_filename}";

curl \
    -u "${nextcloud_share_token}:${nextcloud_share_password}" \
    -o "${output_filename}" \
    "${nextcloud_host_url}/public.php/webdav";
