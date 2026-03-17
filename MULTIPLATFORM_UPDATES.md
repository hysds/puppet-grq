# Multi-Platform Build Updates for puppet-grq

## Summary
Updated `build_docker.sh` and manifests to support building multi-platform container images for both **linux/amd64** (x86_64) and **linux/arm64** (ARM64/aarch64) architectures.

## Changes Made

### 1. build_docker.sh
**File**: `build_docker.sh`

Added conditional logic to support both standard Docker builds and multi-platform buildx builds:

- **Environment Variables**:
  - `USE_BUILDX=1` - Enables multi-platform build mode
  - `DOCKER_BUILDX_PLATFORM` - Specifies target platforms (default: "linux/amd64,linux/arm64")

- **Behavior**:
  - When `USE_BUILDX=1`: Uses `docker buildx build` with `--platform` flag and `--push`
  - Otherwise: Uses standard `docker build` (backward compatible)

**Builds one image:**
- `hysds/grq:${TAG}` - Multi-stage build:
  - Stage 1: Extends `hysds/dev`, installs HySDS framework and GRQ components
  - Stage 2: Extends `hysds/base`, copies artifacts and configures GRQ/Pele

**Example Usage**:
```bash
# Standard build (x86_64 only)
./build_docker.sh latest hysds develop develop develop latest develop

# Multi-platform build
export USE_BUILDX=1
export DOCKER_BUILDX_PLATFORM="linux/amd64,linux/arm64"
./build_docker.sh latest hysds develop develop develop latest develop
```

### 2. manifests/init.pp
**File**: `manifests/init.pp`

#### **Lines 76-98: Package installation (architecture-specific mod_evasive)**
- **Before**: Hardcoded mod_evasive RPM for x86_64 only
  ```puppet
  'https://dl.fedoraproject.org/pub/archive/epel/7/x86_64/Packages/m/mod_evasive-1.10.1-22.el7.x86_64.rpm': ensure => present;
  ```

- **After**: Dynamically selects mod_evasive based on architecture
  ```puppet
  $arch = $::architecture
  
  if $arch == 'x86_64' {
    $mod_evasive_rpm = 'https://dl.fedoraproject.org/pub/archive/epel/7/x86_64/Packages/m/mod_evasive-1.10.1-22.el7.x86_64.rpm'
  } elsif $arch == 'aarch64' {
    $mod_evasive_rpm = 'https://dl.fedoraproject.org/pub/archive/epel/7/aarch64/Packages/m/mod_evasive-1.10.1-22.el7.aarch64.rpm'
  }
  
  package {
    "${mod_evasive_rpm}": ensure => present;
  }
  ```

#### **Lines 112-141: JDK installation (architecture-specific)**
- **Before**: Hardcoded JDK for x86_64 only
  ```puppet
  $jdk_rpm_file = "jdk-8u241-linux-x64.rpm"
  $jdk_pkg_name = "jdk1.8.x86_64"
  $java_bin_path = "/usr/java/jdk1.8.0_241-amd64/jre/bin/java"
  ```

- **After**: Dynamically selects JDK based on architecture
  ```puppet
  if $arch == 'x86_64' {
    $jdk_rpm_file = "jdk-8u241-linux-x64.rpm"
    $jdk_pkg_name = "jdk1.8.x86_64"
    $java_bin_path = "/usr/java/jdk1.8.0_241-amd64/jre/bin/java"
  } elsif $arch == 'aarch64' {
    $jdk_rpm_file = "jdk-8u241-linux-aarch64.rpm"
    $jdk_pkg_name = "jdk1.8.aarch64"
    $java_bin_path = "/usr/java/jdk1.8.0_241-aarch64/jre/bin/java"
  }
  ```

### 3. docker/Dockerfile - No Changes Required ✅

The Dockerfile is already multi-platform compatible:
- Multi-stage build extends `hysds/dev` and `hysds/base`
- No architecture-specific commands
- No hardcoded x86_64 references

## Prerequisites

### ⚠️ CRITICAL: ARM64 JDK RPM Required

The following file **MUST** be created/obtained for ARM64 builds to succeed:

#### JDK 8 ARM64 RPM
- **files/jdk-8u241-linux-aarch64.rpm** (currently only x64 version exists)
  - Source: Oracle JDK 8 Update 241 for ARM64/aarch64
  - Download from: https://www.oracle.com/java/technologies/javase/javase8-archive-downloads.html
  - Look for: "Linux ARM 64 Hard Float ABI" RPM package
  - Alternative: Use OpenJDK 8 for aarch64 if Oracle JDK is not available

