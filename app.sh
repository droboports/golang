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

## GO ##
_build_go() {
local VERSION="1.4.2"
local FOLDER="go${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://go.googlesource.com/go/+archive/${FILE}"
#export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

_download_go "${FILE}" "${URL}" "${FOLDER}"
cp "src/${FOLDER}-16kb-page-size.patch" "target/${FOLDER}"
export GOROOT_FINAL="${DEST}"
export CC_FOR_TARGET="${CC}"
export CXX_FOR_TARGET="${CXX}"
export GOARCH=arm
export GOARM=7
export GOOS=linux
case $(uname -p) in
  x86_64) export GOHOSTARCH=amd64 ;;
  *)      export GOHOSTARCH=386 ;;
esac

( . uncrosscompile.sh
  pushd "target/${FOLDER}"
  patch -p1 -i "${FOLDER}-16kb-page-size.patch"
  cd src
  export CC=/usr/bin/gcc
  ./make.bash
  popd
)

mkdir -p "${DEST}/bin" "${DEST}/libexec"
cp -vfaR "target/${FOLDER}/bin/linux_arm/"* "${DEST}/bin/"
cp -vfaR "target/${FOLDER}/pkg/tool/linux_arm/"* "${DEST}/libexec/"
}

### BUILD ###
_build() {
  _build_go
  _package
}
