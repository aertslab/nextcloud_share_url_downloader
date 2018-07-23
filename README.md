# Nextcloud shared URL downloader.

## Purpose

Download Nextcloud (password protected) shared links directly from the command
line without needing a webbrowser.


## Installation

```bash
# Clone this repository.
git clone https://github.com/aertslab/nextcloud_shared_url_downloader

cd nextcloud_shared_url_downloader
```


## Usage

```bash
# Ask for password:
./nextcloud_shared_url_downloader.sh <nextcloud_shared_download_url> <output_filename>

# Provide the password as an argument:
./nextcloud_shared_url_downloader.sh <nextcloud_shared_download_url> <output_filename> <nextcloud_share_password>
```

## Examples

### Download password protected files

```bash
# Download password protected file by providing the password as argument:
./nextcloud_shared_url_downloader.sh \
    https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT \
    test_download.zip \
    my_nextcloud_share_password

# Download password protected file by providing the password when being prompted for it:
./nextcloud_shared_url_downloader.sh \
    https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT \
    test_download.zip
```


### Download unprotected files

```bash
# Download unprotected file by providing an empty password as argument:
./nextcloud_shared_url_downloader.sh \
     https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT \
     test_download.zip \
     ""

# Download unprotected file by providing an empty password when being prompted for it:
./nextcloud_shared_url_downloader.sh \
     https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT \
     test_download.zip
```
