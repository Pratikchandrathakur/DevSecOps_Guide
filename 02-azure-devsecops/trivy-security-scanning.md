# Trivy Security Scanning Strategy

## Scan Types
1. **Filesystem Scan (`scan-type: fs`)**
   - Detect vulnerable dependencies and secrets pre-build
2. **Image Scan (`image-ref`)**
   - Detect container CVEs pre-push

## Gate Policy
- Fail on `CRITICAL` image findings
- Fail on `HIGH,CRITICAL` fs findings
- Upload SARIF for visibility and triage

## Operational Practice
- Track vuln trend weekly
- Patch base images regularly
- Pin known-good image digests for stability
