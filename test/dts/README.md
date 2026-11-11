# DTS 1.0 API tests

Deploy `edoc/rest2/dts.xqm` and the generated `edoc/rest2/v2.json` to eXist-db.
The YAML is the source of the routing definition; regenerate JSON after edits:

```sh
python3 tools/build_openapi.py
```

Run the fixture-based integration suite (same local server and admin credentials
as the other REST v2 suites):

```sh
npx mocha test/mocha/r2dts.js
```

It creates a uniquely named project with two TEI documents and removes it after
the run. It checks endpoint discovery, collections and parents, citation levels,
null parents, depth and siblings, inclusive ranges, pagination, TEI fragments
and mixed content, and invalid requests.

The default citation tree consists of elements with `xml:id` inside `tei:text`.
The nearest identified ancestor within `tei:text` is the unit's parent. The TEI
root and header are not citable units. No alternate citation trees are exposed.
Only registered readable TEI documents are advertised. Collections follow the
project metadata's registered files and project pointers. Page size is 25.

Install and run the upstream validator separately from Node dependencies:

```sh
python3 -m venv /tmp/wdbplus-dts-venv
/tmp/wdbplus-dts-venv/bin/pip install -r test/dts/requirements.txt
/tmp/wdbplus-dts-venv/bin/python test/dts/run-validator.py \
  --entry-endpoint=http://localhost:8080/exist/apps/edoc/api/v2/dts \
  --html=/tmp/wdbplus-dts-report.html
```

The runner downloads the pinned upstream tests and schemas into a temporary
directory because the upstream wheel omits them. It forwards arguments to pytest.

The validator is pinned to a revision supporting DTS 1.0. It traverses the
server's existing collections; use a test instance with representative TEI data.
The Mocha suite supplies deterministic behavioral coverage beyond schema checks.
Upstream: <https://github.com/distributed-text-services/validator>.
