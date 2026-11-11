import * as chai from 'chai';
import { default as chaiHttp, request } from 'chai-http';
import { DOMParser } from '@xmldom/xmldom';
import { baseUrl, loginAsAdmin, uniqueSuffix, uploadResourceMultipart } from './rest2-helpers.js';

chai.use(chaiHttp);
const { expect } = chai;
const context = 'https://dtsapi.org/context/v1.0.json';
const suffix = uniqueSuffix();
const project = `dts-${suffix}`;
const resource = `${project}-text`;
const empty = `${project}-empty`;
const tei = (id, body) => `<TEI xmlns="http://www.tei-c.org/ns/1.0" xml:id="${id}"><teiHeader><fileDesc><titleStmt><title>DTS fixture</title></titleStmt><publicationStmt><p>Test</p></publicationStmt><sourceDesc><p>Test</p></sourceDesc></fileDesc></teiHeader><text><body>${body}</body></text></TEI>`;
const body = '<div xml:id="c1" type="chapter"><p xml:id="p1">First <hi>mixed</hi> paragraph.</p><p xml:id="p2">Second paragraph.</p></div><div xml:id="c2" type="chapter"><p xml:id="p3">Third paragraph.</p></div>' +
  Array.from({ length: 26 }, (_, i) => `<p xml:id="extra${i}">Extra ${i}</p>`).join('');
const get = (endpoint, params = {}) => request.execute(baseUrl).get(`/dts${endpoint}`).query(params);
const json = res => {
  expect(res).to.have.status(200);
  expect(res.headers['content-type']).to.match(/^application\/ld\+json/);
  return typeof res.body === 'object' && !Buffer.isBuffer(res.body) ? res.body : JSON.parse(res.text || res.body.toString());
};
const xml = res => {
  expect(res).to.have.status(200);
  expect(res.headers['content-type']).to.match(/^application\/tei\+xml/);
  return new DOMParser().parseFromString(res.text || res.body.toString(), 'application/xml');
};

