import * as chai from "chai";
import { default as chaiHttp, request } from "chai-http";
import * as xmldom from "@xmldom/xmldom";
import * as xpath from "xpath";
import {
  baseUrl,
  defaultResourcePath,
  ensureSharedProject,
  loginAs,
  loginAsAdmin,
  uniqueSuffix,
  unsupportedResourceContentType,
  uploadResourceMultipart
} from "./rest2-helpers.js";

chai.use(chaiHttp);
chai.config.includeStack = true;

const expect = chai.expect;
const parser = new xmldom.DOMParser();
const select = xpath.useNamespaces({
  api: "https://github.com/dariok/wdbplus/api/schema/v1",
  tei: "http://www.tei-c.org/ns/1.0",
  xml: "http://www.w3.org/XML/1998/namespace"
});

const sharedProjectId = "resourceTextProject";
const sharedCollection = "test50";

/**
 * @param {string} title
 * @param {string} xmlId
 */
function teiXml ( title, xmlId, bodyId = `frag-${uniqueSuffix()}` ) {
  return `<TEI xmlns="http://www.tei-c.org/ns/1.0" xml:id="${xmlId}"><teiHeader><fileDesc><titleStmt><title level="a">${title}</title></titleStmt><publicationStmt><p>test</p></publicationStmt><sourceDesc><p>test</p></sourceDesc></fileDesc></teiHeader><text><body><div xml:id="${bodyId}"><p>${title}</p></div></body></text></TEI>`;
}

/**
 * @param {ChaiHttp.Agent} agent
 * @param {string} id
 * @param {string} title
 */
function createProjectResource ( agent, id, title, bodyId = `frag-${uniqueSuffix()}` ) {
  const name = `${id}.xml`;
  const xml = teiXml(title, id, bodyId);
  return uploadResourceMultipart(
    agent.put(`/projects/${sharedProjectId}/resources/${id}`),
    defaultResourcePath,
    name,
    xml
  ).then((res) => {
    expect([201, 204]).to.include(res.status);
    return { id, name, xml, bodyId };
  });
}

/**
 * @type {{ id: string, bodyId: string }}
 */
let sharedGetResource;

