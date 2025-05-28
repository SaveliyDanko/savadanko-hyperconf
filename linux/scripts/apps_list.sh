#!/usr/bin/env bash


set -euo pipefail


# ------------------------
# ARGUMENT PARSING
# ------------------------
OUTPUT_FILE=""
OUTPUT_FORMAT="text"

for arg in "$@"; do
  case "$arg" in
    --file=*)
      OUTPUT_FILE="${arg#*=}"
      ;;
    --json)
      OUTPUT_FORMAT="json"
      ;;
    *)
      echo "[ERROR] Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done


# ------------------------
# COLLECTED OUTPUT
# ------------------------
declare -A RESULTS

# ------------------------
# FUNCTIONS
# ------------------------
check_distro_and_list_manual_packages() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    RESULTS["distribution"]="$PRETTY_NAME"
    RESULTS["kernel"]="$(uname -r)"
    if [[ "$ID" == "ubuntu" ]]; then
      RESULTS["manual_apt"]="$(apt-mark showmanual | sort)"
    else
      RESULTS["manual_apt"]="Not Ubuntu ($PRETTY_NAME), skipping apt-mark"
    fi
  else
    RESULTS["distribution"]="Unknown"
    RESULTS["manual_apt"]="Cannot determine distro: missing /etc/os-release"
  fi
}


list_snap_packages() {
  if command -v snap &>/dev/null; then
    RESULTS["snap"]="$(snap list | tail -n +2)"
  else
    RESULTS["snap"]="Snap is not installed"
  fi
}


list_flatpak_packages() {
  if command -v flatpak &>/dev/null; then
    RESULTS["flatpak"]="$(flatpak list)"
  else
    RESULTS["flatpak"]="Flatpak is not installed"
  fi
}


# ------------------------
# EXECUTE
# ------------------------
OS_NAME=$(source /etc/os-release && echo "$NAME")
OS_VERSION=$(source /etc/os-release && echo "$VERSION")
KERNEL_VERSION=$(uname -r)

echo "[INFO] OS: $OS_NAME $OS_VERSION"
echo "[INFO] Kernel: Linux $KERNEL_VERSION"

check_distro_and_list_manual_packages
list_snap_packages
list_flatpak_packages

# ------------------------
# OUTPUT LOGIC
# ------------------------

output_text() {
  echo "[INFO] Distribution: ${RESULTS["distribution"]:-Unknown}"
  echo "[INFO] Kernel: ${RESULTS["kernel"]:-Unknown}"
  echo -e "\n[MANUAL APT PACKAGES]"
  echo "${RESULTS["manual_apt"]:-None}"

  echo -e "\n[SNAP PACKAGES]"
  echo "${RESULTS["snap"]:-None}"

  echo -e "\n[FLATPAK PACKAGES]"
  echo "${RESULTS["flatpak"]:-None}"
}

output_json() {
  {
    echo "{"
    echo "  \"distribution\": \"${RESULTS["distribution"]}\","
    echo "  \"kernel\": \"${RESULTS["kernel"]}\","
    echo "  \"manual_apt\": ["
    echo "${RESULTS["manual_apt"]}" | awk '{printf "    \"%s\",\n", $0}' | sed '$s/,$//'
    echo "  ],"
    echo "  \"snap\": ["
    echo "${RESULTS["snap"]}" | awk '{printf "    \"%s\",\n", $0}' | sed '$s/,$//'
    echo "  ],"
    echo "  \"flatpak\": ["
    echo "${RESULTS["flatpak"]}" | awk '{printf "    \"%s\",\n", $0}' | sed '$s/,$//'
    echo "  ]"
    echo "}"
  }
}

# ------------------------
# PRINT OR SAVE
# ------------------------

if [[ -n "$OUTPUT_FILE" ]]; then
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    output_json > "$OUTPUT_FILE"
  else
    output_text > "$OUTPUT_FILE"
  fi
  echo "[INFO] Output saved to $OUTPUT_FILE"
else
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    output_json
  else
    output_text
  fi
fi
