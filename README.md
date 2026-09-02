# VCF Certificate Automation

Automated certificate lifecycle management for VMware Cloud Foundation using VCF Operations, Ansible and ACME.

The project automates the complete certificate lifecycle from CSR generation to certificate deployment and endpoint validation.

```text
VCF Operations
      |
      | Generate private key + CSR
      v
ACME Client / Certbot
      |
      | DNS-01
      v
ACME CA
      |
      | Signed certificate
      v
VCF Operations Fleet Certificate Management API
      |
      | Replace certificate
      v
VCF Component
      |
      v
Endpoint certificate validation
```

A key design goal is that the private key never needs to leave the VCF environment.

VCF Operations generates and retains the private key and provides only the CSR for certificate issuance.

---

# Important Notice

This project was developed over several days with the assistance of ChatGPT.

The automation, API calls, certificate workflows and resulting certificates were reviewed, validated and tested in my lab to the best of my knowledge and ability.

That does **not** mean the code is free of errors.

Certificate replacement is a security-sensitive operation and mistakes can potentially affect the availability or manageability of your VCF environment.

For that reason, I currently **do not recommend using this project unchanged in a production environment**.

Treat it as:

```text
Lab automation
Reference implementation
Learning resource
Starting point for your own automation
```

Review the code, understand what it does and test it thoroughly in your own environment before considering any productive use.

The project is provided **as-is**.

There is no warranty, no guarantee of functionality and no entitlement to support, updates, bug fixes or compatibility with future VCF releases.

If it works for you: great.

If you improve it: even better.

But please understand the code before allowing it to replace certificates in an environment you care about.

---

# Why this project exists

Replacing certificates in a VMware Cloud Foundation environment once is manageable.

Doing it repeatedly across vCenter, NSX, ESX, SDDC Manager, VCF Operations and the VCF Services Runtime is considerably less entertaining.

This project turns the process into a Git-driven certificate lifecycle.

Add a certificate definition:

```text
certificates/my-component.yml
```

Commit and push it.

The automation handles the rest:

```text
Git
 |
 v
VCF Operations
 |
 | Generate private key + CSR
 v
ACME
 |
 | DNS-01 validation
 v
Certificate Authority
 |
 | Signed certificate
 v
VCF Operations Fleet API
 |
 | Replace certificate
 v
VCF Component
 |
 v
Endpoint certificate verification
```

Certificate renewals are handled automatically based on the configured renewal window:

```yaml
renewal:
  renew_before_days: 30
```

---

# Tested Environment

The project was developed and tested with:

```text
VMware Cloud Foundation 9.1
VCF Operations
Ansible
Certbot
Gitea Actions
Let's Encrypt
Cloudflare DNS
Microsoft Active Directory Certificate Services
Windows DNS
```

The primary and most complete implementation is the:

```text
Let's Encrypt
+
Cloudflare DNS-01
+
VCF Operations Fleet Certificate Management API
```

workflow.

---

# Supported VCF Components

The automation currently supports the following VCF certificate appliance types:

```text
VCENTER
SDDC_MANAGER
NSXT_MANAGER
ESX
VCF_OPERATIONS
IDENTITY_BROKER
VCF_SERVICES_RUNTIME
```

This includes certificates for components such as:

```text
vCenter Server
SDDC Manager
NSX Managers
ESXi Hosts
VCF Operations
VCF Identity Broker
VCF Fleet LCM
VCF Shared Services
VCF Services Platform
```

Real certificate definitions from the development lab are included in the `certificates/` directory.

---

# Supported Certificate Authority Paths

The project currently contains two ACME scenarios.

## Let's Encrypt + Cloudflare DNS-01

This is the primary and most extensively tested certificate path.

Publicly trusted certificates can be requested from Let's Encrypt using Cloudflare DNS-01 validation.

Example:

```yaml
acme:
  server: https://acme-v02.api.letsencrypt.org/directory
  issuance_timeout: 300

challenge:
  type: dns-01
  provider: cloudflare
  credentials_file: /etc/letsencrypt/cloudflare/example.ini
  propagation_seconds: 30
```

The Cloudflare API token is stored outside the Git repository.

Example location:

```text
/etc/letsencrypt/cloudflare/example.ini
```

---

