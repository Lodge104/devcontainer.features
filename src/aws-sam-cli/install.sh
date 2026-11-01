#!/bin/sh
#-------------------------------------------------------------------------------------------------------------
# Installs the AWS SAM CLI, picking the install method from the detected OS, CPU architecture and libc.
#
# Docs: https://github.com/Lodge104/devcontainer.features/tree/main/src/aws-sam-cli
#
# Syntax: ./install.sh
#-------------------------------------------------------------------------------------------------------------

set -e

SAM_VERSION="${VERSION:-"latest"}"
INSTALL_CFN_LINT="${INSTALLCFNLINT:-"true"}"
CFN_LINT_VENV="/usr/local/cfn-lint-venv"

INSTALL_DIR="/usr/local/aws-sam-cli"
BIN_DIR="/usr/local/bin"
RELEASES_URL="https://github.com/aws/aws-sam-cli/releases"
PIP_INSTALL_DIR="/usr/local/aws-sam-cli-venv"

if [ "$(id -u)" -ne 0 ]; then
    printf '%s\n' 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# --- Platform detection ------------------------------------------------------------------------------------

detect_os() {
    local os
    os="$(uname -s)"
    case "${os}" in
        Linux) echo "linux" ;;
        *)
            echo "(!) Unsupported operating system '${os}'. Dev container features run on Linux."
            exit 1
            ;;
    esac
}

detect_arch() {
    local machine
    machine="$(uname -m)"
    case "${machine}" in
        x86_64 | amd64) echo "x86_64" ;;
        aarch64 | arm64) echo "arm64" ;;
        *)
            echo "(!) Unsupported architecture '${machine}'. AWS SAM CLI supports x86_64 and arm64."
            exit 1
            ;;
    esac
}

# Returns 0 when running on a musl-based distro (e.g. Alpine), where the official glibc build cannot run.
is_musl() {
    if [ -f /etc/alpine-release ]; then
        return 0
    fi
    if command -v ldd > /dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl; then
        return 0
    fi
    return 1
}

detect_pkg_manager() {
    if command -v apt-get > /dev/null 2>&1; then
        echo "apt-get"
    elif command -v apk > /dev/null 2>&1; then
        echo "apk"
    elif command -v dnf > /dev/null 2>&1; then
        echo "dnf"
    elif command -v microdnf > /dev/null 2>&1; then
        echo "microdnf"
    elif command -v yum > /dev/null 2>&1; then
        echo "yum"
    elif command -v zypper > /dev/null 2>&1; then
        echo "zypper"
    else
        echo "none"
    fi
}

# --- Package helpers ---------------------------------------------------------------------------------------

PKG_MANAGER="$(detect_pkg_manager)"
APT_UPDATED="false"

# Installs the given packages with whatever package manager is available.
pkg_install() {
    case "${PKG_MANAGER}" in
        apt-get)
            if [ "${APT_UPDATED}" != "true" ]; then
                echo "Running apt-get update..."
                apt-get update -y
                APT_UPDATED="true"
            fi
            DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends "$@"
            ;;
        apk)
            apk add --no-cache "$@"
            ;;
        dnf)
            dnf -y install "$@"
            ;;
        microdnf)
            microdnf -y install "$@"
            ;;
        yum)
            yum -y install "$@"
            ;;
        zypper)
            zypper --non-interactive install "$@"
            ;;
        *)
            echo "(!) No supported package manager found. Please install the following manually: $*"
            exit 1
            ;;
    esac
}

