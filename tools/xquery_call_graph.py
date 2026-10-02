#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import shutil
import subprocess
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "generated"
GRAPH_DOT = OUTPUT_DIR / "xquery-callgraph.dot"
GRAPH_JSON = OUTPUT_DIR / "xquery-callgraph.json"
GRAPH_SVG = OUTPUT_DIR / "xquery-callgraph.svg"

XQUERY_GLOBS = ("*.xq", "*.xqm", "*.xql", "*.xquery")
SKIP_DIRS = {".git", ".codex", "node_modules"}


@dataclass
class FunctionDecl:
    key: str
    namespace_uri: str
    declared_qname: str
    local_name: str
    arity: int
    file: str
    restxq: bool
    private: bool
    body: str


def iter_xquery_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.suffix in {".xq", ".xqm", ".xql", ".xquery"}:
            files.append(path)
    return sorted(files)


def strip_comments(text: str) -> str:
    out: list[str] = []
    i = 0
    depth = 0
    in_single = False
    in_double = False
    while i < len(text):
        pair = text[i : i + 2]
        ch = text[i]
        if depth == 0 and not in_double and ch == "'" and not in_single:
            in_single = True
            out.append(ch)
            i += 1
            continue
        if depth == 0 and in_single:
            out.append(ch)
            if ch == "'":
                in_single = False
            i += 1
            continue
        if depth == 0 and not in_single and ch == '"' and not in_double:
            in_double = True
            out.append(ch)
            i += 1
            continue
        if depth == 0 and in_double:
            out.append(ch)
            if ch == '"':
                in_double = False
            i += 1
            continue
        if not in_single and not in_double and pair == "(:":
            depth += 1
            i += 2
            continue
        if depth > 0 and pair == "(:":
            depth += 1
            i += 2
            continue
        if depth > 0 and pair == ":)":
            depth -= 1
            i += 2
            continue
        if depth == 0:
            out.append(ch)
        i += 1
    return "".join(out)


def scan_to_matching(
    text: str,
    start: int,
    opening: str,
    closing: str,
    *,
    file: str | None = None,
    context: str | None = None,
) -> tuple[str, int]:
    assert text[start] == opening
    i = start
    depth = 0
    in_single = False
    in_double = False
    chars: list[str] = []
    while i < len(text):
        ch = text[i]
        chars.append(ch)
        if not in_double and ch == "'" and (i == 0 or text[i - 1] != "\\"):
            in_single = not in_single
            i += 1
            continue
        if not in_single and ch == '"' and (i == 0 or text[i - 1] != "\\"):
            in_double = not in_double
            i += 1
            continue
        if in_single or in_double:
            i += 1
            continue
        if ch == opening:
            depth += 1
        elif ch == closing:
            depth -= 1
            if depth == 0:
                return "".join(chars), i + 1
        i += 1
    message = f"Unbalanced {opening}{closing} in input"
    details: list[str] = []
    if file:
        details.append(f"file={file}")
    if context:
        details.append(f"context={context}")
    if details:
        message += " (" + ", ".join(details) + ")"
    raise ValueError(message)


def count_params(param_text: str) -> int:
    params = [p.strip() for p in param_text.split(",") if p.strip()]
    return len(params)


def get_module_namespace(text: str) -> tuple[str | None, str | None]:
    match = re.search(r"module\s+namespace\s+([A-Za-z_][\w.-]*)\s*=\s*['\"]([^'\"]+)['\"]\s*;", text)
    if not match:
        return None, None
    return match.group(1), match.group(2)


def parse_imports(text: str) -> dict[str, str]:
    imports: dict[str, str] = {}
    for match in re.finditer(
        r"import\s+module\s+namespace\s+([A-Za-z_][\w.-]*)\s*=\s*['\"]([^'\"]+)['\"]",
        text,
    ):
        imports[match.group(1)] = match.group(2)
    return imports


