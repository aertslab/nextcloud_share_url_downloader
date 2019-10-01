# Nextcloud share URL downloader.

## Purpose

Download files from and list content of NextCloud (password protected) share
directly from the command line without needing a webbrowser.


## Installation

```bash
# Clone this repository.
git clone https://github.com/aertslab/nextcloud_share_url_downloader

cd nextcloud_share_url_downloader
```


## Usage

```bash
# Ask for password:
./nextcloud_share_url_downloader.sh <nextcloud_share_url>

# Provide the password as an argument:
./nextcloud_share_url_downloader.sh <nextcloud_share_url> <nextcloud_share_password>
```


## Examples

### Download password protected file(s)

```bash
# Download/list password protected file(s) by providing the password as argument:
./nextcloud_share_url_downloader.sh \
    "https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT" \
    "my_nextcloud_share_password"

# Download/list password protected file(s) by providing the password when being prompted for it:
./nextcloud_share_url_downloader.sh \
    "https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT"
```


### Download/list unprotected file(s)

```bash
# Download/list unprotected file(s) by providing an empty password as argument:
./nextcloud_share_url_downloader.sh \
    "https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT" \
    ""

# Download/list unprotected file(s) by providing an empty password when being prompted for it:
./nextcloud_share_url_downloader.sh \
    "https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT"
```


### Download/list password protected file(s) from a subdirectory

```bash
# Download/list password protected file(s) from a subdirectory:
./nextcloud_share_url_downloader.sh \
    "https://nextcloud.example.com/index.php/s/c56Ci4EpLnjj9xT?path=subdir" \
    "my_nextcloud_share_password"
```

