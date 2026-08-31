export SCRIPT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))

# Read-only mirror of the Chromium tree, used to check patches against a
# version without cloning it. The build itself still clones from the canonical
# source in build.sh.
export CHROMIUM_MIRROR=${CHROMIUM_MIRROR:-https://raw.githubusercontent.com/chromium/chromium}

# Which Chromium version this repo targets, in precedence order:
#   $CHROMIUM_VERSION      one-off override, for trying a version out
#   chromium.version       a pin checked into the repo
#   vanadium/args.gn       whatever the Vanadium submodule is on (the default)
chromium_version() {
    if [ -n "${CHROMIUM_VERSION:-}" ]; then
        echo "$CHROMIUM_VERSION"
    elif [ -s "$SCRIPT_DIR/chromium.version" ]; then
        grep -m1 -oE '[0-9]+(\.[0-9]+){3}' "$SCRIPT_DIR/chromium.version"
    else
        # Empty if the submodule is not checked out; callers report that.
        grep -m1 -oE '[0-9]+(\.[0-9]+){3}' "$SCRIPT_DIR/vanadium/args.gn" 2>/dev/null
    fi
}

replace() {
    export org=$2 new=$3
    find $1 -type f -exec sed -i 's@'$org'@'$new'@g' {} \;
}

set_keys() {
    mkdir -p $SCRIPT_DIR/keys
    echo $LOCAL_TEST_JKS | base64 -d > $SCRIPT_DIR/keys/local.properties
    echo $STORE_TEST_JKS | base64 -d > $SCRIPT_DIR/keys/test.jks
    unset LOCAL_TEST_JKS
    unset STORE_TEST_JKS
}

sign_apk() {
    export apksigner=$(find $ANDROID_HOME/build-tools -name apksigner | sort | tail -n 1)
    source $SCRIPT_DIR/keys/local.properties
    $apksigner sign -verbose -ks $SCRIPT_DIR/keys/test.jks --ks-pass pass:$storePassword --key-pass pass:$keyPassword --ks-key-alias $keyAlias --out $2 $1 || exit 1
}

sign_aab() {
    source $SCRIPT_DIR/keys/local.properties
    jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore $SCRIPT_DIR/keys/test.jks -storepass $storePassword -keypass $keyPassword -signedjar $2 $1 $keyAlias || exit 1
}

version_lt() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}
