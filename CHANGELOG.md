# Changelog

All notable changes to this project will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] - 2025-03-12

### Added
- Initial release
- SuiteCRM 8.9.0 on PHP 8.2 + Apache (Debian Bookworm)
- Multi-arch support: `linux/amd64`, `linux/arm64`, `linux/arm/v7`
- GitHub Actions CI/CD with native arm64 runner (no QEMU for arm64)
- Parallel build jobs per arch + manifest merge
- Bind mount for `config.php` and `config_override.php` (survives restarts)
- `setup.sh` script for first-time deployment
- `.env` based configuration
- OAuth2 key auto-generation at container startup
- SuiteCRM 8 scheduler via `bin/console schedulers:run`
- OPcache tuned for low-memory environments (RPi)
- PHP errors suppressed from UI, routed to Apache log
