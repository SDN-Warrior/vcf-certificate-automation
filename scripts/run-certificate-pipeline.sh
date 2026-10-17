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
# Read appliance type from the certificate definition and select the
# appropriate VCF certificate pipeline.
#
# VCF component pipeline:
#   VCENTER
#   SDDC_MANAGER
#   NSXT_MANAGER
#
# VCF management pipeline:
#   VCF_AUTOMATION
#   LOG_MANAGEMENT
#   VCF_OPERATIONS
#   VCF_OPS_NETWORK
#   IDENTITY_BROKER
#   VCF_OPS_HCX
#   ESX
#   VCF_SERVICES_RUNTIME
#   AVI_LOAD_BALANCER
# ---------------------------------------------------------------------------

PIPELINE_INFO="$(
  python3 - "${CERTIFICATE_FILE}" <<'PY'
import sys
import yaml

certificate_file = sys.argv[1]

component_appliances = {
    "VCENTER",
    "SDDC_MANAGER",
    "NSXT_MANAGER",
}

management_appliances = {
    "VCF_AUTOMATION",
    "LOG_MANAGEMENT",
    "VCF_OPERATIONS",
    "VCF_OPS_NETWORK",
    "IDENTITY_BROKER",
    "VCF_OPS_HCX",
    "ESX",
    "VCF_SERVICES_RUNTIME",
    "AVI_LOAD_BALANCER",
}

with open(certificate_file, "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

if not isinstance(data, dict):
    raise SystemExit("ERROR: Invalid certificate YAML root")

certificate = data.get("certificate")

if not isinstance(certificate, dict):
    raise SystemExit("ERROR: Missing certificate definition")

deployment = certificate.get("deployment")

if not isinstance(deployment, dict):
    raise SystemExit("ERROR: Missing deployment definition")

appliance = deployment.get("appliance")

if not isinstance(appliance, str) or not appliance:
    raise SystemExit("ERROR: Missing deployment.appliance")

if appliance in component_appliances:
    playbook = "ansible/playbooks/vcf-certificate.yml"
    pipeline = "VCF component"

elif appliance in management_appliances:
    playbook = "ansible/playbooks/vcf-management-certificate.yml"
    pipeline = "VCF management"

else:
    raise SystemExit(
        f"ERROR: Unsupported VCF appliance type: {appliance}"
    )

print(appliance)
print(playbook)
print(pipeline)
PY
)"

mapfile -t PIPELINE_DATA <<< "${PIPELINE_INFO}"

APPLIANCE="${PIPELINE_DATA[0]}"
CERTIFICATE_PLAYBOOK="${PIPELINE_DATA[1]}"
PIPELINE="${PIPELINE_DATA[2]}"

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

if ansible-playbook \
  "${CERTIFICATE_PLAYBOOK}" \
  --vault-password-file /etc/vcf-certmanager/vault-pass \
  -e "certificate_name=${CERTIFICATE_NAME}"
then
  echo
  echo "=================================================="
  echo "Post-replacement settling period"
  echo "=================================================="
  echo "Certificate : ${CERTIFICATE_NAME}"
  echo "Waiting     : 180 seconds"
  echo "Reason      : allow VCF Operations background tasks to complete"
  echo "=================================================="

  sleep 180

  echo
  echo "Post-replacement settling period completed."
else
  PIPELINE_RC=$?

  echo
  echo "=================================================="
  echo "Certificate pipeline failed"
  echo "=================================================="
  echo "Certificate : ${CERTIFICATE_NAME}"
  echo "Exit code   : ${PIPELINE_RC}"
  echo "No settling period will be started."
  echo "=================================================="

  exit "${PIPELINE_RC}"
fi
