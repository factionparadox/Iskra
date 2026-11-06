#!/usr/bin/env python3
"""guix-hash.py: the hash Guix wants in a package's (sha256 (base32 "...")), without Guix.

    build/guix-hash.py DIRECTORY     a git-fetch source: the NAR hash of the checkout (no .git)
    build/guix-hash.py FILE          a url-fetch source: the file's SHA-256

Both printed in Nix/Guix base32, as `guix hash -x -S nar DIR` and `guix hash FILE` print them.
Checked against hashes in Guix's own package definitions.
"""
import hashlib
import os
import stat
import sys

ALPHABET = '0123456789abcdfghijklmnpqrsvwxyz'   # Nix's base32 (no e, o, t, u)


def nix_base32(digest: bytes) -> str:
    n = len(digest)
    length = (n * 8 - 1) // 5 + 1
    out = []
    for k in range(length - 1, -1, -1):
        b = k * 5
        i, j = divmod(b, 8)
        c = digest[i] >> j
        if i + 1 < n:
            c |= digest[i + 1] << (8 - j)
        out.append(ALPHABET[c & 0x1f])
    return ''.join(out)


def nar_string(h, data: bytes):
    h.update(len(data).to_bytes(8, 'little'))
    h.update(data)
    h.update(b'\0' * ((8 - len(data) % 8) % 8))


def nar(h, path):
    st = os.lstat(path)
    nar_string(h, b'(')
    if stat.S_ISLNK(st.st_mode):
        nar_string(h, b'type'); nar_string(h, b'symlink')
        nar_string(h, b'target'); nar_string(h, os.readlink(path).encode())
    elif stat.S_ISDIR(st.st_mode):
        nar_string(h, b'type'); nar_string(h, b'directory')
        for name in sorted(os.listdir(path), key=lambda s: s.encode()):
            if name == '.git':
                continue
            nar_string(h, b'entry'); nar_string(h, b'(')
            nar_string(h, b'name'); nar_string(h, name.encode())
            nar_string(h, b'node'); nar(h, os.path.join(path, name))
            nar_string(h, b')')
    else:
        nar_string(h, b'type'); nar_string(h, b'regular')
        if st.st_mode & 0o100:
            nar_string(h, b'executable'); nar_string(h, b'')
        nar_string(h, b'contents')
        with open(path, 'rb') as f:
            data = f.read()
        nar_string(h, data)
    nar_string(h, b')')


def main(target):
    h = hashlib.sha256()
    if os.path.isdir(target):
        nar_string(h, b'nix-archive-1')
        nar(h, target)
    else:
        with open(target, 'rb') as f:
            h.update(f.read())
    print(nix_base32(h.digest()))


if __name__ == '__main__':
    main(sys.argv[1])
