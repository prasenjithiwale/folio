#!/bin/sh
# Installs kaffy, a terminal UI for Kafka.
#
#   curl -fsSL https://prasenjithiwale.github.io/folio/kaffy/install.sh | sh
#
# Environment variables:
#   KAFFY_VERSION      version to install, e.g. v0.1.0 (default: latest)
#   KAFFY_INSTALL_DIR  where to put the binary (default: ~/.local/bin)
#
# Everything runs inside main(), so a partially downloaded script does nothing.

set -eu

RELEASES_URL="${KAFFY_RELEASES_URL:-https://prasenjithiwale.github.io/folio/kaffy/releases}"

say() { printf 'kaffy-install: %s\n' "$*"; }
err() { printf 'kaffy-install: error: %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }

# fetch URL [FILE]: print to stdout, or save to FILE.
fetch() {
    if has curl; then
        if [ $# -eq 2 ]; then curl -fsSL --retry 3 -o "$2" "$1"; else curl -fsSL --retry 3 "$1"; fi
    elif has wget; then
        if [ $# -eq 2 ]; then wget -qO "$2" "$1"; else wget -qO- "$1"; fi
    else
        err "need curl or wget to download kaffy"
    fi
}

sha256() {
    if has sha256sum; then sha256sum "$1" | cut -d' ' -f1
    elif has shasum; then shasum -a 256 "$1" | cut -d' ' -f1
    else err "need sha256sum or shasum to verify the download"
    fi
}

detect_target() {
    os=$(uname -s)
    arch=$(uname -m)
    # A shell running under Rosetta reports x86_64 on Apple Silicon; prefer the native build.
    if [ "$os" = Darwin ] && [ "$arch" = x86_64 ] \
        && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = 1 ]; then
        arch=arm64
    fi
    case "$os/$arch" in
        Linux/x86_64 | Linux/amd64) echo "x86_64-unknown-linux-musl" ;;
        Darwin/arm64 | Darwin/aarch64) echo "aarch64-apple-darwin" ;;
        Darwin/x86_64) echo "x86_64-apple-darwin" ;;
        *) err "prebuilt kaffy binaries are available for Linux x86_64 and macOS (this machine is $os/$arch)" ;;
    esac
}

main() {
    has tar || err "need tar to unpack kaffy"
    target=$(detect_target)

    version="${KAFFY_VERSION:-}"
    if [ -z "$version" ]; then
        version=$(fetch "$RELEASES_URL/latest.txt") || err "could not look up the latest version"
    fi
    case "$version" in
        v[0-9]*) ;;
        [0-9]*) version="v$version" ;;
        *) err "unexpected version '$version'" ;;
    esac

    install_dir="${KAFFY_INSTALL_DIR:-$HOME/.local/bin}"
    archive="kaffy-$version-$target.tar.gz"
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT INT TERM

    say "downloading kaffy $version for $target"
    if ! fetch "$RELEASES_URL/$version/$archive" "$tmp/$archive" 2>/dev/null; then
        # Releases before v0.4.0 had a single glibc build for Linux.
        if [ "$target" = x86_64-unknown-linux-musl ]; then
            target=x86_64-unknown-linux-gnu
            archive="kaffy-$version-$target.tar.gz"
            say "no static build for $version; trying $target (needs glibc 2.35+)"
            fetch "$RELEASES_URL/$version/$archive" "$tmp/$archive" \
                || err "download failed: $RELEASES_URL/$version/$archive"
        else
            err "no $target build of kaffy $version (macOS builds start at v0.4.0)"
        fi
    fi
    fetch "$RELEASES_URL/$version/$archive.sha256" "$tmp/$archive.sha256" \
        || err "checksum download failed"

    expected=$(cut -d' ' -f1 "$tmp/$archive.sha256")
    actual=$(sha256 "$tmp/$archive")
    [ "$expected" = "$actual" ] || err "checksum mismatch for $archive (expected $expected, got $actual)"

    tar -xzf "$tmp/$archive" -C "$tmp"
    mkdir -p "$install_dir"
    # Copy then rename, so a running kaffy is never overwritten in place.
    cp "$tmp/kaffy-$version-$target/kaffy" "$install_dir/.kaffy.new"
    chmod 755 "$install_dir/.kaffy.new"
    mv -f "$install_dir/.kaffy.new" "$install_dir/kaffy"

    say "installed $("$install_dir/kaffy" --version) to $install_dir/kaffy"
    case ":$PATH:" in
        *":$install_dir:"*) ;;
        *)
            say "$install_dir is not on your PATH; add this to your shell profile:"
            printf '\n    export PATH="%s:$PATH"\n\n' "$install_dir"
            ;;
    esac
    say "try it without a broker:  kaffy --demo"
    say "or connect to one:        kaffy --bootstrap localhost:9092"
}

main "$@"