**Note**: The JDK RPM files are split into multiple parts using `cat_split_file`. You'll need to:
1. Download the ARM64 JDK RPM
2. Split it into parts (if it's large) to match the existing pattern
3. Place the split files in the `files/` directory

### Base Images Must Be Multi-Platform

This repository depends on multi-platform base images from upstream repositories:
- ✅ `hysds/dev:${TAG}` - From puppet-hysds_dev
- ✅ `hysds/base:${TAG}` - From puppet-hysds_base

Ensure these base images are built and pushed as multi-platform before building grq.

## Build Order

The correct build order for multi-platform images:

1. **puppet-hysds_base**: Build base image
   ```bash
   cd /path/to/puppet-hysds_base
   export USE_BUILDX=1
   export DOCKER_BUILDX_PLATFORM="linux/amd64,linux/arm64"
   ./build_docker.sh latest hysds develop
   ```

2. **puppet-hysds_dev**: Build dev image
   ```bash
   cd /path/to/puppet-hysds_dev
   export USE_BUILDX=1
   export DOCKER_BUILDX_PLATFORM="linux/amd64,linux/arm64"
   ./build_docker.sh latest hysds develop
   ```

3. **puppet-grq**: Build grq image
   ```bash
   cd /path/to/puppet-grq
   export USE_BUILDX=1
   export DOCKER_BUILDX_PLATFORM="linux/amd64,linux/arm64"
   ./build_docker.sh latest hysds develop develop develop latest develop
   ```

## Image Hierarchy

```
hysds/base (puppet-hysds_base)
  └── hysds/dev (puppet-hysds_dev)
        └── [stage 1] → hysds/grq (puppet-grq)
```

Note: GRQ uses a multi-stage build where stage 1 extends the dev image to install software, then stage 2 extends the base image and copies artifacts from stage 1.

## Testing Checklist

### Build Testing
- [ ] Standard build works without USE_BUILDX
- [ ] Multi-platform build works with buildx enabled
- [ ] GRQ image builds successfully
- [ ] Image is pushed to registry with correct manifest

### Runtime Testing
- [ ] **x86_64**: Pull and run image on x86_64 host
  ```bash
  docker run --platform linux/amd64 hysds/grq:test java -version
  docker run --platform linux/amd64 hysds/grq:test python --version
  ```
- [ ] **ARM64**: Pull and run image on ARM64 host
  ```bash
  docker run --platform linux/arm64 hysds/grq:test java -version
  docker run --platform linux/arm64 hysds/grq:test python --version
  ```

### Component-Specific Testing
- [ ] Verify JDK 8 is installed correctly on both architectures
- [ ] Verify Java alternatives are set correctly
- [ ] Verify mod_evasive is installed correctly
- [ ] Test GRQ2 web interface
- [ ] Test Pele REST API
- [ ] Verify Elasticsearch connectivity

## Verify Multi-platform Image

After building, verify both architectures are present:

```bash
docker buildx imagetools inspect hysds/grq:latest
```

Expected output should show manifests for both:
- Platform: linux/amd64
- Platform: linux/arm64

## Build Secrets

The build script uses Docker BuildKit secrets for GitHub OAuth tokens:
- Secret ID: `git_oauth_token`
- Source: `$HOME/.git_oauth_token`
- Used to bypass GitHub API rate limits during builds

This works with both standard builds and buildx builds.

## Rollback Plan

If issues arise, revert to single-platform builds by:
1. Not setting `USE_BUILDX=1` environment variable
2. The scripts will automatically use standard `docker build` commands

## Known Limitations

1. **ARM64 JDK Availability**: Oracle JDK 8u241 for ARM64 must be obtained separately
   - May need to use OpenJDK 8 as an alternative
   - Ensure JDK version matches between architectures for consistency

2. **mod_evasive ARM64**: The EPEL 7 aarch64 repository should have mod_evasive, but verify availability

3. **Build Time**: Multi-platform builds take significantly longer (2x+ time)

4. **Multi-stage Complexity**: The grq image uses multi-stage builds which may require more memory

5. **Base Image Dependency**: Requires all upstream multi-platform base images to be available

## Alternative: Use OpenJDK

If Oracle JDK for ARM64 is not available, consider switching to OpenJDK 8 which is available in standard repositories:

```puppet
# Alternative approach using dnf package manager
package { 'java-1.8.0-openjdk-devel':
  ensure => present,
}
```

This would work on both architectures without needing separate RPM files, but would require testing to ensure compatibility with GRQ's Java requirements.

## Related Files

This repository's changes work in conjunction with:
- `/Users/mcayanan/git/puppet-hysds_base/` - Base image repository (build first)
- `/Users/mcayanan/git/puppet-hysds_dev/` - Dev image repository (build second)
- `/Users/mcayanan/git/hysds-framework/.circleci/config.yml` - CircleCI configuration
- `/Users/mcayanan/git/hysds-framework/.circleci/MULTIPLATFORM_BUILD_NOTES.md` - Overall strategy

## Additional Notes

- The multi-stage build in the Dockerfile works seamlessly with buildx
- Architecture detection happens automatically during buildx
- Docker automatically pulls the correct architecture when running containers
- Images are tagged once but contain manifests for multiple architectures
- The JDK installation path differs between architectures (amd64 vs aarch64)
- mod_evasive is an Apache module for DDoS protection
- GRQ (Granule Query) and Pele are HySDS REST API components
