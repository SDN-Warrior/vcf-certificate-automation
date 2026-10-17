# Changelog

All notable changes to C.E.R.B.E.R.U.S. are documented in this file.

---

## [v1.0.3] - 2026-10-17

### Installing ISRG Root YR

C.E.R.B.E.R.U.S. uses the self-signed ISRG Root YR certificate
as the trust anchor for the selected Let's Encrypt Generation Y chain.

The certificate must exist locally on the CertManager because
the certificate definitions reference it through `deployment.root_ca_file`.

Download the official self-signed certificate from Let's Encrypt:

https://letsencrypt.org/certs/gen-y/root-yr.pem

Install and verify the certificate on the CertManager:

~~bash
curl -fsSL \
  https://letsencrypt.org/certs/gen-y/root-yr.pem \
  -o /tmp/ISRG_Root_YR.pem

EXPECTED="E5:7B:7E:6F:15:0C:41:91:02:E8:D5:C0:55:72:9F:F9:67:B9:D1:A8:29:BF:00:CE:C8:9C:A6:04:EB:F4:A8:6F"

ACTUAL=$(
  openssl x509 \
    -in /tmp/ISRG_Root_YR.pem \
    -noout -fingerprint -sha256 |
    cut -d= -f2
)

if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "ERROR: Unexpected Root CA fingerprint"
  exit 1
fi

sudo install -m 0644 \
  /tmp/ISRG_Root_YR.pem \
  /etc/ssl/certs/ISRG_Root_YR.pem

openssl x509 \
  -in /etc/ssl/certs/ISRG_Root_YR.pem \
  -noout -subject -issuer -fingerprint -sha256
~~

The expected subject and issuer are identical:
`C=US, O=ISRG, CN=Root YR`.

Use the self-signed Root YR certificate, not the variant
cross-signed by ISRG Root X1.

No modification of the Ubuntu system trust store is required
solely to provide this certificate file to the pipeline.

Configure Certbot in `/etc/letsencrypt/cli.ini`:

~~ini
preferred-chain = Root YR
~~

Certificate definitions must reference:

~~yaml
deployment:
  root_ca_file: /etc/ssl/certs/ISRG_Root_YR.pem
~~

Target VCF components may require separate CA trust registration.
The local file does not automatically establish trust on remote appliances.

Note that Certbot's `preferred-chain` setting is a preference;
the returned chain must still be verified.


### Changed

- Added a 180-second settling period after each successful certificate replacement.
- Allow VCF Operations background tasks to complete before continuing.
- Improved certificate chain validation using the configured root CA.
- Updated certificate definitions to use ISRG Root YR.
- Ansible failures are propagated without starting the settling timer.

### Configuration

For Let's Encrypt Generation Y certificates, configure Certbot in /etc/letsencrypt/cli.ini:

    preferred-chain = Root YR

The ISRG Root YR certificate must be available on the CertManager host:

    /etc/ssl/certs/ISRG_Root_YR.pem

### Downloading and Installing ISRG Root YR

The self-signed ISRG Root YR certificate must be downloaded and stored
locally on the CertManager host before running the certificate pipeline.

Official Let's Encrypt certificate source:
https://letsencrypt.org/certificates/

Download the self-signed ISRG Root YR certificate, validate its SHA-256
fingerprint, and install it at the location expected by C.E.R.B.E.R.U.S.:

~~bash
set -e

curl -fsSL \
  https://letsencrypt.org/certs/gen-y/root-yr.pem \
  -o /tmp/ISRG_Root_YR.pem

EXPECTED="E5:7B:7E:6F:15:0C:41:91:02:E8:D5:C0:55:72:9F:F9:67:B9:D1:A8:29:BF:00:CE:C8:9C:A6:04:EB:F4:A8:6F"

ACTUAL=$(
  openssl x509 -in /tmp/ISRG_Root_YR.pem \
    -noout -fingerprint -sha256 | cut -d= -f2
)

if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "ERROR: Unexpected Root CA fingerprint"
  exit 1
fi

sudo install -m 0644 \
  /tmp/ISRG_Root_YR.pem \
  /etc/ssl/certs/ISRG_Root_YR.pem

rm -f /tmp/ISRG_Root_YR.pem
~~

The expected certificate subject is `C=US, O=ISRG, CN=Root YR`.

