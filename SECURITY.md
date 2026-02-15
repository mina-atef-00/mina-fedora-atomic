# Security Policy

This document describes the security measures implemented for Mina's Fedora Atomic images and how to verify them.

## Image Signing

All container images are signed using [Cosign](https://docs.sigstore.dev/cosign/) with a private key. The public key is included in this repository as `cosign.pub`.

### Public Key

```
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE7vBif0XL1xuMgbuzMP36SeV4Q6Bb
S5/sJSTI15XDpNIKiTYYcW8UZgKnAJ0sFGY6yetTlsw51YfRMGXg0oxjkg==
-----END PUBLIC KEY-----
```

## Verifying Image Signatures

Before deploying or switching to a new image, you should verify its signature.

### Prerequisites

Install Cosign:

```bash
# Fedora
sudo dnf install cosign

# Or download directly
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
```

### Verify by Tag

```bash
# Download the public key
curl -O https://raw.githubusercontent.com/mina-atef-00/mina-fedora-atomic/main/cosign.pub

# Verify the laptop image
cosign verify --key cosign.pub \
  ghcr.io/mina-atef-00/mina-fedora-atomic-laptop:latest

# Verify the desktop image
cosign verify --key cosign.pub \
  ghcr.io/mina-atef-00/mina-fedora-atomic-desktop:latest
```

### Verify by Digest (Recommended)

For the highest security, verify the image by its digest:

```bash
# Get the digest from the registry
DIGEST=$(skopeo inspect docker://ghcr.io/mina-atef-00/mina-fedora-atomic-laptop:latest --format '{{.Digest}}')

# Verify by digest
cosign verify --key cosign.pub \
  ghcr.io/mina-atef-00/mina-fedora-atomic-laptop@$DIGEST
```

## Secure Bootc Switch

When switching to a new image, always verify first:

```bash
# 1. Download the public key
curl -O https://raw.githubusercontent.com/mina-atef-00/mina-fedora-atomic/main/cosign.pub

# 2. Verify the image
cosign verify --key cosign.pub \
  ghcr.io/mina-atef-00/mina-fedora-atomic-laptop:latest

# 3. Only proceed if verification succeeds
if [ $? -eq 0 ]; then
  sudo bootc switch --transport registry \
    ghcr.io/mina-atef-00/mina-fedora-atomic-laptop:latest
else
  echo "Signature verification failed! Aborting."
  exit 1
fi
```

## Security Features

### Build Security

- **Pinned Actions**: All GitHub Actions use SHA-pinned versions to prevent supply chain attacks
- **Minimal Permissions**: Workflows use minimal required permissions (`contents: read`, `packages: write`)
- **No Secret Leaks**: Build logs are sanitized to prevent secret exposure
- **Clean Environment**: Build runners use `remove-unwanted-software` to minimize attack surface

### Supply Chain Security

- **SBOM Generation**: Every build generates a Software Bill of Materials (SBOM) in SPDX format
- **Vulnerability Scanning**: Images are scanned with Trivy for CVEs on every build
- **Trusted Base Images**: Only images from `ghcr.io/ublue-os` are used as bases
- **Signed Images**: All images are signed with Cosign using a private key

### Access Control

- **No PR Pushes**: Pull request builds don't push to the registry
- **Protected Branches**: Only pushes to `main` trigger releases
- **Workflow Dispatch**: Manual triggers require appropriate permissions

## Vulnerability Reports

If you discover a security vulnerability, please:

1. **DO NOT** open a public issue
2. Email security concerns to: [repository owner]
3. Include detailed reproduction steps
4. Allow time for remediation before public disclosure

## Security Checklist for Users

Before deploying:

- [ ] Verify image signature with `cosign verify`
- [ ] Check SBOM for unexpected packages
- [ ] Review vulnerability scan results
- [ ] Ensure you're pulling from `ghcr.io/mina-atef-00/`
- [ ] Verify the digest matches expected value

## SBOM Access

Software Bills of Materials are available as build artifacts for 90 days. You can download them from:

1. GitHub Actions build artifacts
2. Future: Attached to GitHub Releases

## Reporting Issues

For non-security issues, please use the [GitHub issue tracker](https://github.com/mina-atef-00/mina-fedora-atomic/issues).

---

**Last Updated**: 2026-02-14  
**Cosign Version**: v2.6.1  
**Verification Key**: `cosign.pub` in repository root
