# Security Policy

## Supported versions

PulseOS is currently pre-1.0 alpha software. Security fixes are applied to the current development branch and the newest published release line. Older alpha builds should not be assumed to receive backports.

| Version | Security support |
| --- | --- |
| `main` / `edge` | Yes, development channel |
| Latest tagged release | Yes |
| Older alpha releases | Best effort only |

## Reporting a vulnerability

Please **do not publish exploit details, private keys, credentials, or a working proof-of-concept for a serious vulnerability in a public issue**.

Use GitHub's private vulnerability reporting / Security Advisory flow for this repository when available. If that option is unavailable, open a minimal public issue that says you need a private security contact, without including sensitive details.

A useful report includes:

- affected PulseOS version or commit;
- affected hardware if relevant;
- attack preconditions and impact;
- reproduction steps at a level safe for private disclosure;
- suggested mitigation, if known.

## Security principles

PulseOS does not treat reduced security as a default gaming optimization. In particular, the project does not intentionally ship:

- CPU vulnerability mitigations disabled by default;
- anti-cheat bypasses or kernel concealment;
- automatic GPU/CPU overclocking;
- embedded signing keys or fixed installer credentials;
- globally exposed privileged debugging interfaces for performance reasons.

The technical security model is documented in [docs/SECURITY.md](docs/SECURITY.md).

## Supply chain

Public releases should use reproducible image definitions, OCI image signatures, release checksums, CI provenance where available, and immutable version tags. Third-party packages retain their upstream trust and signing models.