pkg_cleanup() {
    case "${PKG_MANAGER}" in
        apt-get)  rm -rf /var/lib/apt/lists/* ;;
        dnf)      dnf clean all ;;
        microdnf) microdnf clean all ;;
        yum)      yum clean all ;;
        zypper)   zypper clean --all ;;
    esac
}

# Installs the given commands' packages only when the command is missing.
# Usage: ensure_command <command> [package]
ensure_command() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if ! command -v "${cmd}" > /dev/null 2>&1; then
        pkg_install "${pkg}"
    fi
}

ensure_ca_certificates() {
    if [ ! -d /etc/ssl/certs ] || [ -z "$(ls -A /etc/ssl/certs 2> /dev/null)" ]; then
        pkg_install ca-certificates
    fi
}

# --- Installers --------------------------------------------------------------------------------------------

# Official zip installer (glibc). https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
install_from_zip() {
    local arch="$1"
    local zip_name="aws-sam-cli-linux-${arch}.zip"
    local url tmp_dir

    if [ "${SAM_VERSION}" = "latest" ]; then
        url="${RELEASES_URL}/latest/download/${zip_name}"
    else
        url="${RELEASES_URL}/download/v${SAM_VERSION#v}/${zip_name}"
    fi

    ensure_ca_certificates
    ensure_command curl
    ensure_command unzip

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' EXIT

    echo "Downloading ${url}..."
    curl -fsSL --retry 3 --retry-delay 2 -o "${tmp_dir}/${zip_name}" "${url}"
    unzip -q "${tmp_dir}/${zip_name}" -d "${tmp_dir}/sam-installation"

    local update_flag=""
    if [ -x "${INSTALL_DIR}/current/bin/sam" ] || [ -d "${INSTALL_DIR}" ]; then
        update_flag="--update"
    fi

    # shellcheck disable=SC2086
    "${tmp_dir}/sam-installation/install" \
        --install-dir "${INSTALL_DIR}" \
        --bin-dir "${BIN_DIR}" \
        ${update_flag}

    rm -rf "${tmp_dir}"
    trap - EXIT
}

# Fallback for musl-based distros (Alpine), where the official bundled binary cannot run.
install_from_pip() {
    echo "musl-based distro detected; installing AWS SAM CLI from PyPI instead of the official zip."

    if ! command -v python3 > /dev/null 2>&1 || ! python3 -m venv --help > /dev/null 2>&1; then
        case "${PKG_MANAGER}" in
            apk) pkg_install python3 py3-pip ;;
            *)   pkg_install python3 ;;
        esac
    fi

    python3 -m venv "${PIP_INSTALL_DIR}"
    "${PIP_INSTALL_DIR}/bin/pip" install --no-cache-dir --upgrade pip

    if [ "${SAM_VERSION}" = "latest" ]; then
        "${PIP_INSTALL_DIR}/bin/pip" install --no-cache-dir --upgrade aws-sam-cli
    else
        "${PIP_INSTALL_DIR}/bin/pip" install --no-cache-dir "aws-sam-cli==${SAM_VERSION#v}"
    fi

    ln -sf "${PIP_INSTALL_DIR}/bin/sam" "${BIN_DIR}/sam"
}

# Installs cfn-lint into its own venv so it does not conflict with SAM CLI's dependencies.
install_cfn_lint() {
    echo "Installing cfn-lint..."
    local venv_check_dir
    local venv_ready="false"
    if command -v python3 > /dev/null 2>&1; then
        venv_check_dir="$(mktemp -d)"
        if python3 -m venv "${venv_check_dir}/venv" > /dev/null 2>&1; then
            venv_ready="true"
        fi
        rm -rf "${venv_check_dir}"
    fi

    if [ "${venv_ready}" != "true" ]; then
        case "${PKG_MANAGER}" in
            apk) pkg_install python3 py3-pip ;;
            apt-get) pkg_install python3 python3-venv python3-pip ;;
            *)   pkg_install python3 ;;
        esac
    fi

    python3 -m venv "${CFN_LINT_VENV}"
    "${CFN_LINT_VENV}/bin/pip" install --no-cache-dir --upgrade pip
    "${CFN_LINT_VENV}/bin/pip" install --no-cache-dir --upgrade cfn-lint
    ln -sf "${CFN_LINT_VENV}/bin/cfn-lint" "${BIN_DIR}/cfn-lint"
}

# --- Main --------------------------------------------------------------------------------------------------

OS="$(detect_os)"
ARCH="$(detect_arch)"
echo "Detected: os=${OS} arch=${ARCH} pkg-manager=${PKG_MANAGER} version=${SAM_VERSION}"

if is_musl; then
    install_from_pip
else
    install_from_zip "${ARCH}"
fi

if [ "${INSTALL_CFN_LINT}" = "true" ]; then
    install_cfn_lint
fi

pkg_cleanup

echo "Verifying installation..."
sam --version
if [ "${INSTALL_CFN_LINT}" = "true" ]; then
    cfn-lint --version
fi

echo "Done!"
