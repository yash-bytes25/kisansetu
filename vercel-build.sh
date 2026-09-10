#!/bin/bash
set -euo pipefail

echo "============================================================"
echo " KisanSetu (SIH26032) - Vercel Flutter Web Build"
echo "============================================================"

# Aligned with project specifications: Flutter 3.47.2 / Dart 3.13.2
TARGET_FLUTTER_VERSION="3.47.2"

# 1. Locate or Install Flutter SDK
if command -v flutter &> /dev/null; then
    echo "==> Flutter is already installed on system PATH:"
    flutter --version | head -n 2
elif [ -x "$HOME/flutter/bin/flutter" ]; then
    echo "==> Found cached Flutter SDK in $HOME/flutter/bin"
    export PATH="$HOME/flutter/bin:$PATH"
elif [ -x "/tmp/flutter/bin/flutter" ]; then
    echo "==> Found cached Flutter SDK in /tmp/flutter/bin"
    export PATH="/tmp/flutter/bin:$PATH"
else
    echo "==> Flutter SDK not detected. Installing Flutter ${TARGET_FLUTTER_VERSION}..."
    INSTALL_DIR="$HOME/flutter"
    # Attempt shallow clone of exact version tag first, fall back to stable branch if tag fails
    if ! git clone --depth 1 --branch "${TARGET_FLUTTER_VERSION}" https://github.com/flutter/flutter.git "${INSTALL_DIR}"; then
        echo "==> Tag ${TARGET_FLUTTER_VERSION} clone failed; falling back to stable channel..."
        git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${INSTALL_DIR}"
    fi
    export PATH="${INSTALL_DIR}/bin:$PATH"
fi

echo "==> Using Flutter located at: $(which flutter)"
flutter --version

# Disable telemetry and precache Web engine binaries
flutter config --no-analytics
echo "==> Precaching Flutter web engine artifacts..."
flutter precache --web

# 2. Resolve project dependencies
echo "==> Running 'flutter pub get'..."
flutter pub get

# 3. Process Environment Variables and Security Validations
echo "==> Configuring build environment..."

# Enforce security: Ensure service_role or secret keys are never passed into client build
if [ -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ] || [ -n "${SUPABASE_SECRET_KEY:-}" ]; then
    echo "SECURITY ERROR: SUPABASE_SERVICE_ROLE_KEY or SUPABASE_SECRET_KEY detected in environment!" >&2
    echo "Secret service_role keys must NEVER be exposed to client-side Flutter Web builds." >&2
    exit 1
fi

MODE="${BACKEND_MODE:-supabase}"
echo "    BACKEND_MODE: ${MODE}"

DART_DEFINES=(
    "--dart-define=BACKEND_MODE=${MODE}"
)

if [ -n "${SUPABASE_URL:-}" ]; then
    echo "    SUPABASE_URL: provided via environment"
    DART_DEFINES+=("--dart-define=SUPABASE_URL=${SUPABASE_URL}")
else
    echo "    SUPABASE_URL: not set (using compile-time fallback)"
fi

if [ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]; then
    echo "    SUPABASE_PUBLISHABLE_KEY: provided via environment"
    DART_DEFINES+=("--dart-define=SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}")
else
    echo "    SUPABASE_PUBLISHABLE_KEY: not set (using compile-time fallback)"
fi

# 4. Execute Flutter Web Release Build
echo "==> Building Flutter Web in release mode..."
flutter build web --release "${DART_DEFINES[@]}"

echo "============================================================"
echo " Build successful! Output generated in build/web"
echo "============================================================"
ls -la build/web
