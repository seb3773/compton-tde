#!/bin/bash
# Install dependencies for compton-tde on Debian/Ubuntu-based systems

echo "Installing build dependencies for compton-tde..."

# Detect package manager
if command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        cmake \
        pkg-config \
        libx11-dev \
        libxcomposite-dev \
        libxdamage-dev \
        libxrender-dev \
        libxfixes-dev \
        libxrandr-dev \
        libxinerama-dev \
        libxext-dev \
        libgl-dev \
        libconfig-dev \
        libdbus-1-dev \
        libpcre2-dev

    echo ""
    echo "=== Core dependencies installed successfully! ==="
    
    # Check for gold linker
    echo ""
    echo "=== Optional: Gold Linker for optimal binary size ==="
    echo "The gold linker can produce smaller binaries (~15-20% smaller) through"
    echo "advanced optimizations like Identical Code Folding (ICF)."
    echo ""
    
    if command -v ld.gold &>/dev/null; then
        echo "✓ Gold linker is already available on your system."
    else
        echo "Gold linker is not currently installed."
        read -p "Would you like to install binutils-gold for optimal binary size? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Installing binutils-gold..."
            sudo apt-get install -y binutils-gold
            echo "✓ Gold linker installed successfully."
        else
            echo "Skipping gold linker installation."
            echo "Note: The build will work with the standard linker, but binaries will be larger."
        fi
    fi
    
    # Check for sstrip
    echo ""
    echo "=== Optional: sstrip for additional size reduction ==="
    echo "sstrip (from elfkickers) can further reduce binary size by removing"
    echo "ELF section headers (saves ~2-5% additional size)."
    echo ""
    
    if command -v sstrip &>/dev/null; then
        echo "✓ sstrip is already available on your system."
    else
        echo "sstrip is not currently installed."
        read -p "Would you like to install elfkickers for sstrip? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Installing elfkickers..."
            sudo apt-get install -y elfkickers
            echo "✓ sstrip installed successfully."
        else
            echo "Skipping sstrip installation."
            echo "Note: You can use standard 'strip' instead, but sstrip provides better results."
        fi
    fi
    
    echo ""
    echo "=== Build instructions ==="
    echo "You can now build compton-tde with:"
    echo ""
    echo "  # Standard build (with logging):"
    echo "  cmake . && make compton-tde"
    echo ""
    echo "  # Optimized build (smaller binary, no console logging):"
    echo "  cmake . -DWITH_SILENT_BUILD=ON && make compton-tde"
    echo ""
    echo "  # For smallest binary size (recommended):"
    echo "  cmake . -DWITH_SILENT_BUILD=ON && make compton-tde && sstrip compton-tde"
    echo ""
    echo "Expected binary sizes:"
    echo "  - Standard linker: ~200-210KB"
    echo "  - Gold linker: ~180-190KB"
    echo "  - Gold linker + silent build: ~175-180KB"
    echo "  - Gold linker + silent build + sstrip: ~170-175KB"
    
else
    echo "Error: apt-get not found. This script only supports Debian/Ubuntu-based systems."
    echo "Please install the following packages manually:"
    echo "  - X11 development libraries (libX11, libXcomposite, libXdamage, libXrender, libXfixes, libXrandr, libXinerama, libXext)"
    echo "  - OpenGL development libraries"
    echo "  - libconfig-dev"
    echo "  - libdbus-1-dev"
    echo "  - libpcre2-dev"
    echo "  - cmake, pkg-config, build-essential"
    echo ""
    echo "Optional for optimal binary size:"
    echo "  - binutils-gold (gold linker)"
    echo "  - elfkickers (sstrip tool)"
    exit 1
fi