## Microsoft AD CS + ACME Bridge + Windows DNS

The repository also contains an implementation using an internal ACME endpoint backed by Microsoft Active Directory Certificate Services.

This part of the project was created mainly out of curiosity while exploring whether the same certificate lifecycle could be used with an internal Microsoft CA.

It is **optional** and should currently be considered experimental.

The Windows CA path is **not developed to the same level of completeness as the Let's Encrypt implementation**.

It was only tested with the four Windows-CA-backed certificate definitions that were used during development of this project.

It has not been validated across every appliance type supported by the Let's Encrypt workflow.

Do not assume that the Windows CA implementation will work unchanged for:

```text
ESX
VCF_OPERATIONS
IDENTITY_BROKER
VCF_SERVICES_RUNTIME
or any other component not explicitly tested with it
```

Additional development and testing may be required.

The purpose of keeping this code in the repository is to demonstrate that the certificate provider can be changed while retaining much of the same VCF certificate lifecycle.

Conceptually:

```text
                    +----------------------+
                    | Certificate Provider |
                    +----------------------+
                       |                |
                       |                |
               Let's Encrypt      Microsoft AD CS
                       |                |
                       +-------+--------+
                               |
                               v
                       Signed Certificate
                               |
                               v
                     VCF Operations Fleet API
                               |
                               v
                       VCF Component
```

The certificate provider is selected through the certificate definition.

---

# Certificate Definition

Every managed certificate is represented by a YAML file below:

```text
certificates/
```

Example:

```yaml
---
certificate:
  name: esx01
  enabled: true

  common_name: esx01.example.com

  subject:
    country: DE
    state: RLP
    locality: NW
    organization: Example
    organizational_unit: Lab

  sans:
    - esx01.example.com

  ip_sans: []

  key:
    type: rsa
    size: 4096

  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    issuance_timeout: 300

  challenge:
    type: dns-01
    provider: cloudflare
    credentials_file: /etc/letsencrypt/cloudflare/example.ini
    propagation_seconds: 30

  deployment:
    type: vcf_operations
    ops_endpoint: ops.example.com
    appliance: ESX
    target: esx01.example.com
    validate_certs: false
    root_ca_file: /etc/ssl/certs/ISRG_Root_X1.pem

  renewal:
    renew_before_days: 30
```

---

# Real Lab Examples

The repository intentionally contains real certificate definitions used in the development lab.

The hostnames are not considered secret and provide useful examples for different VCF appliance types.

Examples include:

```text
vc01.vcf.sdn-warrior.cloud

ops01.vcf.sdn-warrior.cloud

vidb.vcf.sdn-warrior.cloud

fleetlcm.vcf.sdn-warrior.cloud

shared01.vcf.sdn-warrior.cloud

vsp01.vcf.sdn-warrior.cloud

esx01.vcf.sdn-warrior.cloud

esx02.vcf.sdn-warrior.cloud

esx03.vcf.sdn-warrior.cloud

nsx01.vcf.sdn-warrior.cloud

nsx02.vcf.sdn-warrior.cloud

sddcm.vcf.sdn-warrior.cloud
```

The repository also contains older internal certificate definitions using Microsoft AD CS and an internal ACME endpoint.

Those definitions are included as examples of the experimental Windows CA path described above.

---

# Repository Layout

```text
.
├── .gitea/
│   └── workflows/
│       ├── auto-new-certificate.yml
│       └── scheduled-certificate-renewal.yml
│
├── ansible/
│   ├── playbooks/
│   │   ├── dns-challenge.yml
│   │   ├── vcf-certificate.yml
│   │   ├── vcf-generate-csr.yml
│   │   ├── vcf-replace-certificate.yml
│   │   ├── vcf-management-certificate.yml
│   │   ├── vcf-management-generate-csr.yml
│   │   └── vcf-management-replace-certificate.yml
│   │
│   └── vars/
│       └── vault.example.yml
│
├── certificates/
│   ├── esx01.yml
│   ├── esx02.yml
│   ├── esx03.yml
│   ├── nsx01.yml
│   ├── nsx02.yml
│   ├── ops01-fleetlcm.yml
│   ├── ops01-ops.yml
│   ├── ops01-shared.yml
│   ├── ops01-vidb.yml
│   ├── ops01-vsp.yml
│   ├── sddcm.yml
│   ├── vc01-vcsa.yml
│   └── ...
│
├── hooks/
│   ├── dns-auth.sh
│   └── dns-cleanup.sh
│
├── scripts/
│   └── run-certificate-pipeline.sh
│
├── .gitignore
├── LICENSE
└── README.md
```

