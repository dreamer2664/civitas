"""Pinned, hash-checked Linux tools stored in excluded cache, not saved deliverables.

The first use moves matching existing binaries out of ~/bin into ~/.cache/civitas;
~/bin keeps small symlinks. If a later snapshot omits the cache, verify.sh downloads
these exact releases again. No credentials are read or written.
"""
import hashlib
import io
from pathlib import Path
import platform
import shutil
import urllib.request
import zipfile

TOOLS={
    'lune':('lune-org/lune','v0.11.1','lune-0.11.1-linux-x86_64.zip','11f7dfa483b504b060fe80dd2bf80aa4ba10e11bdb6f6607f071519cb4873c69'),
    'rojo':('rojo-rbx/rojo','v7.7.1','rojo-7.7.1-linux-x86_64.zip','cb997ef82543670e51f2114898950bcabf9911efc3bf44f798524833e0e47f6e'),
    'selene':('Kampfkarren/selene','0.32.0','selene-0.32.0-linux.zip','54029f10caab1fffc84b5e2545003a3c72ae2541b7021ad125552eaf81e715b3'),
    'stylua':('JohnnyMorganz/StyLua','v2.6.0','stylua-linux-x86_64.zip','58f2f3056700c3a3c34b50da1c1e6316a24dc5713ecef436f01e77364e561270'),
    'luau-lsp':('JohnnyMorganz/luau-lsp','1.70.1','luau-lsp-linux-x86_64.zip','949d94eccc8b84b486dc994002502bab0078d879bf571f29ad42ec90aa9f5004'),
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def ensure_tools():
    if platform.system()!='Linux' or platform.machine() not in ('x86_64','AMD64'):
        raise RuntimeError('Pinned audit toolchain is Linux x86_64 only')
    cache=Path.home()/'.cache/civitas/toolchain'
    bindir=Path.home()/'bin'
    cache.mkdir(parents=True,exist_ok=True)
    bindir.mkdir(parents=True,exist_ok=True)
    for name,(repo,tag,asset,expected) in TOOLS.items():
        target,link=cache/name,bindir/name
        if not target.exists():
            if link.is_file() and not link.is_symlink() and digest(link)==expected:
                shutil.move(str(link),str(target))
            else:
                url=f'https://github.com/{repo}/releases/download/{tag}/{asset}'
                raw=urllib.request.urlopen(url,timeout=120).read()
                with zipfile.ZipFile(io.BytesIO(raw)) as archive:
                    member=next(p for p in archive.namelist() if p.rsplit('/',1)[-1]==name)
                    binary=archive.read(member)
                if hashlib.sha256(binary).hexdigest()!=expected:
                    raise RuntimeError(f'{name}: downloaded executable hash mismatch')
                target.write_bytes(binary)
        if digest(target)!=expected:
            raise RuntimeError(f'{name}: cached executable hash mismatch')
        target.chmod(0o755)
        if link.is_symlink():
            if link.resolve()==target.resolve():
                continue
            raise RuntimeError(f'{link}: refusing to replace an unrelated symlink')
        if link.exists():
            if digest(link)!=expected:
                raise RuntimeError(f'{link}: refusing to overwrite an unrelated executable')
            link.unlink()
        link.symlink_to(target)
    total=sum((cache/name).stat().st_size for name in TOOLS)
    print(f'Pinned audit tools ready in excluded cache: {total} bytes; ~/bin holds symlinks')


if __name__=='__main__':
    ensure_tools()
