#!/usr/bin/env python3
"""Build Roaster's JSON routing table from the OpenAPI YAML (requires PyYAML)."""
import json
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'edoc/rest2/v2.yaml'


def build():
    spec = yaml.safe_load(SOURCE.read_text())

    def resolve(value, seen=()):
        if isinstance(value, list):
            return [resolve(item, seen) for item in value]
        if not isinstance(value, dict):
            return value
        ref = value.get('$ref')
        if ref and ref.startswith('#/') and ref not in seen:
            target = spec
            for part in ref[2:].split('/'):
                target = target[part.replace('~1', '/').replace('~0', '~')]
            return resolve({**target, **{k: v for k, v in value.items() if k != '$ref'}}, (*seen, ref))
        return {key: resolve(item, seen) for key, item in value.items()}

    result = resolve(spec)
    # Roaster reads operation parameters, including those inherited from paths.
    for path in result['paths'].values():
        inherited = path.get('parameters', [])
        for method in ('get', 'head', 'post', 'put', 'patch', 'delete', 'options'):
            if method not in path or not inherited:
                continue
            operation = path[method]
            own = operation.get('parameters', [])
            overridden = {(p['name'], p['in']) for p in own}
            operation['parameters'] = [p for p in inherited if (p['name'], p['in']) not in overridden] + own
    SOURCE.with_suffix('.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    build()
