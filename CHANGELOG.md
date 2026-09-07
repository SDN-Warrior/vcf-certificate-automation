# Changelog

All notable changes to C.E.R.B.E.R.U.S. are documented in this file.

---

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
