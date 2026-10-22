# Security Policy

## Supported versions

Only the latest release of PruneIt is actively supported.

## Reporting a vulnerability

**Do not file a public GitHub issue for security vulnerabilities.**

Please email the maintainer privately at: `TODO_YOUR_SECURITY_EMAIL`

Include:
- A clear description of the vulnerability
- Steps to reproduce
- The version of PruneIt affected
- Any suggested mitigations

You will receive an acknowledgement within 72 hours.

## Deletion safety

PruneIt moves files to the Trash and in some cases removes them permanently
(Simulator runtimes, Apple Intelligence models, Time Machine snapshots, and
package-manager-managed tools). If you find a path where PruneIt could delete
something it should not:

1. Report it privately using the process above.
2. Include the file path, how it appeared in the UI, and what label/safety level it showed.

After a fix is shipped, a post-mortem is added to [`docs/safety-notes.md`](docs/safety-notes.md).
