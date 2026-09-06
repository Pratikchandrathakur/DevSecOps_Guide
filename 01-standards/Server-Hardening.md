# Server Hardening Standard

## OS Baseline
- Approved OS images only
- Automatic security updates enabled (with maintenance windows)
- Remove unused packages/services

## Access Security
- Disable password-based SSH for production
- Key-based or identity provider-based login only
- Sudo access via role and approval

## Runtime Security
- Host firewall enabled (least privilege)
- Endpoint protection/EDR installed
- File integrity monitoring on critical paths

## Logging
- Auth logs, sudo logs, service logs centralized
- Time sync via NTP for forensic consistency

## Compliance
- Monthly hardening audit
- Exceptions documented with expiry dates
