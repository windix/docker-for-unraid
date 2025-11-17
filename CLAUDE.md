# CLAUDE.md - AI Assistant Documentation

## Project Overview

**docker-for-unraid** is a personal customized Ubuntu Docker image designed to run on Unraid systems. It provides a comprehensive CLI environment with tools not included in Unraid's default Slackware-based system.

### Why This Project Exists

- Unraid uses Slackware Linux (less common/supported)
- Unraid hides user accounts, allowing only root SSH access
- Customizations are lost during Unraid upgrades
- This containerized approach preserves tools and environment across upgrades

## Repository Structure

```
docker-for-unraid/
├── Dockerfile                      # Main image definition (Ubuntu 24.04 + tools)
├── Dockerfile.bdinfo-build         # Legacy bdinfo build (deprecated, kept for reference)
├── Makefile                        # Build automation (build/push/run)
├── README.md                       # User-facing documentation
├── files/
│   └── bin/
│       ├── configure-ssh-user.sh   # SSH user setup and SSHD startup script
│       ├── bdinfo-cli              # BDInfo wrapper (calls mono)
│       └── thumb                   # Video thumbnail generator script
├── ruby-misc/                      # Ruby scripts directory (external, not in git)
│   ├── Gemfile                     # Ruby dependencies
│   └── [custom scripts]            # User's ruby scripts
└── unraid-docker-settings.png     # Configuration reference screenshot
```

## Core Components

### Installed Tools

**Download Tools:**
- wget, curl, aria2c

**Video Processing:**
- ffmpeg - Video encoding/processing
- mediainfo - Media file information
- BDInfoCLI-ng v0.7.5.5 - Blu-ray disc information
- VCS (Video Contact Sheet) v1.13.4 - Video thumbnails/contact sheets
- yt-dlp - YouTube/video downloader (latest)

**File Management:**
- rclone - Cloud storage sync
- gclone v1.67.0-mod1.6.2 - Enhanced rclone for Google Drive
- p7zip-full, p7zip-rar - Archive tools
- rsync - File synchronization

**Development:**
- Ruby (full) + bundler
- Build tools (gcc, g++, make)
- Git
- Mono (complete) - .NET runtime for BDInfoCLI

**System Utilities:**
- tmux, byobu - Terminal multiplexers
- htop - Process viewer
- vim - Text editor
- rename - Batch file renaming
- netcat, net-tools, iputils-ping - Networking

### Custom Scripts

**`files/bin/configure-ssh-user.sh`** (Dockerfile.bdinfo-build:1)
- Container entrypoint/startup script
- Creates/configures SSH user from environment variables
- Sets up authorized keys if provided
- Grants sudo privileges (passwordless)
- Starts SSH daemon

**`files/bin/bdinfo-cli`** (files/bin/bdinfo-cli:1)
- Wrapper script for BDInfoCLI-ng
- Calls: `mono /app/bdinfo-cli/BDInfo.exe "$@"`

**`files/bin/thumb`** (files/bin/thumb:1)
- Generates video thumbnail contact sheets
- Finds video files (mp4, mkv, wmv, avi, mov, ts)
- Creates 18-tile contact sheets using VCS
- Uses Noto Sans CJK font for Asian character support
- Skips if thumbnail already exists

## Development Workflow

### Building the Image

```bash
# Build with default tag (current date)
make build

# Build with custom tag
DOCKER_TAG=custom-tag make build

# This creates two tags:
# - docker.windix.au/docker-for-unraid:YYYYMMDD
# - docker.windix.au/docker-for-unraid:latest
```

### Running Locally

```bash
# Quick test run
make run

# Manual run with custom settings
docker run -it --rm \
  -e SSH_PASSWORD=your_password \
  -e SSH_USERNAME=ubuntu \
  -p 2222:22 \
  -v /path/to/data:/data \
  -v /path/to/ruby-misc:/app/ruby \
  docker.windix.au/docker-for-unraid:latest
```

### Deploying to Registry

```bash
# Push both tags to private registry
make push
```

### Environment Variables

**Required:**
- `SSH_PASSWORD` - Password for SSH user (required)

**Optional:**
- `SSH_USERNAME` - SSH username (default: `ubuntu`)
- `AUTHORIZED_KEYS` - SSH public keys for key-based auth
- `SSHD_CONFIG_ADDITIONAL` - Additional SSHD config lines
- `SSHD_CONFIG_FILE` - Path to additional SSHD config file
- `TZ` - Timezone (default: `Australia/Melbourne`)

### Volume Mounts

**Expected Mounts:**
- `/data` - General data storage
- `/mnt/user` - Unraid user shares
- `/app/ruby` - Ruby scripts directory (mount ruby-misc here)

## Key Conventions & Patterns

### Docker Image Patterns

