# Server Switcher

Easily switch between servers, proxies and PHP versions on _macOS_ using [Homebrew](https://brew.sh) and [fzf](https://github.com/junegunn/fzf).

---

Managing multiple webservers and PHP version for development along with several different configurations can be messy after a while.
The `server-switcher` bundles all needed config files to run Apache, Nginx, Proxies and PHP without touching the default configuration.

## Installation

Install _Apache_, _Nginx_, _PHP_ and _fzf_:

```bash
brew install httpd
brew install nginx
brew install php
brew install fzf
```

Older PHP versions can be added as well and will be automatically picked up by the switcher:

```bash
brew install php@8.0
brew install php@8.1
```

That's all.

## Configuration

The basic configuration for the servers as well as for PHP-FPM has to be placed in a single `.env` file in the root of this repository:

```bash
SERVER_NAME=my-server.local
USER=username
DOC_ROOT=/Users/username/dev
PORT=8080
PHP_PORT=9005
PROXY_PATH=some-subdirectory
PROXY_PORT=3333
```

| Name          | Description                                                                                                                                  |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `SERVER_NAME` | The server name                                                                                                                              |
| `USER`        | The username for running the servers as well as PHP                                                                                          |
| `DOC_ROOT`    | The document root directory                                                                                                                  |
| `PORT`        | The server's port                                                                                                                            |
| `PHP_PORT`    | The port where PHP port, is usually `9000` &mdash; make sure to change that one to another number such as `9005` in order to avoid conflicts |
| `PROXY_PATH`  | The path for redirecting the proxy to &mdash; more below                                                                                     |
| `PROXY_PORT`  | The port for the proxy                                                                                                                       |

### Nginx Locations

The switcher looks for `index.php` files on startup and dynamically adds location blocks for those pages to a temporary `nginx.conf` that is used to start the server.

### Proxies

Since this setup is basically made for developing and testing PHP applications locally, it is sometimes also required to test an application's
behavior when being behind a proxy. The switcher provides an easy to use interface for spinning up an Apache proxy that is pointing to a subdiretory (`PROXY_PATH`)
that is hosted by Nginx or vice versa.

## Usage

In order to use the switcher, simply run the `server-switcher.sh` inside this repository. However it is probaly more convenient to add a little alias to your shell config:

```
alias srv='sh ~/server-switcher/server-switcher.sh'
```

and then invoke the switcher with just typing `srv` in your terminal to get nice fuzzy-finder menu with all possible combinations of servers and PHP versions.
