#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift.org open source project
##
## Copyright (c) 2025 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0 with Runtime Library Exception
##
## See https://swift.org/LICENSE.txt for license information
## See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
##
##===----------------------------------------------------------------------===##

set -euo pipefail

log() { printf -- "** %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

# Detect OS from /etc/os-release
detect_os_info() {
    if [[ ! -f /etc/os-release ]]; then
        fatal "Cannot detect OS: /etc/os-release not found"
    fi

    local os_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
    local version_id=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

    if [[ -z "$os_id" || -z "$version_id" ]]; then
        fatal "Could not parse OS information from /etc/os-release"
    fi

    # Create both formats
    local os_name="${os_id}$(echo "$version_id" | tr -d '.')"
    local os_dotted="${os_id}${version_id}"

    log "Detected OS from /etc/os-release: $os_name (dotted: $os_dotted)"

    echo "$os_name|$os_dotted"
}

OS_INFO=$(detect_os_info)
OS_NAME=$(echo "$OS_INFO" | cut -d'|' -f1)
OS_DOTTED_VERSION=$(echo "$OS_INFO" | cut -d'|' -f2)

log "Using OS: $OS_NAME"
log "Dotted version of OS for filenames: $OS_DOTTED_VERSION"

# Detect architecture to adjust platform name if needed
ARCH=$(uname -m)
ARCH_SUFFIX=""
if [[ "$ARCH" == "aarch64" ]]; then
    ARCH_SUFFIX="-aarch64"
    log "Detected aarch64 architecture, using suffix: $ARCH_SUFFIX"
else
    log "Detected $ARCH architecture, using no suffix"
fi

# Install curl if not already installed
check_and_install_tools() {
    if ! which curl >/dev/null 2>&1; then
        log "Installing required tools: curl"
        apt -q update && apt -yq install curl
    fi
}

SWIFT_WEBROOT="https://download.swift.org/swift-6.2-branch"
PLATFORM_NAME="${OS_NAME}${ARCH_SUFFIX}"
PLATFORM_WEBROOT="${SWIFT_WEBROOT}/${PLATFORM_NAME}"
STATIC_SDK_WEBROOT="${SWIFT_WEBROOT}/static-sdk"

# Directory for extracted toolchain (if needed to match the static SDK)
TOOLCHAIN_DIR="${HOME}/.swift-toolchains"

# Get current Swift version from /.swift_tag
get_current_swift_version() {
    # Check /.swift_tag file
    if [[ -f "/.swift_tag" ]]; then
        local swift_tag=$(cat /.swift_tag | tr -d '\n' | tr -d ' ')
        if [[ -n "$swift_tag" ]]; then
            log "Found Swift tag in /.swift_tag: $swift_tag"
            echo "$swift_tag"
            return 0
        fi
    fi

    log "No Swift tag found in /.swift_tag"
    echo "none"
}

parse_yaml_value() {
    local key="$1"
    local content="$2"
    echo "$content" | grep "^${key}:" | sed "s/^${key}:[[:space:]]*//"
}

download_and_verify() {
    local url="$1"
    local sig_url="$2"
    local output_file="$3"
    local temp_sig="${output_file}.sig"

    log "Downloading ${url##*/}"
    curl -fsSL "$url" -o "$output_file"

    log "Downloading signature"
    curl -fsSL "$sig_url" -o "$temp_sig"

    log "Setting up GPG for verification"
    export GNUPGHOME="$(mktemp -d)"
    curl -fSsL https://swift.org/keys/all-keys.asc | zcat -f | gpg --import - >/dev/null 2>&1

    log "Verifying signature"
    if gpg --batch --verify "$temp_sig" "$output_file" >/dev/null 2>&1; then
        log "✅ Signature verification successful"
    else
        fatal "Signature verification failed"
    fi

    rm -rf "$GNUPGHOME" "$temp_sig"
}

# Uses the static SDK snapshot name to find the correct toolchain snapshot
# E.g. takes "swift-6.2-DEVELOPMENT-SNAPSHOT-2025-07-22-a" as input
download_and_extract_toolchain() {
    local dir_name="$1"

    log "Downloading Swift toolchain: $dir_name"

    # "swift-6.2-DEVELOPMENT-SNAPSHOT-2025-07-22-a-ubuntu22.04.tar.gz"
    # "swift-6.2-DEVELOPMENT-SNAPSHOT-2025-07-22-a-ubuntu22.04.tar.gz.sig"
    local toolchain_filename="${dir_name}-${OS_DOTTED_VERSION}${ARCH_SUFFIX}.tar.gz"
    local toolchain_sig_filename="${toolchain_filename}.sig"

    local toolchain_url="${PLATFORM_WEBROOT}/${dir_name}/${toolchain_filename}"
    local toolchain_sig_url="${PLATFORM_WEBROOT}/${dir_name}/${toolchain_sig_filename}"

    # Check if toolchain is available
    local http_code=$(curl -sSL --head -w "%{http_code}" -o /dev/null "$toolchain_url")
    if [[ "$http_code" == "404" ]]; then
        log "❌ Toolchain not found: ${toolchain_url##*/}"
        log "Exiting workflow..."
        # Don't fail the workflow if we can't find the right toolchain
        exit 0
    fi

    # Create toolchain directory
    mkdir -p "$TOOLCHAIN_DIR"
    local toolchain_path="${TOOLCHAIN_DIR}/${dir_name}"

    # Check if toolchain already exists
    if [[ -d "$toolchain_path" && -f "${toolchain_path}/usr/bin/swift" ]]; then
        log "Toolchain already exists at: $toolchain_path"
        echo "$toolchain_path/usr/bin/swift"
        return 0
    fi

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local toolchain_file="${temp_dir}/swift_toolchain.tar.gz"

    # Download and verify toolchain
    download_and_verify "$toolchain_url" "$toolchain_sig_url" "$toolchain_file"

    log "Extracting toolchain to: $toolchain_path"
    mkdir -p "$toolchain_path"
    tar -xzf "$toolchain_file" --directory "$toolchain_path" --strip-components=1

    # Clean up
    rm -rf "$temp_dir"

    local swift_executable="${toolchain_path}/usr/bin/swift"
    if [[ -f "$swift_executable" ]]; then
        log "✅ Swift toolchain extracted successfully"
        echo "$swift_executable"
    else
        fatal "Swift executable not found at expected path: $swift_executable"
    fi
}

install_static_sdk() {
    local sdk_info="$1"
    local swift_executable="$2"
    local download_name=$(parse_yaml_value "download" "$sdk_info")
    local dir_name=$(parse_yaml_value "dir" "$sdk_info")
    local checksum=$(parse_yaml_value "checksum" "$sdk_info")

    # Check if the static SDK is already installed
    if "$swift_executable" sdk list 2>/dev/null | grep -q "^$dir_name"; then
        log "✅ Static SDK $dir_name is already installed, skipping installation"
        return 0
    fi

    log "Installing Swift Static SDK: $dir_name"

    local sdk_url="${STATIC_SDK_WEBROOT}/${dir_name}/${download_name}"

    log "Running: ${swift_executable} sdk install ${sdk_url} --checksum $checksum"

    if "$swift_executable" sdk install "$sdk_url" --checksum "$checksum"; then
        log "✅ Static SDK installed successfully"
    else
        fatal "Failed to install static SDK"
    fi
}

get_static_sdk_name() {
    local sdk_info="$1"
    local download_name=$(parse_yaml_value "download" "$sdk_info")
    # Note: we want to keep the "_static-linux-0.0.1"
    echo "$download_name" | sed 's/\.artifactbundle\.tar\.gz$//'
}

run_swift_static_sdk_build() {
    local swift_executable="$1"
    local sdk_name="$2"

    log "Running Swift build with static SDK"
    log "Command: $swift_executable build --swift-sdk $sdk_name"

    if "$swift_executable" build --swift-sdk "$sdk_name"; then
        log "✅ Swift build with static SDK completed successfully"
    else
        fatal "Swift build with static SDK failed"
    fi
}

main() {
    log "Starting Swift 6.2 Static SDK and Toolchain setup for $OS_NAME"
    log "Platform URL: $PLATFORM_WEBROOT"

    check_and_install_tools

    local current_swift_version=$(get_current_swift_version)
    log "Current Swift version: $current_swift_version"

    log "Fetching latest 6.2 static SDK information"
    local sdk_info
    if ! sdk_info=$(curl -fsSL "${STATIC_SDK_WEBROOT}/latest-build.yml"); then
        fatal "Failed to fetch static SDK information"
    fi

    local sdk_dir=$(parse_yaml_value "dir" "$sdk_info")
    local sdk_checksum=$(parse_yaml_value "checksum" "$sdk_info")

    log "Latest static SDK: $sdk_dir"
    log "Static SDK checksum: ${sdk_checksum:0:16}..."

    local swift_executable=""
    local sdk_name=""

    # Check if current Swift version matches the static SDK version
    if [[ "$current_swift_version" == "$sdk_dir" ]]; then
        log "✅ Current Swift version matches latest static SDK version"
        log "Using system Swift and installing static SDK"

        swift_executable="swift"
        install_static_sdk "$sdk_info" "$swift_executable"
        sdk_name=$(get_static_sdk_name "$sdk_info")

    else
        # Either no Swift or version mismatch, so download matching toolchain
        if [[ "$current_swift_version" == "none" ]]; then
            log "No Swift installation detected"
        else
            log "Current Swift version ($current_swift_version) does not match latest static SDK ($sdk_dir)"
        fi

        log "Downloading matching toolchain and installing static SDK"

        # Download the toolchain that matches the static SDK snapshot name
        swift_executable=$(download_and_extract_toolchain "$sdk_dir")
        install_static_sdk "$sdk_info" "$swift_executable"
        sdk_name=$(get_static_sdk_name "$sdk_info")
    fi

    # Uncomment to save paths to files for other scripting
    # echo "$swift_executable" > swift_executable_path.txt
    # echo "$sdk_name" > static_sdk_name.txt

    # log "Paths saved to:"
    # log "  swift_executable_path.txt"
    # log "  static_sdk_name.txt"

    # Run Swift build with static SDK
    log ""
    run_swift_static_sdk_build "$swift_executable" "$sdk_name"

    # Success
    log ""
    log "✅ Setup and build completed successfully!"
    log ""
    log "Swift executable path: $swift_executable"
    log "Static SDK name: $sdk_name"
    log ""
    log "To run manually:"
    log "  $swift_executable build --swift-sdk $sdk_name"

}

main "$@"