Use the self-signed Root YR certificate rather than the certificate
cross-signed by ISRG Root X1.

Adding the certificate to the operating system's global trust store
is not required solely for the C.E.R.B.E.R.U.S. pipeline. However,
target VCF components may require separate trust configuration.

Certbot's `preferred-chain` setting is a preference, not a guarantee.
Always validate the resulting certificate chain.

Certificate definitions use:

    deployment:
      root_ca_file: /etc/ssl/certs/ISRG_Root_YR.pem

### Known Issues

- In the tested VCF 9.1.1 environment, SSO integration with an external vIDB deployed on a VCF Services Cluster fails with certificate_unknown(46) when using Let's Encrypt certificates.
- SSO with the embedded vCenter vIDB works in the tested environment.
- The external vIDB issue remains under investigation.
- Cloud Proxy and Cert Manager certificate replacement are not yet supported.

## [v1.0.2] - 2026-09-07

### Added

* Added support for additional appliance types exposed through the VCF Operations Fleet Certificate Management API:

  * `VCF_AUTOMATION`
  * `LOG_MANAGEMENT`
  * `VCF_OPERATIONS`
  * `VCF_OPS_NETWORK`
  * `IDENTITY_BROKER`
  * `VCF_OPS_HCX`
  * `ESX`
  * `VCF_SERVICES_RUNTIME`
  * `AVI_LOAD_BALANCER`
* Added certificate definition for VCF Operations for Logs using `LOG_MANAGEMENT`.

### Changed

* Refactored the certificate pipeline dispatcher.
* Centralized appliance type selection and routing between the VCF Component and VCF Management certificate pipelines.
* Extended the VCF Management CSR validation to accept the additional Fleet Certificate Management appliance types.

### Notes

* `LOG_MANAGEMENT` uses the existing VCF Management certificate pipeline.
* Not every newly added appliance type has been tested in the development lab yet. Support means that the appliance type is exposed through the existing VCF Operations Fleet Certificate Management API path used by C.E.R.B.E.R.U.S.
* Components requiring different certificate APIs, such as Cloud Proxy and License Server, are not included.

---

## [v1.0.1] - 2026-09-03

### Fixed

* Fixed CSR selection when VCF Operations returns multiple CSR objects for the same endpoint.
* CSR matching now prefers the `certificateId` returned by VCF Operations.
* Retained the previous matching behavior as a fallback for VCF 9.1 API responses that do not expose `certificateId`.

### Compatibility

* Tested with VCF 9.1.1.
* Maintains compatibility with the VCF 9.1 certificate workflow.

---

## [v1.0.0] - 2026-09-02

### Added

* Initial public release of C.E.R.B.E.R.U.S.
* Git-driven certificate lifecycle management for VMware Cloud Foundation 9.1.
* Automated CSR generation through VCF Operations.
* Let's Encrypt certificate issuance using ACME.
* Cloudflare DNS-01 challenge support.
* Experimental Microsoft AD CS / ACME Bridge implementation with Windows DNS.
* Separate certificate definitions using YAML files.
* Automatic processing of newly added certificate definitions through Gitea Actions.
* Scheduled certificate renewal based on the configured renewal window.
* Manual forced renewal support.
* Batch processing of multiple certificate definitions.
* Separate VCF Component and VCF Management certificate pipelines.
* Certificate validation before deployment, including:

  * Common Name validation
  * DNS SAN validation
  * CSR and certificate public key comparison
  * Certificate chain validation
* Support for appending a configured root CA to the certificate chain before deployment to VCF Operations.
* Certificate replacement through the VCF Operations API.
* Endpoint verification after certificate replacement.
* Runtime data stored outside the Git repository.
* Ansible Vault support for VCF credentials.
* Private keys remain inside VCF Operations and are never handled by C.E.R.B.E.R.U.S.

### Initial VCF Appliance Support

* `VCENTER`
* `SDDC_MANAGER`
* `NSXT_MANAGER`
* `ESX`
* `VCF_OPERATIONS`
* `IDENTITY_BROKER`
* `VCF_SERVICES_RUNTIME`

### Notes

The Let's Encrypt / Cloudflare DNS-01 workflow is the primary implementation.

The Microsoft AD CS / ACME Bridge implementation is experimental and has not been validated across all supported VCF appliance types.