1. **Multi-stage cleanup**: Each tool installation cleans apt cache
2. **Layer optimization**: Related tools grouped in single RUN commands
3. **Security**: PermitRootLogin disabled, sudo user created
4. **Date-based versioning**: Tags use YYYYMMDD format
5. **Private registry**: Uses docker.windix.au (not Docker Hub)

### File Organization

1. **Binary scripts** go in `files/bin/` (copied to `/usr/local/bin/`)
2. **Ruby scripts** kept separate in `ruby-misc/` (mounted at runtime)
3. **External dependencies** downloaded via wget during build
4. **Prebuilt binaries** preferred over source compilation (see bdinfo-cli)

### Recent Changes

Based on git history (Dockerfile.bdinfo-build:824192c):

1. **824192c** - Replaced `unzip` with `7z` for bdinfo extraction
2. **fca2d66** - Fixed bdinfo path issues
3. **4c62715** - Initial commit

### BDInfo Build Notes

- Original approach: Build from source using Dockerfile.bdinfo-build
- Current approach: Download prebuilt binary (v0.7.5.5)
- Dockerfile.bdinfo-build kept for reference only
- Uses 7z instead of unzip (more reliable for certain archives)

## AI Assistant Guidelines

### When Making Changes

1. **Preserve functionality**: This is a production image for Unraid
2. **Test locally**: Use `make run` before pushing
3. **Update version**: Git commit triggers new build
4. **Document in README**: User-facing changes go in README.md
5. **Respect external dependencies**: ruby-misc/ is not in git

### Common Tasks

**Adding a new tool:**
1. Add apt package or wget download in Dockerfile
2. Follow existing pattern (install + cleanup in same RUN)
3. Update README.md "What included" section
4. Test build: `make build`

**Modifying scripts:**
1. Edit files in `files/bin/`
2. Ensure executable permissions preserved
3. Test in running container before committing

**Updating dependencies:**
1. Check for new versions of downloaded tools (vcs, gclone, yt-dlp, bdinfo)
2. Update wget URLs in Dockerfile
3. Verify version compatibility

**Ruby scripts:**
1. NOT managed in this repo
2. Expected to be mounted at `/app/ruby`
3. Must have Gemfile for dependencies
4. Installed via `bundle install` during image build

### Security Considerations

1. **SSH password required**: No default password, must be set via env var
2. **Sudo access**: User has passwordless sudo (intentional for convenience)
3. **Root login disabled**: SSH access only via created user
4. **Private registry**: Not published to public Docker Hub

### Testing Checklist

Before committing changes:
- [ ] Dockerfile builds successfully
- [ ] Image runs with `make run`
- [ ] SSH access works (port 2222)
- [ ] Key tools functional (ffmpeg, bdinfo-cli, thumb, etc.)
- [ ] No broken dependencies
- [ ] README.md updated if needed

### Common Pitfalls

1. **ruby-misc missing**: Build expects this directory - handle gracefully if absent
2. **7z vs unzip**: Prefer 7z for reliability (recent change)
3. **Mono version**: BDInfo requires mono-complete (not mono-runtime)
4. **Font paths**: thumb script needs Noto CJK font for Asian characters
5. **Timezone**: Default is Australia/Melbourne - users may override

## Architecture Decisions

### Why Ubuntu 24.04?
- LTS support
- Better package availability than Slackware
- Familiar to most users
- Regular security updates

### Why SSH Server?
- Unraid doesn't provide persistent shell customization
- Container provides isolated, persistent environment
- Users can SSH directly into container with their tools

### Why Private Registry?
- Personal/internal use
- Faster pulls on local network
- No Docker Hub rate limits

### Why Mono for BDInfo?
- BDInfoCLI is .NET application
- Mono provides cross-platform .NET runtime
- Alternative was Wine (less reliable)

## Future Considerations

- **Ruby scripts integration**: Consider versioning ruby-misc separately
- **Multi-arch support**: Currently x86_64 only
- **Automated builds**: Could add CI/CD pipeline
- **Health checks**: Add Docker HEALTHCHECK for SSH daemon
- **Size optimization**: Current image is large due to mono + ruby

## Resources

- Base image source: https://github.com/aoudiamoncef/ubuntu-sshd
- BDInfoCLI-ng: https://github.com/zoffline/BDInfoCLI-ng
- VCS: https://github.com/outlyer-net/video-contact-sheet
- yt-dlp: https://github.com/yt-dlp/yt-dlp
- gclone: https://github.com/dogbutcat/gclone

## Quick Reference

```bash
# Build and tag
make build

# Push to registry
make push

# Test locally
make run

# Access container
ssh -p 2222 ubuntu@localhost

# Run bdinfo on Blu-ray
bdinfo-cli /path/to/bluray/BDMV

# Generate thumbnails
cd /path/to/videos && thumb

# Download video
yt-dlp [URL]
```

---

*Last updated: 2025-11-17*
*Repository: windix/docker-for-unraid*