---

# Certificate Lifecycle

The lifecycle for a newly added certificate definition looks like this:

```text
New certificate YAML
        |
        v
Gitea Actions
        |
        v
Pipeline Dispatcher
        |
        +------------------------------+
        |                              |
        v                              v
VCF Component Pipeline       VCF Management Pipeline
        |                              |
        +--------------+---------------+
                       |
                       v
              VCF Operations API
                       |
                       | Generate CSR
                       v
                    Certbot
                       |
                       | DNS-01
                       v
                 Certificate CA
                       |
                       | Issue certificate
                       v
                Build certificate chain
                       |
                       v
              VCF Operations Fleet API
                       |
                       | Replace certificate
                       v
                  VCF Component
                       |
                       v
                TLS endpoint check
                       |
                       v
                 Fingerprint match
```

---

# Private Key Handling

One of the most important architectural properties of this project is that the private key does not need to leave VCF.

The process is:

```text
VCF Operations
     |
     | Generate RSA private key
     |
     | Generate CSR
     v
CSR only
     |
     v
ACME Certificate Authority
     |
     | Sign CSR
     v
Certificate Chain
     |
     v
VCF Operations
```

The automation does not export or manage the private key.

---

# Runtime Directory

Generated certificate runtime data is stored outside the Git repository.

Default runtime location:

```text
/etc/vcf-certmanager/
```

Each certificate receives its own runtime directory:

```text
/etc/vcf-certmanager/certificates/<certificate-name>/
```

For example:

```text
/etc/vcf-certmanager/certificates/esx01/
```

Runtime files can include:

```text
request.csr
request.raw.csr
cert.pem
chain.pem
fullchain.pem
```

These files must not be committed to Git.

---

# Ansible Vault

VCF Operations and Windows DNS credentials are stored in Ansible Vault.

Create the local Vault file:

```bash
cp \
  ansible/vars/vault.example.yml \
  ansible/vars/vault.yml
```

Edit the file and add the required credentials.

Then encrypt it:

```bash
ansible-vault encrypt \
  ansible/vars/vault.yml
```

The Vault password itself is expected at:

```text
/etc/vcf-certmanager/vault-pass
```

Neither the encrypted production Vault nor the Vault password should be committed to the repository.

---

# Example Vault Variables

```yaml
---
vcf_ops_user: "admin"
vcf_ops_password: "CHANGE_ME"

# Optional
# vcf_ops_auth_source: "YOUR_AUTH_SOURCE"

windows_dns_user: "DOMAIN\\service-account"
windows_dns_password: "CHANGE_ME"
```

The Windows DNS credentials are only required when using the optional Windows DNS / Microsoft CA workflow.

---

# Cloudflare Credentials

Cloudflare credentials are stored outside Git.

Example:

```text
/etc/letsencrypt/cloudflare/example.ini
```

The file can contain:

```ini
dns_cloudflare_api_token = YOUR_TOKEN
```

Recommended permissions:

```bash
chmod 600 \
  /etc/letsencrypt/cloudflare/example.ini
```

Never commit API tokens to the repository.

---

# Automatic Certificate Onboarding

The workflow:

```text
.gitea/workflows/auto-new-certificate.yml
```

detects newly added YAML files below:

```text
certificates/
```

When a new enabled certificate definition is committed, the workflow automatically starts the appropriate certificate pipeline.

Example:

```bash
git add certificates/esx01.yml

git commit \
  -m "Add ESX01 certificate"

git push
```

The certificate is then generated and deployed automatically.

---

# Pipeline Selection

The script:

```text
scripts/run-certificate-pipeline.sh
```

selects the correct pipeline based on:

```yaml
deployment:
  appliance: ...
```

The current routing is conceptually:

```text
VCENTER
SDDC_MANAGER
NSXT_MANAGER
        |
        v
VCF Component Pipeline
```

and:

