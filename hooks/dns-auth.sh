#!/usr/bin/env bash
set -euo pipefail

CERTIFICATE_NAME="${1:?Certificate name missing}"

: "${CERTBOT_DOMAIN:?CERTBOT_DOMAIN missing}"
: "${CERTBOT_VALIDATION:?CERTBOT_VALIDATION missing}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

/usr/bin/ansible-playbook \
  "${REPO_ROOT}/ansible/playbooks/dns-challenge.yml" \
  --vault-password-file /etc/vcf-certmanager/vault-pass \
  -e "certificate_name=${CERTIFICATE_NAME}" \
  -e "dns_action=present" \
  -e "dns_identifier=${CERTBOT_DOMAIN}" \
  -e "dns_token=${CERTBOT_VALIDATION}"
