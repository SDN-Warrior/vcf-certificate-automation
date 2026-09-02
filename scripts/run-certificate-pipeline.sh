#!/usr/bin/env bash

set -euo pipefail

CERTIFICATE_NAME="${1:?Certificate name missing}"
CERTIFICATE_FILE="certificates/${CERTIFICATE_NAME}.yml"

if [[ ! -f "${CERTIFICATE_FILE}" ]]; then
  echo "ERROR: Certificate definition not found:"
  echo "       ${CERTIFICATE_FILE}"
  exit 1
fi

# ---------------------------------------------------------------------------
# Read deployment type from certificate definition.
# ---------------------------------------------------------------------------

APPLIANCE="$(
  python3 - "${CERTIFICATE_FILE}" <<'PY'
import sys
import yaml

certificate_file = sys.argv[1]

with open(certificate_file, "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

if not isinstance(data, dict):
    raise SystemExit("Invalid certificate YAML root")

certificate = data.get("certificate")

if not isinstance(certificate, dict):
    raise SystemExit("Missing certificate definition")

deployment = certificate.get("deployment")

if not isinstance(deployment, dict):
    raise SystemExit("Missing deployment definition")

appliance = deployment.get("appliance")

if not isinstance(appliance, str) or not appliance:
    raise SystemExit("Missing deployment.appliance")

print(appliance)
PY
)"

# ---------------------------------------------------------------------------
# Select certificate pipeline.
#
# Existing VCF component path:
#
#   VCENTER
#   SDDC_MANAGER
#   NSXT_MANAGER
#
# New VCF Management path:
#
#   VCF_OPERATIONS
#   IDENTITY_BROKER
#   VCF_SERVICES_RUNTIME
# ---------------------------------------------------------------------------

case "${APPLIANCE}" in

  VCENTER|SDDC_MANAGER|NSXT_MANAGER)

    CERTIFICATE_PLAYBOOK="ansible/playbooks/vcf-certificate.yml"
    PIPELINE="VCF component"

    ;;

  VCF_OPERATIONS|IDENTITY_BROKER|VCF_SERVICES_RUNTIME|ESX)

    CERTIFICATE_PLAYBOOK="ansible/playbooks/vcf-management-certificate.yml"
    PIPELINE="VCF management"

    ;;

  *)

    echo "ERROR: Unsupported VCF appliance type:"
    echo "       ${APPLIANCE}"
    exit 1

    ;;

esac

if [[ ! -f "${CERTIFICATE_PLAYBOOK}" ]]; then
  echo "ERROR: Certificate playbook not found:"
  echo "       ${CERTIFICATE_PLAYBOOK}"
  exit 1
fi

echo
echo "=================================================="
echo "Certificate pipeline selection"
echo "=================================================="
echo "Certificate : ${CERTIFICATE_NAME}"
echo "Appliance   : ${APPLIANCE}"
echo "Pipeline    : ${PIPELINE}"
echo "Playbook    : ${CERTIFICATE_PLAYBOOK}"
echo "=================================================="
echo

exec ansible-playbook \
  "${CERTIFICATE_PLAYBOOK}" \
  --vault-password-file /etc/vcf-certmanager/vault-pass \
  -e "certificate_name=${CERTIFICATE_NAME}"
