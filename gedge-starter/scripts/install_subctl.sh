#!/bin/bash
set -e -o pipefail

get_operating_system() {
  case $(uname -s) in

    Darwin*) echo "darwin" ;;
    Linux*) echo "linux" ;;
    CYGWIN*) echo "windows" ;;
    MINGW*) echo "windows" ;;
    *)
    error "This installer only works on Linux, macos and Windows. Found $(uname -s)"
    return 1;;
  esac
}

get_architecture() {
  case $(uname -m) in

    x86_64) echo "amd64" ;;
    amd64) echo "amd64" ;;
    arm64) echo "arm64" ;;
    i?86) echo "386" ;;
    *)
    error "This installer only supports x86_64, i386, amd64 and arm64 architectures. Found $(uname -m)"
    return 1;;
  esac
}

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

download_command() {
  if command_exists curl; then
    echo "curl -fsSL"
  elif command_exists wget; then
    echo "wget -qO-"
  else
    error "curl and wget are missing"
    return 1
  fi
}

get=$(download_command)

sanitized_version() {
  case $1 in
    rc|latest|devel|release*|feature*|v*) echo $1;;
    *) echo "v$1" ;;
  esac
}

get_subctl_release_url() {
  local draft_filter="cat"
  local url
  case ${VERSION} in
    rc) url=https://api.github.com/repos/submariner-io/releases/releases
           draft_filter="grep \-rc"
           ;;
    latest) url=https://api.github.com/repos/submariner-io/releases/releases/latest ;;
    feature-multi-active-gw|release-0.?|release-0.1[012])
        echo "https://github.com/submariner-io/submariner-operator/releases/download/subctl-${VERSION}/subctl-${VERSION}-${os}-${architecture}.tar.xz"
        return
        ;;
    devel|release*|feature*)
        echo "https://github.com/submariner-io/subctl/releases/download/subctl-${VERSION}/subctl-${VERSION}-${os}-${architecture}.tar.xz"
        return
        ;;
    v0.[1234567].*)
        echo "https://github.com/submariner-io/submariner-operator/releases/download/${VERSION}/subctl-${VERSION}-${os}-${architecture}.tar.xz"
        return
        ;;
    *) echo "https://github.com/submariner-io/releases/releases/download/${VERSION}/subctl-${VERSION}-${os}-${architecture}.tar.xz"
       return
       ;;
  esac

  ${get} "${url}" | grep "browser_download_url.*-${os}-${architecture}" | ${draft_filter} | head -n 1 | cut -d\" -f 4
}

finish_cleanup() {
  [ -z "${tmpdir}" ] || rm -rf "$tmpdir"
}

get_subctl() {
  tmpdir=$(mktemp -d)

  cd "${tmpdir}"

  # Retry downloading several times, as the underlying $get command might not support the retries we need.
  for i in {1..5}; do
    echo "Download attempt #${i}..."
    download_and_install && return 0

    [ "$i" == 5 ] && exit 1
    sleep "${backoff}"
    backoff=$((backoff * 2))
  done
}

download_and_install() {
  case ${url} in
    *tar.xz)
      ${get} "${url}" | tar xfJ - || return 1
      # shellcheck disable=SC2086
      install_subctl subctl*/subctl*
      ;;
    *) # non tar.xz releases (older)
      filename=$(basename "${url}")
      ${get} "${url}" > "${filename}"
      install_subctl "${filename}"
      ;;
  esac
}

install_subctl() {
  local bin=$1
  local bin_file
  local destdir=${DESTDIR:-~/.local/bin}
  local dest=${destdir}/subctl

  mkdir -p "$destdir"
  
  # Delete the target if it exists, to ensure we get a new inode
  # This allows a running subctl to be replace (e.g. if subctl is really a download script)
  rm -f "${dest}"
  cp "${bin}" "${dest}"
  chmod +x "${dest}"

  bin_file=$(basename "${bin}")
  echo "${bin_file} has been installed as ${dest}"
  printf "This provides "
  ${dest} version
  if [ "$(command -v subctl)" != "${dest}" ]; then
    echo ""
    echo "please update your path (and consider adding it to ~/.profile):
    export PATH=\$PATH:${destdir}
    "
  fi
}

# VERSION=$(sanitized_version "${VERSION:-latest}")
VERSION=0.14.0
os=$(get_operating_system)
architecture=$(get_architecture)
url=$(get_subctl_release_url)
backoff=1

echo "Installing subctl version $VERSION"
echo "  OS detected:           ${os}"
echo "  Architecture detected: ${architecture}"
echo "  Download URL:          ${url}"
echo ""
echo "Downloading..."

trap finish_cleanup EXIT

get_subctl