describe('REST v2 DTS 1.0', function () {
  this.timeout(20000);
  let agent;
  let created = false;
  before(async function () {
    agent = request.agent(baseUrl);
    await loginAsAdmin(agent);
    expect(await agent.put(`/projects/data/subprojects/${project}`).send({ title: 'DTS tests', collection: project })).to.have.status(201);
    created = true;
    for (const [id, content] of [[resource, body], [empty, '<p>No identifiers</p>']]) {
      expect(await uploadResourceMultipart(agent.put(`/projects/${project}/resources/${id}`), '/edition', `${id}.xml`, tei(id, content))).to.have.status(201);
    }
  });
  after(async function () {
    if (agent) {
      try {
        // Delete only the uniquely named fixture project and its resources.
        if (created) expect(await agent.delete(`/projects/${project}`)).to.have.status(204);
      } finally { agent.close(); }
    }
  });

  it('advertises resolvable endpoint templates', async function () {
    const entry = json(await get(''));
    expect(entry).to.include({ '@context': context, '@type': 'EntryPoint', dtsVersion: '1.0' });
    for (const name of ['collection', 'navigation', 'document']) {
      expect(new URL(entry[name].split('{')[0]).pathname).to.equal(`/exist/apps/edoc/api/v2/dts/${name}`);
    }
  });
  it('returns the root collection and its pagination', async function () {
    const root = json(await get('/collection', { page: 1 }));
    expect(root).to.include({ '@id': 'data', '@type': 'Collection', totalParents: 0 });
    expect(root.member).to.be.an('array');
    expect(root.view).to.have.all.keys('@id', '@type', 'first', 'previous', 'next', 'last');
  });
  it('lists TEI resources with fixed resource templates', async function () {
    const collection = json(await get('/collection', { id: project }));
    expect(collection).to.include({ totalChildren: 2, totalParents: 1 });
    const item = collection.member.find(item => item['@id'] === resource);
    expect(item).to.include({ '@type': 'Resource', title: 'DTS fixture' });
    expect(item.mediaTypes).to.deep.equal(['application/tei+xml']);
    expect(item.citationTrees[0]['@type']).to.equal('CitationTree');
    expect(item.citationTrees[0]).not.to.have.property('identifier');
    expect(item.document).to.include(`resource=${resource}{&`);
  });
  it('returns parent collections for projects and resources', async function () {
    for (const [id, parent] of [[project, 'data'], [resource, project]]) {
      const result = json(await get('/collection', { id, nav: 'parents' }));
      expect(result.member.map(item => item['@id'])).to.include(parent);
    }
  });
  it('returns no children for resources', async function () {
    expect(json(await get('/collection', { id: resource })).member).to.deep.equal([]);
  });
  it('returns top-level units with null parents', async function () {
    const result = json(await get('/navigation', { resource, down: 1 }));
    expect(result['@type']).to.equal('Navigation');
    expect(new URL(result['@id']).searchParams.get('down')).to.equal('1');
    expect(result.member[0]).to.include({ identifier: 'c1', parent: null, level: 1, citeType: 'chapter' });
    expect(result.member.every(unit => unit.level === 1)).to.equal(true);
  });
  it('returns ref metadata without member when down is absent', async function () {
    const result = json(await get('/navigation', { resource, ref: 'p1' }));
    expect(result.ref).to.include({ identifier: 'p1', parent: 'c1', level: 2 });
    expect(result).not.to.have.property('member');
  });
  it('returns siblings including the selected unit for down=0', async function () {
    const result = json(await get('/navigation', { resource, ref: 'p1', down: 0 }));
    expect(result.member.map(unit => unit.identifier)).to.deep.equal(['p1', 'p2']);
  });
  it('returns top-level siblings for down=0', async function () {
    const result = json(await get('/navigation', { resource, ref: 'c1', down: 0 }));
    expect(result.member.slice(0, 2).map(unit => unit.identifier)).to.deep.equal(['c1', 'c2']);
    expect(result.member.every(unit => unit.parent === null)).to.equal(true);
  });
  it('includes the ref and descendants up to the requested relative depth', async function () {
    const result = json(await get('/navigation', { resource, ref: 'c1', down: 1 }));
    expect(result.member.map(unit => unit.identifier)).to.deep.equal(['c1', 'p1', 'p2']);
  });
  it('returns range metadata without member when down is absent', async function () {
    const result = json(await get('/navigation', { resource, start: 'p1', end: 'p2' }));
    expect(result.start.identifier).to.equal('p1');
    expect(result.end.identifier).to.equal('p2');
    expect(result).not.to.have.property('member');
  });
  it('returns a subtree in document order', async function () {
    const result = json(await get('/navigation', { resource, ref: 'c1', down: -1 }));
    expect(result.member.map(unit => unit.identifier)).to.deep.equal(['c1', 'p1', 'p2']);
  });
  it('returns a leaf itself when it has no descendants', async function () {
    expect(json(await get('/navigation', { resource, ref: 'p1', down: 4 })).member.map(unit => unit.identifier)).to.deep.equal(['p1']);
  });
  it('returns inclusive ranges and endpoint metadata', async function () {
    const result = json(await get('/navigation', { resource, start: 'p1', end: 'p3', down: -1 }));
    expect(result.start.identifier).to.equal('p1');
    expect(result.end.identifier).to.equal('p3');
    expect(result.member.map(unit => unit.identifier)).to.deep.equal(['p1', 'p2', 'c2', 'p3']);
  });
  it('paginates without losing request parameters', async function () {
    const first = json(await get('/navigation', { resource, down: -1 }));
    expect(first.member).to.have.length(25);
    const next = new URL(first.view.next);
    expect(next.searchParams.get('resource')).to.equal(resource);
    expect(next.searchParams.get('down')).to.equal('-1');
    const second = json(await get('/navigation', Object.fromEntries(next.searchParams)));
    expect([...first.member, ...second.member]).to.have.length(31);
    expect(new Set([...first.member, ...second.member].map(unit => unit.identifier)).size).to.equal(31);
  });
  it('returns an empty citation tree without errors', async function () {
    const result = json(await get('/navigation', { resource: empty }));
    expect(result.member).to.deep.equal([]);
    expect(result.resource.citationTrees).to.deep.equal([]);
  });
  it('returns empty members for tree-less navigation with selection parameters', async function () {
    const result = json(await get('/navigation', { resource: empty, ref: 'missing', down: 0, tree: 'missing' }));
    expect(result.member).to.deep.equal([]);
  });
  it('returns the full TEI document with a collection link', async function () {
    const res = await get('/document', { resource });
    const doc = xml(res);
    expect(doc.documentElement.localName).to.equal('TEI');
    expect(doc.documentElement.namespaceURI).to.equal('http://www.tei-c.org/ns/1.0');
    expect(doc.getElementsByTagNameNS('http://www.tei-c.org/ns/1.0', 'teiHeader').length).to.equal(1);
    expect(res.headers.link).to.include(`id=${resource}>; rel="collection"`);
  });
  it('wraps fragments and preserves mixed content', async function () {
    const doc = xml(await get('/document', { resource, ref: 'p1' }));
    const wrapper = doc.getElementsByTagNameNS('https://w3id.org/api/dts#', 'wrapper')[0];
    expect(wrapper.textContent).to.equal('First mixed paragraph.');
    expect(wrapper.getElementsByTagNameNS('http://www.tei-c.org/ns/1.0', 'hi').length).to.equal(1);
  });
  it('reconstructs ranges across containers without including adjacent text', async function () {
    const doc = xml(await get('/document', { resource, start: 'p2', end: 'p3' }));
    expect(doc.documentElement.textContent).to.equal('Second paragraph.Third paragraph.');
  });
  it('includes both endpoint subtrees in document ranges', async function () {
    const doc = xml(await get('/document', { resource, start: 'c1', end: 'c2' }));
    expect(doc.getElementsByTagNameNS('http://www.tei-c.org/ns/1.0', 'p').length).to.equal(3);
    expect(doc.documentElement.textContent).to.equal('First mixed paragraph.Second paragraph.Third paragraph.');
  });
  it('retrieves an inclusive single-unit range', async function () {
    const doc = xml(await get('/document', { resource, start: 'p2', end: 'p2' }));
    expect(doc.documentElement.textContent).to.equal('Second paragraph.');
  });
  it('ignores tree for whole-document retrieval', async function () {
    xml(await get('/document', { resource, tree: 'ignored' }));
  });
  for (const endpoint of ['/navigation', '/document']) {
    for (const [label, params, status] of [
      ['missing resource', {}, 400],
      ['unknown resource', { resource: 'does-not-exist', down: 1 }, 404],
      ['ref and start', { resource, ref: 'p1', start: 'p1', end: 'p2' }, 400],
      ['unpaired start', { resource, start: 'p1' }, 400],
      ['unpaired end', { resource, end: 'p1' }, 400],
      ['unknown reference', { resource, ref: 'not-found' }, 404],
      ['unknown tree', { resource, ref: 'p1', tree: 'not-found' }, 404],
      ['reversed range', { resource, start: 'p3', end: 'p1', down: -1 }, 400]
    ]) it(`${endpoint}: rejects ${label}`, async function () {
      expect(await get(endpoint, params)).to.have.status(status);
    });
  }
  for (const params of [{ resource }, { resource, down: 0 }, { resource, down: -2 }, { resource, down: 'bad' }, { resource, start: 'p1', end: 'p2', down: 0 }, { resource, down: 1, page: 0 }]) {
    it(`rejects invalid navigation ${JSON.stringify(params)}`, async function () {
      expect(await get('/navigation', params)).to.have.status(400);
    });
  }
  it('rejects unsupported document media types', async function () {
    expect(await get('/document', { resource, mediaType: 'text/plain' })).to.have.status(404);
  });
  for (const params of [{ id: 'not-found' }, { nav: 'invalid' }, { page: 0 }]) {
    it(`rejects invalid collection ${JSON.stringify(params)}`, async function () {
      expect(await get('/collection', params)).to.have.status(params.id ? 404 : 400);
    });
  }
});