describe("REST v2 resources", function() {
  describe("REST v2 resources – PUT, PATCH", function () {
    /**
     * @type {ChaiHttp.Agent}
     */
    let agent;

    before(function () {
      agent = request.agent(baseUrl);
      return loginAsAdmin(agent)
        .then(() => ensureSharedProject(agent, sharedProjectId, sharedCollection))
        .then(() => {
          const id = `resource-shared-get-${uniqueSuffix()}`;
          const bodyId = `frag-${uniqueSuffix()}`;
          return createProjectResource(agent, id, "resource shared get", bodyId)
            .then(() => {
              sharedGetResource = { id, bodyId };
            });
        });
    });

    after(function () {
      if ( agent ) {
        agent.close();
      }
    });

    it("PUT /resources/$id without login returns 401", function () {
      const id = `resource-put-auth-${uniqueSuffix()}`;
      return createProjectResource(agent, id, "resource put auth")
        .then(() => {
          return uploadResourceMultipart(
            request.execute(baseUrl).put(`/resources/${id}`),
            defaultResourcePath,
            `${id}.xml`,
            teiXml("resource put no auth", id)
          );
        })
        .then((res) => {
          expect(res).to.have.status(401);
        });
    });

    it("PUT /resources/$id with unsupported media type returns 415", function () {
      const id = `resource-put-unsupported-${uniqueSuffix()}`;
      return createProjectResource(agent, id, "resource put unsupported")
        .then(() => {
          return agent.put(`/resources/${id}`)
            .set("Content-Type", unsupportedResourceContentType)
            .send({ path: defaultResourcePath, file: { name: `${id}.xml`, type: "application/xml", data: teiXml("resource put unsupported 2", id) } });
        })
        .then((res) => {
          expect(res).to.have.status(415);
        });
    });

    it("PUT /resources/$id returns 404 for missing resources", function () {
      const id = `resource-put-missing-${uniqueSuffix()}`;
      return uploadResourceMultipart(
        agent.put(`/resources/${id}`),
        defaultResourcePath,
        `${id}.xml`,
        teiXml("resource put missing", id)
      ).then((res) => {
        expect(res).to.have.status(404);
      });
    });

    it("PUT /resources/$id returns 409 for mismatching stored path", function () {
      const id = `resource-put-conflict-${uniqueSuffix()}`;
      return createProjectResource(agent, id, "resource put conflict")
        .then(() => {
          return uploadResourceMultipart(
            agent.put(`/resources/${id}`),
            "/other-path",
            `${id}.xml`,
            teiXml("resource put conflict 2", id)
          );
        })
        .then((res) => {
          expect(res).to.have.status(409);
        });
    });

    it("PUT /resources/$id returns 204 for identical content", function () {
      const id = `resource-put-identical-${uniqueSuffix()}`;
      const xml = teiXml("resource put identical", id, `frag-${uniqueSuffix()}`);
      return uploadResourceMultipart(
        agent.put(`/projects/${sharedProjectId}/resources/${id}`),
        defaultResourcePath,
        `${id}.xml`,
        xml
      )
        .then((res) => {
          expect([201, 204]).to.include(res.status);
          return uploadResourceMultipart(
            agent.put(`/resources/${id}`),
            defaultResourcePath,
            `${id}.xml`,
            xml
          );
        })
        .then((res) => {
          expect(res).to.have.status(204);
        });
    });

    it("PUT /resources/$id updates the stored file", function () {
      const id = `resource-put-update-${uniqueSuffix()}`;
      const firstBodyId = `frag-${uniqueSuffix()}`;
      const secondBodyId = `frag-${uniqueSuffix()}`;
      return createProjectResource(agent, id, "resource put v1", firstBodyId)
        .then(() => {
          return uploadResourceMultipart(
            agent.put(`/resources/${id}`),
            defaultResourcePath,
            `${id}.xml`,
            teiXml("resource put v2", id, secondBodyId)
          );
        })
        .then((res) => {
          expect(res).to.have.status(204);
          return request.execute(baseUrl)
            .get(`/resources/${id}`)
            .set("Accept", "application/tei+xml");
        })
        .then((res) => {
          expect(res).to.have.status(200);
          const doc = parser.parseFromString(res.body.toString(), "application/xml");
          expect(select("string(//tei:div/@xml:id)", doc)).to.equal(secondBodyId);
        });
    });

    it("PATCH /resources/$id updates a fragment by xml:id", function () {
      const id = `resource-patch-${uniqueSuffix()}`;
      const bodyId = `frag-${uniqueSuffix()}`;
      const replacement = `<div xmlns="http://www.tei-c.org/ns/1.0" xml:id="${bodyId}"><p>patched fragment</p></div>`;
      return createProjectResource(agent, id, "resource patch", bodyId)
        .then(() => {
          return agent.patch(`/resources/${id}`)
            .set("Content-Type", "application/xml")
            .send(replacement);
        })
        .then((res) => {
          expect(res).to.have.status(204);
          return request.execute(baseUrl)
            .get(`/resources/${id}`)
            .set("Accept", "application/tei+xml");
        })
        .then((res) => {
          const doc = parser.parseFromString(res.body.toString(), "application/xml");
          expect(select(`normalize-space(string(//tei:div[@xml:id = "${bodyId}"]/tei:p))`, doc)).to.equal("patched fragment");
        });
    });

    it("PATCH /resources/$id returns 400 for fragments without xml:id", function () {
      const id = `resource-patch-invalid-${uniqueSuffix()}`;
      return createProjectResource(agent, id, "resource patch invalid")
        .then(() => {
          return agent.patch(`/resources/${id}`)
            .set("Content-Type", "application/xml")
            .send("<div xmlns=\"http://www.tei-c.org/ns/1.0\"><p>invalid</p></div>");
        })
        .then((res) => {
          expect(res).to.have.status(400);
        });
    });
  });

  describe("REST v2 resources – GET", function() {
    /**
     * @type {ChaiHttp.Agent}
     */
    let agent;

    before(function () {
      if ( sharedGetResource ) {
        return;
      }

      agent = request.agent(baseUrl);
      const id = `resource-shared-get-fallback-${uniqueSuffix()}`;
      const bodyId = `frag-${uniqueSuffix()}`;

      return loginAsAdmin(agent)
        .then(() => ensureSharedProject(agent, sharedProjectId, sharedCollection))
        .then(() => createProjectResource(agent, id, "resource shared get fallback", bodyId))
        .then(() => {
          sharedGetResource = { id, bodyId };
        });
    });

    after(function () {
      if ( agent ) {
        agent.close();
      }
    });

    it("GET /resources/$id returns 404 for missing resources", function () {
      return request.execute(baseUrl)
        .get(`/resources/missing-${uniqueSuffix()}`)
        .set("Accept", "application/xml")
        .then((res) => {
          expect(res).to.have.status(404);
        });
    });

    it("GET /resources/$id returns stored TEI content", function () {
      return request.execute(baseUrl)
        .get(`/resources/${sharedGetResource.id}`)
        .set("Accept", "application/tei+xml")
        .then((res) => {
          expect(res).to.have.status(200);
          expect(res.header["content-type"]).to.include("application/tei+xml");
          const doc = parser.parseFromString(res.body.toString(), "application/xml");
          expect(select("string(/tei:TEI/@xml:id)", doc)).to.equal(sharedGetResource.id);
        });
    });

    it("HEAD /resources/$id returns 204 with Last-Modified", function () {
      return request.execute(baseUrl).head(`/resources/${sharedGetResource.id}`)
        .then((res) => {
          expect(res).to.have.status(200);
          expect(res).to.have.header("last-modified");
        });
    });

    it("OPTIONS /resources/$id returns 204 with Allow", function () {
      return request.execute(baseUrl).options(`/resources/${sharedGetResource.id}`)
        .then((res) => {
          expect(res).to.have.status(200);
          expect(res).to.have.header("allow");
          expect(res.header.allow).to.include("GET");
          // TODO: adjust when roaster has been fixed
          //expect(res.header.allow).to.include("PATCH");
          expect(res.header.allow).to.include("DELETE");
        });
    });

    it("GET /resources/$id/views lists available views as XML", function () {
      return request.execute(baseUrl)
        .get(`/resources/${sharedGetResource.id}/views`)
        .set("Accept", "application/xml")
        .then((res) => {
          expect(res).to.have.status(200);
          const doc = parser.parseFromString(res.body.toString(), "application/xml");
          expect(doc.documentElement.nodeName).to.equal("list");
          expect(select("count(/api:list/api:view)", doc)).to.be.greaterThan(0);
        });
    });

    /* TODO: make sure the correct XSLT is selected when passing "default" or e.g. "md" and for different types
    *       This means we need to provide an additional XSLT and at least one non-default view and something that is not HTML
    */
    it("GET /resources/$id/views/{view} resolves a listed view", function () {
      let firstView;

      return request.execute(baseUrl)
        .get(`/resources/${sharedGetResource.id}/views`)
        .set("Accept", "application/xml")
        .then((res) => {
          const doc = parser.parseFromString(res.body.toString(), "application/xml");
          firstView = select("string((/api:list/api:view/@view)[1])", doc);
          expect(firstView).to.be.a("string").and.not.to.equal("");
          return request.execute(baseUrl)
            .get(`/resources/${sharedGetResource.id}/views/${firstView}`)
            .set("Accept", "text/html");
        })
        .then((res) => {
          expect(res).to.have.status(200);
        });
    });

    it("GET /resources/$id/views/{view} returns 406 for missing views", function () {
      return request.execute(baseUrl)
        .get(`/resources/${sharedGetResource.id}/views/missing-view-${uniqueSuffix()}`)
        .set("Accept", "application/xml")
        .then((res) => {
          expect(res).to.have.status(406);
        });
    });

    it("GET /resources/byPid/$pid returns 404 for unknown PIDs", function () {
      return request.execute(baseUrl)
        .get(`/resources/byPid/uuid-${uniqueSuffix()}`)
        .then((res) => {
          expect(res).to.have.status(404);
        });
    });
  });

  describe("REST v2 resources – DELETE", function() {
    /**
     * @type {ChaiHttp.Agent}
     */
    let agent;

    before(function () {
      agent = request.agent(baseUrl);
      return loginAsAdmin(agent)
        .then(() => ensureSharedProject(agent, sharedProjectId, sharedCollection));
    });

    after(function () {
      if ( agent ) {
        agent.delete("/projects/" + sharedProjectId)
          .then((res) => {
            console.log(res.body);
            expect(res).to.have.status(204);
            agent.close();
          });
      }
    });
    
    it("DELETE /resources/$id removes the resource", function () {
      const id = `resource-delete-${uniqueSuffix()}`;
      return createProjectResource(agent, id, "resource delete")
        .then(() => agent.delete(`/resources/${id}`))
        .then((res) => {
          expect(res).to.have.status(204);
          return request.execute(baseUrl)
            .get(`/resources/${id}`)
            .set("Accept", "application/xml");
        })
        .then((res) => {
          expect(res).to.have.status(404);
        });
    });
  });
});