#!/usr/bin/env python3
"""Run the pinned upstream DTS suite, whose wheel omits tests and schemas."""
import io
from pathlib import Path
import subprocess
import sys
import tempfile
from urllib.request import urlopen
from zipfile import ZipFile

REVISION = 'b3a826fc35947345245c8f1cc35bd4323f37295e'
URL = f'https://github.com/distributed-text-services/validator/archive/{REVISION}.zip'


def main():
    with tempfile.TemporaryDirectory(prefix='wdbplus-dts-validator-') as directory:
        with urlopen(URL, timeout=60) as response:
            archive = ZipFile(io.BytesIO(response.read()))
        archive.extractall(directory)
        source = Path(directory) / f'validator-{REVISION}'
        return subprocess.call([sys.executable, '-m', 'pytest', str(source / 'tests'), *sys.argv[1:]], cwd=source)


if __name__ == '__main__':
    sys.exit(main())
