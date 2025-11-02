#!/bin/bash

[[ -z "${CRYPT_PASSPHRASE}" ]] && echo 'Missing CRYPT_PASSPHRASE environment variable'; exit 1; || CRYPT_PASSPHRASE="${CRYPT_PASSPHRASE}"

encrypt() {
    /usr/bin/nice /usr/bin/gpg -z 0 --batch --yes --output "$1.enc" --passphrase "$CRYPT_PASSPHRASE" --symmetric "$1"
}

encryptin() {
    /usr/bin/nice /usr/bin/gpg -z 0 --batch --yes --passphrase "$CRYPT_PASSPHRASE" --symmetric
}

decrypt() {
    out=$(basename "$1" '.enc')
    /usr/bin/gpg --batch --yes --output "$out" --passphrase "$CRYPT_PASSPHRASE" --decrypt "$1"
}
