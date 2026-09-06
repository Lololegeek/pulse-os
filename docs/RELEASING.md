# Releasing PulseOS

## Before tagging

- update `VERSION`;
- update `CHANGELOG.md`;
- run `make verify`;
- confirm the main CI build is green;
- perform installer/update/rollback smoke tests;
- verify the GHCR update image is publicly pullable;
- review known hardware and game regressions.

## Create a release

For version `0.2.0`:

```bash
git tag -s v0.2.0 -m "PulseOS 0.2.0"
git push origin v0.2.0
```

An unsigned tag can be used during early development if the maintainer does not yet have a signing setup, but signed maintainer tags are preferred for public stable releases.

The `Build PulseOS` workflow publishes the release OCI tags, generates the ISO/checksum, and creates the GitHub Release.

## After release

- verify the GitHub Release artifact downloads;
- verify SHA-256;
- verify the OCI signature;
- test an upgrade from the previous stable image;
- monitor new issues for installer/update regressions before announcing broadly.
