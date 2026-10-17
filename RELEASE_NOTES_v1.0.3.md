# v1.0.3 - Certificate Chain and Pipeline Improvements

## Changed

- Added a 180-second settling period after each successful certificate replacement.
- Allow VCF Operations background tasks to complete before continuing.
- Improved certificate chain validation using the configured root CA.
- Updated certificate definitions to use ISRG Root YR.
- Ansible failures are propagated without starting the settling timer.

## Configuration

For Let's Encrypt Generation Y certificates, configure Certbot in /etc/letsencrypt/cli.ini:

    preferred-chain = Root YR

The ISRG Root YR certificate must be available on the CertManager host:

    /etc/ssl/certs/ISRG_Root_YR.pem

Certificate definitions use:

    deployment:
      root_ca_file: /etc/ssl/certs/ISRG_Root_YR.pem

## Known Issues

- In the tested VCF 9.1.1 environment, SSO integration with an external vIDB deployed on a VCF Services Cluster fails with certificate_unknown(46) when using Let's Encrypt certificates.
- SSO with the embedded vCenter vIDB works in the tested environment.
- The external vIDB issue remains under investigation.
- Cloud Proxy and Cert Manager certificate replacement are not yet supported.