def parse_functions(path: Path, text: str, module_prefix: str | None, module_uri: str | None) -> list[FunctionDecl]:
    if not module_prefix or not module_uri:
        return []
    functions: list[FunctionDecl] = []
    pattern = re.compile(
        r"declare\s+(?P<ann>(?:%[\w:-]+(?:\([^)]*\))?\s+)*)function\s+"
        r"(?P<qname>[A-Za-z_][\w.-]*:[A-Za-z_][\w.-]*)\s*\(",
        re.MULTILINE,
    )
    for match in pattern.finditer(text):
        qname = match.group("qname")
        file_name = str(path.relative_to(ROOT))
        params_with_parens, after_params = scan_to_matching(
            text,
            match.end() - 1,
            "(",
            ")",
            file=file_name,
            context=f"function declaration {qname}",
        )
        params = params_with_parens[1:-1]
        body_start = text.find("{", after_params)
        if body_start == -1:
            continue
        body_with_braces, after_body = scan_to_matching(
            text,
            body_start,
            "{",
            "}",
            file=file_name,
            context=f"function body {qname}",
        )
        body = body_with_braces[1:-1]
        local_name = qname.split(":", 1)[1]
        arity = count_params(params)
        annotations = match.group("ann") or ""
        functions.append(
            FunctionDecl(
                key=f"{module_uri}#{local_name}#{arity}",
                namespace_uri=module_uri,
                declared_qname=qname,
                local_name=local_name,
                arity=arity,
                file=file_name,
                restxq="%rest:" in annotations,
                private="%private" in annotations,
                body=body,
            )
        )
    return functions


def count_call_args(
    text: str,
    open_idx: int,
    *,
    file: str | None = None,
    context: str | None = None,
) -> tuple[int, int]:
    chunk, end_idx = scan_to_matching(text, open_idx, "(", ")", file=file, context=context)
    inner = chunk[1:-1].strip()
    if not inner:
        return 0, end_idx
    depth_round = depth_square = depth_curly = 0
    in_single = False
    in_double = False
    commas = 0
    for i, ch in enumerate(inner):
        if not in_double and ch == "'" and (i == 0 or inner[i - 1] != "\\"):
            in_single = not in_single
            continue
        if not in_single and ch == '"' and (i == 0 or inner[i - 1] != "\\"):
            in_double = not in_double
            continue
        if in_single or in_double:
            continue
        if ch == "(":
            depth_round += 1
        elif ch == ")":
            depth_round -= 1
        elif ch == "[":
            depth_square += 1
        elif ch == "]":
            depth_square -= 1
        elif ch == "{":
            depth_curly += 1
        elif ch == "}":
            depth_curly -= 1
        elif ch == "," and depth_round == depth_square == depth_curly == 0:
            commas += 1
    return commas + 1, end_idx


def parse_calls(body: str, *, file: str | None = None, caller: str | None = None) -> list[tuple[str, str, int]]:
    calls: list[tuple[str, str, int]] = []
    i = 0
    name_pattern = re.compile(r"[A-Za-z_][\w.-]*:[A-Za-z_][\w.-]*")
    while i < len(body):
        match = name_pattern.search(body, i)
        if not match:
            break
        qname = match.group(0)
        j = match.end()
        while j < len(body) and body[j].isspace():
            j += 1
        if j < len(body) and body[j] == "(":
            arity, end_idx = count_call_args(
                body,
                j,
                file=file,
                context=f"call {qname} inside {caller}" if caller else f"call {qname}",
            )
            prefix, local_name = qname.split(":", 1)
            calls.append((prefix, local_name, arity))
            i = end_idx
            continue
        i = match.end()
    return calls


