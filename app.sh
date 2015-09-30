# Download a Go archive file and unpack it, removing old files.
# $1: file
# $2: url
# $3: folder
_download_go() {
  [[ ! -d "download" ]]      && mkdir -p "download"
  [[ ! -d "target" ]]        && mkdir -p "target"
  [[ ! -f "download/${1}" ]] && wget -O "download/${1}" "${2}"
  [[   -d "target/${3}" ]]   && rm -vfr "target/${3}"
  [[ ! -d "target/${3}" ]]   && mkdir -p "target/${3}" && tar -zxvf "download/${1}" -C "target/${3}"
  return 0
}

## GO BOOTSTRAP ##
export GO_BOOTSTRAP_VERSION="1.4.3"
_build_go_bootstrap() {
local VERSION="${GO_BOOTSTRAP_VERSION}"
local FOLDER="go${VERSION}"
local FILE="${FOLDER}.src.tar.gz"
local URL="https://storage.googleapis.com/golang/${FILE}"

_download_go "${FILE}" "${URL}" "${FOLDER}"

( . uncrosscompile.sh
  pushd "target/${FOLDER}/go/src"
  export GOROOT="${PWD}"
  export CC=/usr/bin/gcc
  ./make.bash )
}

## GO ##
_build_go() {
local VERSION="1.5.1"
local FOLDER="go${VERSION}"
local FILE="${FOLDER}.src.tar.gz"
local URL="https://storage.googleapis.com/golang/${FILE}"

_download_go "${FILE}" "${URL}" "${FOLDER}"
cp "src/${FOLDER}-16kb-page-size.patch" "target/${FOLDER}/go"

export GOROOT_BOOTSTRAP="${PWD}/target/go${GO_BOOTSTRAP_VERSION}/go"
export GOROOT_FINAL="${DEST}"
export CC_FOR_TARGET="${CC}"
export CXX_FOR_TARGET="${CXX}"
export GOGCCFLAGS="${CFLAGS}"
export GOARCH=arm
export GOARM=7
export GOOS=linux
case $(uname -p) in
  x86_64) export GOHOSTARCH=amd64 ;;
  *)      export GOHOSTARCH=386 ;;
esac

( . uncrosscompile.sh
  pushd "target/${FOLDER}/go"
  patch -p1 -i "${FOLDER}-16kb-page-size.patch"
  cd src
#  export GOROOT="${PWD}"
  export CC=/usr/bin/gcc
  ./make.bash
  popd
)

if [ -d "${DEST}" ]; then rm -fr "${DEST}"; fi
cp -vfaR "target/${FOLDER}/go" "${DEST}"
}

### BUILD ###
_build() {
  _build_go_bootstrap
  _build_go
  _package
}