```text
VCF_OPERATIONS
IDENTITY_BROKER
VCF_SERVICES_RUNTIME
ESX
        |
        v
VCF Management Pipeline
```

The second path exists because some VCF component types expose CSR inventory information differently through the VCF Operations API.

---

# Automatic Certificate Renewal

The workflow:

```text
.gitea/workflows/scheduled-certificate-renewal.yml
```

periodically reads the certificate currently presented by the endpoint.

The certificate definition controls when renewal should begin:

```yaml
renewal:
  renew_before_days: 30
```

If the certificate expires within the configured window, the complete lifecycle runs again:

```text
Check endpoint
     |
     v
Certificate expires soon?
     |
    yes
     |
     v
Generate new CSR
     |
     v
Issue new certificate
     |
     v
Replace certificate
     |
     v
Verify endpoint
```

---

# Forced Renewal

The scheduled renewal workflow can also be started manually.

This makes a separate manual deployment workflow unnecessary.

Select the certificate and enable:

```text
force_renewal: true
```

Example:

```text
certificate:
esx01

force_renewal:
true
```

This forces the complete renewal process even when the currently installed certificate is still outside the normal renewal window.

---

# Multiple Certificates in One Commit

Several new certificate definitions can be added in one Git commit.

The Auto-New workflow processes them sequentially.

Example:

```text
esx02.yml
esx03.yml
nsx01.yml
nsx02.yml
sddcm.yml
```

The workflow processes:

```text
esx02
  |
  v
esx03
  |
  v
nsx01
  |
  v
nsx02
  |
  v
sddcm
```

If one certificate deployment fails, the workflow stops instead of continuing with additional certificate replacements.

This behavior is intentional.

---

# VCF 9.1 Notes

During development several VCF 9.1 certificate-management behaviors required special handling.

## CSR Inventory Differences

Not every VCF appliance type exposes CSR inventory information in exactly the same form.

The initial implementation queried CSR objects using the appliance type.

This works for some VCF components.

For components such as:

```text
VCF_OPERATIONS
ESX
```

the returned CSR object does not necessarily contain the expected appliance type information.

The alternative pipeline therefore retrieves the CSR inventory and performs local matching using:

```text
commonName
+
applianceHostname
```

This is the reason the project contains separate CSR generation paths.

---

# Let's Encrypt Certificate Chain

VCF Operations performs certificate-chain validation when replacing certificates.

During testing, the standard Certbot `fullchain.pem` returned by Let's Encrypt was not sufficient for the VCF certificate replacement API.

VCF required a complete chain including the trusted root certificate.

The automation therefore supports:

```yaml
deployment:
  root_ca_file: /etc/ssl/certs/ISRG_Root_X1.pem
```

When configured, the root CA certificate is appended to the generated chain before the certificate is submitted to VCF Operations.

Conceptually:

```text
Leaf Certificate
      |
      v
Let's Encrypt Intermediate
      |
      v
Let's Encrypt Chain
      |
      v
ISRG Root X1
```

This produces the chain accepted by the tested VCF 9.1 environment.

This behavior reflects the environment and certificate chain tested during development and may change with different Let's Encrypt chains or future VCF versions.

---

# Long-Running VCF Services Runtime Replacements

Certificate replacements for VCF Services Runtime components can take significantly longer than replacements for some traditional VCF components.

Examples include:

```text
fleetlcm
shared services
VCF Services Platform
```

These services may require several minutes for the certificate replacement workflow to complete.

The dedicated VCF Management replacement playbook therefore uses a larger polling window.

The `FAILED - RETRYING` output generated by Ansible during polling does not necessarily indicate a failed VCF operation.

It normally means that the VCF workflow is still:

```text
INPROGRESS
```

The automation continues polling until VCF reports:

```text
COMPLETED
```

or the retry limit is reached.

---

# Certificate Verification

After VCF reports a successful certificate replacement, the automation connects directly to the target endpoint.

It reads the certificate presented over TLS and calculates its SHA-256 fingerprint.

The fingerprint is then compared with the certificate generated locally.

Conceptually:

```text
Local certificate
      |
      | SHA256
      v
Fingerprint A


VCF endpoint
      |
      | TLS
      |
      | SHA256
      v
Fingerprint B


Fingerprint A == Fingerprint B
             |
             v
          SUCCESS
```

