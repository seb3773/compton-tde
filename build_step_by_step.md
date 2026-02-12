# Step-by-Step Instructions for Building and Installing compton-tde-x from Source

## TDE Versions
14.1.1 or later (tested on 14.1.1 and 14.1.5)

## Getting the Source Code

First, check which version of TDE is installed on your system:
```bash
tde-config --version
```
Note the TDE version and then download TDE Base Source: You need the `tdebase` source code matching your installed TDE version (Download from TDE Git).

### Clone tdebase for your TDE version (replace 14.1.5 with your version)
```bash
git clone https://mirror.git.trinitydesktop.org/gitea/TDE/tdebase.git -b r14.1.5 tdebase-trinity-14.1.5
```

### Clone the compton-tde-x repository to a temporary location
```bash
cd /tmp
git clone https://github.com/seb3773/compton-tde-x
```

### Copy compton-tde-x Files into TDE Base
Let's assume you cloned the tdebase in `~/src/`:
```bash
cp -r /tmp/compton-tde-x ~/src/tdebase-trinity-14.1.5/twin/compton-tde
```

### Verify the files are in place
```bash
ls ~/src/tdebase-trinity-14.1.5/twin/compton-tde
```
You should see files like `CMakeLists.txt`, `compton.c`, `compton.h`, `install_deps.sh`, `README.md`, etc.

## Install Dependencies

Now, all commands assume you are in the tdebase directory:
```bash
cd ~/src/tdebase-trinity-14.1.5
```

The `install_deps.sh` script will install all required development packages and optionally install optimization tools.
```bash
cd twin/compton-tde
./install_deps.sh
```

This will:
- install core build dependencies (X11 libraries, OpenGL, libconfig, dbus, pcre2, etc.)
- check if the **gold linker** is available (optional but better for smaller binaries)
- checks if **sstrip** is available (optional, for more binary size reduction)

### Verify Dependencies
```bash
cmake --version

# Check pkg-config:
pkg-config --version

# Check if gold linker is available
ld.gold --version

# Check if sstrip is available (optional)
sstrip --version
```

## Build Instructions

Now, let's build. There are two build modes:

### Mode 1: Standard Build (with logging)
> Includes console logging for debugging purposes. Binary size: ~200-210KB.

Make sure you're in the compton-tde directory:
```bash
cd ~/src/tdebase-trinity-14.1.5/twin/compton-tde
```

Configure with cmake:
```bash
cmake . -DWITH_LIBCONFIG=ON -DWITH_OPENGL=ON -DWITH_PCRE2=ON \
        -DWITH_XRENDER=ON -DWITH_XFIXES=ON -DWITH_XCOMPOSITE=ON \
        -DWITH_XDAMAGE=ON
```

And build:
```bash
make
```

### Mode 2: Optimized Build (silent, no logging)
> This one removes all console logging strings for a smaller binary. Binary size around ~175-180KB.
> **This is what I use for production release.**

Make sure you're in the compton-tde directory:
```bash
cd ~/src/tdebase-trinity-14.1.5/twin/compton-tde
```

Configure with cmake (note the `-DWITH_SILENT_BUILD=ON` flag):
```bash
cmake . -DWITH_LIBCONFIG=ON -DWITH_OPENGL=ON -DWITH_PCRE2=ON \
        -DWITH_XRENDER=ON -DWITH_XFIXES=ON -DWITH_XCOMPOSITE=ON \
        -DWITH_XDAMAGE=ON -DWITH_SILENT_BUILD=ON
```

And then build:
```bash
make
```

### What to Expect
During CMake configuration, you should see:
- `"-- Using gold linker for better optimization"`
- OR `"Gold linker not available, using standard ld"`
- OR `"-- Using lld linker"`
(This indicates which linker is being used.)

During compilation, you should see something like:
```
[ 20%] Building C object CMakeFiles/compton-tde.dir/compton.c.o
[ 40%] Building C object CMakeFiles/compton-tde.dir/opengl.c.o
[ 60%] Building C object CMakeFiles/compton-tde.dir/dbus.c.o
[ 80%] Building C object CMakeFiles/compton-tde.dir/c2.c.o
[100%] Linking C executable compton-tde
[100%] Built target compton-tde
```

### Verify Binary Creation
Check that the binary was created:
```bash
ls -lh compton-tde
```
The size will vary depending on:
- Build mode (standard vs silent)
- Linker used (gold vs ld vs lld)
- Whether sstrip was applied

After a successful build, you will find:
```
twin/compton-tde/
├── compton-tde              # Main executable binary <--- this one should go to /opt/trinity/bin/ for installing
├── CMakeCache.txt           # CMake cache (generated)
├── CMakeFiles/              # CMake build files (generated)
├── cmake_install.cmake      # CMake install script (generated)
├── Makefile                 # Generated Makefile
├── compton_config.h         # Generated configuration header
└── ... (other sources files)
```

## Installing

To install compton-tde-x system-wide (requires root privileges):

Make sure you're in the compton-tde directory:
```bash
cd ~/src/tdebase-trinity-14.1.5/twin/compton-tde
```

Run install:
```bash
sudo make install
```
(this will simply copy `compton-tde` binary to `/usr/local/bin/` (or `/usr/bin/` depending on CMAKE_INSTALL_PREFIX))