def escape_dot(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def main() -> int:
    files = iter_xquery_files(ROOT)
    cleaned_texts: dict[Path, str] = {}
    module_by_uri: dict[str, dict[str, str]] = {}
    file_imports: dict[Path, dict[str, str]] = {}

    for path in files:
        cleaned = strip_comments(path.read_text(encoding="utf-8"))
        cleaned_texts[path] = cleaned
        prefix, uri = get_module_namespace(cleaned)
        if prefix and uri:
            module_by_uri[uri] = {
                "file": str(path.relative_to(ROOT)),
                "prefix": prefix,
            }
        file_imports[path] = parse_imports(cleaned)

    functions: list[FunctionDecl] = []
    functions_by_key: dict[str, FunctionDecl] = {}
    functions_by_namespace_local: dict[tuple[str, str], list[FunctionDecl]] = defaultdict(list)

    for path, cleaned in cleaned_texts.items():
        prefix, uri = get_module_namespace(cleaned)
        for function in parse_functions(path, cleaned, prefix, uri):
            functions.append(function)
            functions_by_key[function.key] = function
            functions_by_namespace_local[(function.namespace_uri, function.local_name)].append(function)

    edges: set[tuple[str, str]] = set()
    external_calls: set[tuple[str, str, str, int]] = set()

    for function in functions:
        path = ROOT / function.file
        prefix, uri = get_module_namespace(cleaned_texts[path])
        prefix_map = dict(file_imports[path])
        if prefix and uri:
            prefix_map[prefix] = uri

        for call_prefix, call_local, arity in parse_calls(
            function.body,
            file=function.file,
            caller=function.declared_qname,
        ):
            call_uri = prefix_map.get(call_prefix)
            if not call_uri:
                continue
            candidates = functions_by_namespace_local.get((call_uri, call_local), [])
            exact = [candidate for candidate in candidates if candidate.arity == arity]
            if exact:
                for candidate in exact:
                    edges.add((function.key, candidate.key))
            elif candidates:
                for candidate in candidates:
                    edges.add((function.key, candidate.key))
            else:
                external_calls.add((function.key, call_uri, f"{call_prefix}:{call_local}", arity))

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    node_groups: dict[str, list[FunctionDecl]] = defaultdict(list)
    for function in functions:
        node_groups[function.file].append(function)

    dot_lines = [
        "digraph XQueryCallGraph {",
        '  graph [rankdir="LR", fontsize=10, fontname="Helvetica"];',
        '  node [fontname="Helvetica", fontsize=10, style="filled", fillcolor="white"];',
        '  edge [fontname="Helvetica", fontsize=9, color="#666666"];',
    ]

    for file_name in sorted(node_groups):
        cluster_id = re.sub(r"[^A-Za-z0-9_]", "_", file_name)
        dot_lines.append(f'  subgraph "cluster_{cluster_id}" {{')
        dot_lines.append(f'    label="{escape_dot(file_name)}";')
        dot_lines.append('    color="#cccccc";')
        for function in sorted(node_groups[file_name], key=lambda item: (item.declared_qname, item.arity)):
            label = f"{function.declared_qname}#{function.arity}"
            if function.restxq:
                label += "\\nRESTXQ"
            node_id = escape_dot(function.key)
            shape = "box" if function.restxq else "ellipse"
            fill = "#ffe6cc" if function.restxq else ("#f3f3f3" if function.private else "white")
            dot_lines.append(
                f'    "{node_id}" [label="{escape_dot(label)}", shape="{shape}", fillcolor="{fill}"];'
            )
        dot_lines.append("  }")

    for source, target in sorted(edges):
        dot_lines.append(f'  "{escape_dot(source)}" -> "{escape_dot(target)}";')

    dot_lines.append("}")
    GRAPH_DOT.write_text("\n".join(dot_lines) + "\n", encoding="utf-8")

    graph = {
        "nodes": [
            {
                "id": function.key,
                "label": f"{function.declared_qname}#{function.arity}",
                "file": function.file,
                "restxq": function.restxq,
                "private": function.private,
                "namespace_uri": function.namespace_uri,
            }
            for function in sorted(functions, key=lambda item: (item.file, item.declared_qname, item.arity))
        ],
        "edges": [
            {"source": source, "target": target}
            for source, target in sorted(edges)
        ],
        "unresolved_repo_external_calls": [
            {
                "source": source,
                "namespace_uri": namespace_uri,
                "call": call,
                "arity": arity,
            }
            for source, namespace_uri, call, arity in sorted(external_calls)
        ],
    }
    GRAPH_JSON.write_text(json.dumps(graph, indent=2) + "\n", encoding="utf-8")

    dot_binary = shutil.which("dot")
    if dot_binary:
        subprocess.run(
            [dot_binary, "-Tsvg", str(GRAPH_DOT), "-o", str(GRAPH_SVG)],
            check=True,
        )

    print(f"Wrote {GRAPH_DOT.relative_to(ROOT)}")
    print(f"Wrote {GRAPH_JSON.relative_to(ROOT)}")
    if dot_binary:
        print(f"Wrote {GRAPH_SVG.relative_to(ROOT)}")
    else:
        print("Skipped SVG rendering because 'dot' is not installed")
    print(f"Functions: {len(functions)}")
    print(f"Edges: {len(edges)}")
    print(f"Unresolved external calls: {len(external_calls)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