This ensures that a completed VCF workflow also resulted in the expected certificate actually being presented by the endpoint.

---

# Security Model

Sensitive data must remain outside the repository.

Do not commit:

```text
Ansible Vault production files
Vault passwords
Cloudflare API tokens
ACME credential files
private keys
generated CSRs
generated certificates
environment files containing credentials
```

The repository `.gitignore` contains rules intended to prevent common runtime and secret files from being committed.

However, `.gitignore` is not a security mechanism.

Always review staged files before pushing changes:

```bash
git diff --cached
```

---

# GitHub and Gitea

The source code is published on GitHub for sharing and collaboration.

The actual automation environment used during development runs on Gitea with a self-hosted Gitea Actions runner.

The included workflows therefore currently use:

```text
.gitea/workflows/
```

The underlying:

```text
Ansible playbooks
shell scripts
certificate definitions
VCF Operations API workflow
ACME workflow
```

are not inherently tied to Gitea.

The workflows could be adapted to other CI/CD platforms if required.

---

# Development Approach

This project was not created as a commercial product or polished software package.

It grew from a real lab requirement and was developed iteratively over several days.

ChatGPT was used extensively during development to help:

```text
analyze API responses
build and refine Ansible playbooks
debug VCF certificate workflows
develop Git-driven automation
investigate certificate-chain behavior
review logs
identify VCF API differences
and improve the overall implementation
```

Every important step was executed and validated against the lab environment instead of relying solely on generated code or assumptions.

Several issues were discovered only through real testing, including:

```text
VCF CSR inventory differences
ESX CSR handling
Let's Encrypt certificate-chain requirements
long-running VCF Services Runtime replacements
certificate endpoint fingerprint validation
```

Nevertheless, neither manual testing nor AI-assisted development can guarantee that every possible condition, environment or failure mode has been covered.

Use the project accordingly.

---

# Design Goals

The project follows a few simple principles:

```text
Git is the source of truth.

Private keys stay in VCF.

Secrets stay outside Git.

Certificate providers should be replaceable.

Certificate deployment should be repeatable.

Renewal should require no manual certificate handling.

A completed API workflow is not enough:
the final endpoint certificate must also be verified.
```

---

# Disclaimer and Support

This project is an independent community project.

It is not affiliated with, endorsed by, or supported by Broadcom or VMware.

The code was developed with the assistance of ChatGPT over several days and has been validated and tested in a VMware Cloud Foundation 9.1 lab environment to the best of my knowledge and ability.

Despite that testing, errors, incorrect assumptions, undiscovered edge cases or environment-specific behavior may exist.

Certificate replacement can affect critical infrastructure components.

For that reason:

**I do not currently recommend using this project unchanged in a production environment.**

If you choose to use any part of it outside a lab, you are responsible for reviewing, validating and adapting the code for your environment.

The project is provided:

**AS IS**

without warranty of any kind.

There is no guarantee that it will:

```text
work in your environment
work with future VCF versions
support every certificate type
handle every failure scenario
or recover automatically from failed certificate replacement operations
```

There is also **no entitlement to support**.

I may improve, change or extend the project over time, but there is no commitment to provide:

```text
technical support
troubleshooting
bug fixes
feature requests
updates
release schedules
or compatibility guarantees
```

The Microsoft AD CS / Windows DNS implementation deserves an additional warning:

It is an optional and experimental part of this repository that was created primarily out of technical curiosity.

It was tested only with the four Windows-CA-backed certificate definitions used during development and is not considered a complete implementation for every VCF component supported by the Let's Encrypt workflow.

The Let's Encrypt / Cloudflare path is the primary implementation of this project.

Before touching a production VCF environment:

```text
Read the code.

Understand the API calls.

Test it in a lab.

Have a recovery plan.

Then decide whether it is appropriate for your environment.
```

---

# License

Licensed under the Apache License, Version 2.0.

See:

```text
LICENSE
```

for the complete license text.

---

# Sharing is Caring

This project exists because certificate automation should not require everyone to rediscover the same undocumented behavior independently.

The code is available so others can learn from it, adapt it and hopefully improve it.

If it saves you some time:

use it.

If you find something wrong:

fix it.

If you make it better:

share it.

Sharing is caring.