You can also test compton-tde without installing it system-wide:
```bash
./compton-tde &
```

## Packaging

Build the binary first of course, then run the Packaging Script:

```bash
cd ~/src/tdebase-trinity-14.1.5/twin/compton-tde
chmod +x ./create_deb.sh
./create_deb.sh
```

Expected output:
```
Creating .deb package for compton-tde...
Trinity version: 14.1.5
Architecture: amd64
Copying binaries and assets...
Stripping binaries...
Creating control file...
Building package...
dpkg-deb: warning: root directory package_build has unusual owner or group 1000:1000
dpkg-deb: hint: you might need to pass --root-owner-group
dpkg-deb: building package 'compton-tde' in 'compton-tde_1.0_tde14.1.5_amd64.deb'.
Success! Package created: compton-tde_1.0_tde14.1.5_amd64.deb
-rw-r--r-- 1 user user 175K Feb 11 14:25 compton-tde_1.0_tde14.1.5_amd64.deb
```
(warning about "unusual owner or group" is normal when building packages as a non-root user, this can be safely ignored.)

The created package includes:
- **Binary**: `/usr/bin/compton-tde`
- **Package name**: `compton-tde`
- **Version**: Automatically detected from your TDE version
- **Architecture**: Automatically detected
- **Dependencies**: Listed in the package metadata

---

## Troubleshooting (some issues I experienced myself :-p )

### CMake Error - "Unknown CMake command 'tde_add_kpart'"
**Error message:**
```
CMake Error at CMakeLists.txt:17 (tde_add_kpart):
  Unknown CMake command "tde_add_kpart".
```
**Solution:**
You tried to run `cmake .` in a subdirectory that uses TDE-specific macros, but this project is designed to be built from the `twin/compton-tde` directory within the tdebase source tree, not as a standalone project.

### CMake Error - "CMakeCache.txt directory is different"
**Error message:**
```
CMake Error: The current CMakeCache.txt directory /tmp/compton-tde-x/CMakeCache.txt
is different than the directory /home/seb/tdebase-trinity-14.1.5/twin/compton-tde
where CMakeCache.txt was created.
```
**Solution:**
I included generated build files with hardcoded paths from my system. Clean the build artifacts before running CMake:

```bash
cd ~/src/tdebase-trinity-14.1.5/twin/compton-tde
rm -rf CMakeCache.txt CMakeFiles/ cmake_install.cmake Makefile compton_config.h
```

And run cmake again:
```bash
cmake . -DWITH_LIBCONFIG=ON -DWITH_OPENGL=ON -DWITH_PCRE2=ON \
        -DWITH_XRENDER=ON -DWITH_XFIXES=ON -DWITH_XCOMPOSITE=ON \
        -DWITH_XDAMAGE=ON
```

### Linker Error - "cannot find 'ld'"
**Error message:**
```
collect2: fatal error: cannot find 'ld'
```
**Solution:**
The build system is trying to use the gold linker, but it's not installed. The CMakeLists.txt automatically detects available linkers. If you see this error, it means the detection failed. Clean and rebuild:

```bash
rm -rf CMakeCache.txt CMakeFiles/ cmake_install.cmake Makefile compton_config.h

cmake . -DWITH_LIBCONFIG=ON -DWITH_OPENGL=ON -DWITH_PCRE2=ON \
        -DWITH_XRENDER=ON -DWITH_XFIXES=ON -DWITH_XCOMPOSITE=ON \
        -DWITH_XDAMAGE=ON
make
```
Now the build system will automatically fall back to the standard linker if gold is not available.

### "make: *** No targets specified and no makefile found"
**Solution:**
You're in the wrong directory or cmake hasn't been run yet:

```bash
cd ~/src/tdebase-trinity-14.1.5/twin/compton-tde
```

Run cmake first:
```bash
cmake . -DWITH_LIBCONFIG=ON -DWITH_OPENGL=ON -DWITH_PCRE2=ON \
        -DWITH_XRENDER=ON -DWITH_XFIXES=ON -DWITH_XCOMPOSITE=ON \
        -DWITH_XDAMAGE=ON
```

Then build:
```bash
make
```

## CMake Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `WITH_LIBCONFIG` | ON/OFF | ON | Enable libconfig support (required) |
| `WITH_OPENGL` | ON/OFF | ON | Enable OpenGL backend for VSync |
| `WITH_PCRE2` | ON/OFF | ON | Enable PCRE2 regex support |
| `WITH_XRENDER` | ON/OFF | ON | Enable XRender support (required) |
| `WITH_XFIXES` | ON/OFF | ON | Enable XFixes support (required) |
| `WITH_XCOMPOSITE` | ON/OFF | ON | Enable XComposite support |
| `WITH_XDAMAGE` | ON/OFF | ON | Enable XDamage support |
| `WITH_XINERAMA` | ON/OFF | ON | Enable Xinerama support |
| `WITH_XRANDR` | ON/OFF | ON | Enable XRandr support |
| `WITH_DBUS` | ON/OFF | ON | Enable DBus support |
| `WITH_SILENT_BUILD` | ON/OFF | OFF | Disable console logging (smaller binary) |
