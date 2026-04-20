import * as chai from "chai";
import { default as chaiHttp, request } from "chai-http";
import * as xmldom from "@xmldom/xmldom";
import { JSDOM } from "jsdom";
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

const expect  = chai.expect;
const parser  = new xmldom.DOMParser();
const select  = xpath.useNamespaces({
    api: "https://github.com/dariok/wdbplus/api/schema/v1",
    index: "https://github.com/dariok/wdbplus/index"
  });

const sharedProjectId = "project40";
const sharedCollection = "test40";

/**
 * @param {string} title
 * @param {string | undefined} [xmlId]
 */
function teiXml( title, xmlId ) {
  const idAttr = xmlId ? ` xml:id="${xmlId}"` : "";
  return `<TEI xmlns="http://www.tei-c.org/ns/1.0"${idAttr}><teiHeader><fileDesc><titleStmt><title level="a">${title}</title></titleStmt><publicationStmt><p>test</p></publicationStmt><sourceDesc><p>test</p></sourceDesc></fileDesc></teiHeader><text><body><p>${title}</p></body></text></TEI>`;
}

/**
 * @type {string}
 */
let idCreatedByPost;

describe("REST v2 projects", function () {
  describe("OPTIONS", function () {
    it("OPTIONS /projects", function ( ) {
      return request.execute(baseUrl)
        .options("/projects")
        .then(( res ) => {
          expect(res).to.have.status(200);
          // TODO: adjust when roaster has been fixed
          // expect(res).to.have.header("allow", "GET, POST, OPTIONS");
          expect(res.header.allow).to.include("GET");
        });
      });
  });

  describe("GET", function () {
    it("GET /projects XML", function ( ) {
      return request.execute(baseUrl)
        .get("/projects")
        .set("Accept", "application/xml")
        .then(( res ) => {
          expect(res).to.have.status(200);
          expect(res).to.have.header("content-type", "application/xml");
          let doc = parser.parseFromString(res.body.toString(), "application/xml");
          expect(doc.documentElement.nodeName).to.equal("list");
          expect(doc.getElementsByTagName('project')).not.to.be.empty;
          expect(doc.getElementsByTagName('project')[0].getAttribute('label')).to.equal("wdb+ main project collection");
        });
    });
    it("GET /projects JSON", function ( ) {
      return request.execute(baseUrl)
        .get("/projects")
        .set("Accept", "application/json")
        .then(( res ) => {
          expect(res).to.have.status(200);
          expect(res).to.have.header("content-type", "application/json");
          expect(res.body).to.have.property("projects");
          expect(res.body.projects).to.be.an("array");
          expect(res.body.projects[0]).to.have.property("label", "wdb+ main project collection");
        });
    });
  });

  describe("POST", function () {
    /**
     * @type {ChaiHttp.Agent}
     */
    let agent;
    
    before(function () {
      agent = request.agent(baseUrl);
      return loginAsAdmin(agent);
    });

    after(function () {
      if ( agent ) {
        agent.close();
      }
    });

    it("POST /projects/data/subprojects to create a new main project without ID and without login", function ( ) {
      return request.execute(baseUrl)
          .post("/projects/data/subprojects")
          .send({ title: "test", collection: "collection" })
          .then( ( res ) => {
            expect(res).to.have.status(401);
          } );
    });
    it("POST /projects/data/subprojects to create without ID with login, but send an ID", function ( ) {
      return agent.post("/projects/data/subprojects")
          .set("Content-Type", "application/json")
          .send({
            title: "New Project without ID",
            short: "Created by unit test",
            collection: "test10",
            id: "test10"
          })
          .then(( res ) => {
            expect(res).to.have.status(422);
          });
    });
    it("POST /projects/data/subprojects to create without ID with login, but leave out a title", function ( ) {
      return agent.post("/projects/data/subprojects")
          .set("Content-Type", "application/json")
          .send({
            short: "Created by unit test",
            collection: "test20"
          })
          .then(( res ) => {
            expect(res).to.have.status(422);
          });
    });
    it("POST /projects/$parent/subprojects to create without ID, with login, but use a wrong parent", function () {
      return agent.post("/projects/missing-parent/subprojects")
          .set("Content-Type", "application/json")
          .send({
            title: "Created by unit test",
            collection: "test21"
          })
          .then(( res ) => {
            expect(res).to.have.status(404);
          });
    });
    it("POST /projects/data/subprojects to create project without ID with login", function ( ) {
      return agent.post("/projects/data/subprojects")
          .set("Content-Type", "application/json")
          .set("X-Info", "true")
          .send({
            title: "New Project without ID",
            short: "Created by unit test",
            collection: "test30"
          })
          .then(( res ) => {
            idCreatedByPost = res.text;
            expect(res).to.have.status(201);
          });
    });
    it("POST /projects/data/subprojects to create project without ID with login, with collection that’s already in use", function ( ) {
      return agent.post("/projects/data/subprojects")
          .set("Content-Type", "application/json")
          .set("X-Info", "true")
          .send({
            title: "New Project without ID",
            short: "Created by unit test",
            collection: "test30"
          })
          .then(( res ) => {
            expect(res).to.have.status(409);
          });
    });
    it("PUT /projects/data/subprojects/project to create project with ID with login", function ( ) {
      return agent.put(`/projects/data/subprojects/${sharedProjectId}`)
          .set("Content-Type", "application/json")
          .set("X-Info", "true")
          .send({
            title: "New Project with ID",
            short: "Created by unit test",
            collection: sharedCollection
          })
          .then(( res ) => {
            expect(res).to.have.status(201);
          });
    });
  });

  describe("GET by ID", function () {
    it("GET /projects/data XML", function ( ) {
      return request.execute(baseUrl)
        .get("/projects/data")
        .set("Accept", "application/xml")
        .then(( res ) => {
          expect(res).to.have.status(200);
          expect(res).to.have.header("content-type", "application/xml");

          let xml = parser.parseFromString(res.body.toString(), "application/xml");
          expect(xml.documentElement.nodeName).to.equal("contents");
          expect(xml.getElementsByTagName('project')).not.to.be.empty;
          
          let selected = select("//api:project[@label='New Project with ID']", xml);
          expect(selected).not.to.be.empty;
        });
    });
    it("GET /projects/data JSON", function ( ) {
      return request.execute(baseUrl)
        .get("/projects/data")
        .set("Accept", "application/json")
        .then(( res ) => {
          expect(res).to.have.status(200);
          expect(res).to.have.header("content-type", "application/json");
          expect(res.body).to.have.property("projects");
          expect(res.body.projects).to.be.an("array");
          let filtered = res.body.projects.filter((/** @type {{ label: string; }} */ el) => el?.label === "New Project with ID");
          expect(filtered).not.to.be.empty; 
        });
    });
    it("GET /projects/data/views", function ( ) {
      return request.execute(baseUrl)
        .get("/projects/data/views")
        .set("Accept", "application/json")
        .then(( res ) => {
          expect(res).to.have.status(200);
          expect(res.body).to.have.property("views");
          expect(res.body.views).to.be.an("array");
        });
    });
    it("GET /projects/dat/views", function ( ) {
      return request.execute(baseUrl)
        .get("/projects/dat/views")
        .set("Accept", "application/xml")
        .then(( res ) => {
          expect(res).to.have.status(404);
        });
    });
  });

  describe("GET subprojects", function () {
    it("GET /projects/data/subprojects XML", function ( ) {
      return request.execute(baseUrl)
        .get("/projects/data/subprojects")
        .set("Accept", "application/xml")
        .then(( res ) => {
          expect(res).to.have.status(200);
          expect(res).to.have.header("content-type", "application/xml");

          let xml = parser.parseFromString(res.body.toString(), "application/xml");
          expect(xml.documentElement.nodeName).to.equal("list");
          let selected = select("//api:project[@label='New Project with ID']", xml);
          expect(selected).not.to.be.empty;
        });
    });
    it("GET /projects/data/subprojects JSON", function ( ) {
      return request.execute(baseUrl)
        .get("/projects/data/subprojects")
        .set("Accept", "application/json")
        .then(( res ) => {
          expect(res).to.have.status(200);
          expect(res).to.have.header("content-type", "application/json");
          expect(res.body).to.have.property("projects");
          expect(res.body.projects).to.be.an("array");
          let filtered = res.body.projects.filter((/** @type {{ label: string; }} */ el) => el?.label === "New Project with ID");
          expect(filtered).not.to.be.empty;
        });
    });
    it("GET /projects/missing-parent/subprojects", function ( ) {
      return request.execute(baseUrl)
        .get("/projects/missing-parent/subprojects")
        .set("Accept", "application/xml")
        .then(( res ) => {
          expect(res).to.have.status(404);
        });
    });
  });

  describe("POST project resources", function () {
    /**
     * @type {ChaiHttp.Agent}
     */
    let agent;
    
    before(function () {
      agent = request.agent(baseUrl);
      return loginAsAdmin(agent);
    });

    after(function () {
      if ( agent ) {
        agent.close();
      }
    });

    before(function () {
      ensureSharedProject(agent, sharedProjectId, sharedCollection);
    });

    after(function () {
      if (agent) {
        agent.close();
      }
    });

    it("POST /projects/$ed/resources without login", function () {
      return uploadResourceMultipart(
        request.execute(baseUrl).post(`/projects/${sharedProjectId}/resources`),
        defaultResourcePath,
        `unauth-${uniqueSuffix()}.xml`,
        teiXml("unauthorized post", "unauth-post")
      )
        .then((res) => {
          expect(res).to.have.status(401);
        });
    });

    it("POST /projects/$ed/resources with unsupported media type", function () {
      const name = `unsupported-${uniqueSuffix()}.xml`;
      const xml = teiXml("unsupported media type post");
      return agent.post(`/projects/${sharedProjectId}/resources`)
        .set("Content-Type", unsupportedResourceContentType)
        .send({ path: defaultResourcePath, file: { name, type: "application/xml", data: xml } })
        .then((res) => {
          expect(res).to.have.status(415);
        });
    });

    it("POST /projects/$ed/resources with non-privileged user", function () {
      const testAgent = request.agent(baseUrl);
      return loginAs(testAgent, "test", "test")
        .then(() => {
          return uploadResourceMultipart(
            testAgent.post(`/projects/${sharedProjectId}/resources`),
            defaultResourcePath,
            `forbidden-${uniqueSuffix()}.xml`,
            teiXml("forbidden post")
          );
        })
        .then((res) => {
          expect(res).to.have.status(403);
        })
        .finally(() => {
          testAgent.close();
        });
    });

    it("POST /projects/$ed/resources with a missing project", function () {
      return uploadResourceMultipart(
        request.execute(baseUrl).post(`/projects/missing-${uniqueSuffix()}/resources`),
        defaultResourcePath,
        `missing-project-${uniqueSuffix()}.xml`,
        teiXml("missing project post", "missing-post")
      )
        .then((res) => {
          expect(res).to.have.status(404);
        });
    });

    it("POST /projects/$ed/resources with wrong payload keys", function () {
      return uploadResourceMultipart(
        agent.post(`/projects/${sharedProjectId}/resources`),
        defaultResourcePath,
        `wrong-keys-${uniqueSuffix()}.xml`,
        teiXml("wrong keys"),
        { id: "not-allowed" }
      )
        .then((res) => {
          expect(res).to.have.status(422);
        });
    });

    it("POST /projects/$ed/resources with invalid XML", function () {
      return uploadResourceMultipart(
        agent.post(`/projects/${sharedProjectId}/resources`),
        defaultResourcePath,
        `invalid-${uniqueSuffix()}.xml`,
        "<broken><xml>"
      )
        .then((res) => {
          expect(res).to.have.status(422);
        });
    });

    it("POST /projects/$ed/resources creates a new XML resource", function () {
      const path = defaultResourcePath;
      const name = `created-${uniqueSuffix()}.xml`;
      const xml = teiXml("created by POST without ID");
      
      return uploadResourceMultipart(
        agent.post(`/projects/${sharedProjectId}/resources`),
        path,
        name,
        xml
      )
        .then((res) => {
          expect(res).to.have.status(201);
        });
    });

    it("POST /projects/$ed/resources returns 409 for duplicate xml:id", function () {
      const xmlId = `duplicate-id-${uniqueSuffix()}`
          , firstPath = defaultResourcePath
          , firstName = `id1-${uniqueSuffix()}.xml`
          , firstXml = teiXml("first duplicate id", xmlId)
          , secondPath = defaultResourcePath
          , secondName = `id2-${uniqueSuffix()}.xml`
          , secondXml = teiXml("second duplicate id", xmlId);

      return uploadResourceMultipart(
        agent.post(`/projects/${sharedProjectId}/resources`),
        firstPath,
        firstName,
        firstXml
      )
        .then((res) => {
          expect(res).to.have.status(201);
          return uploadResourceMultipart(
            agent.post(`/projects/${sharedProjectId}/resources`),
            secondPath,
            secondName,
            secondXml
          );
        })
        .then((res) => {
          expect(res).to.have.status(409);
        });
    });

    it("POST /projects/$ed/resources returns 409 for duplicate hash", function () {
      const xml = teiXml(`hash-duplicate-${uniqueSuffix()}`);
      const firstPath = defaultResourcePath;
      const firstName = `hash1-${uniqueSuffix()}.xml`;
      const secondPath = defaultResourcePath;
      const secondName = `hash2-${uniqueSuffix()}.xml`;

      return uploadResourceMultipart(
        agent.post(`/projects/${sharedProjectId}/resources`),
        firstPath,
        firstName,
        xml
      )
        .then((res) => {
          expect(res).to.have.status(201);
          return uploadResourceMultipart(
            agent.post(`/projects/${sharedProjectId}/resources`),
            secondPath,
            secondName,
            xml
          );
        })
        .then((res) => {
          expect(res).to.have.status(409);
        });
    });
  });

  describe("PUT project resources", function () {
    /**
     * @type {ChaiHttp.Agent}
     */
    let agent;
    
    before(function () {
      agent = request.agent(baseUrl);
      return loginAsAdmin(agent);
    });

    after(function () {
      if ( agent ) {
        agent.close();
      }
    });
    
    before(function () {
      ensureSharedProject(agent, sharedProjectId, sharedCollection);
    });

    after(function () {
      if (agent) {
        agent.close();
      }
    });

    it("PUT /projects/$ed/resources/$id without login", function () {
      return uploadResourceMultipart(
        request.execute(baseUrl).put(`/projects/${sharedProjectId}/resources/no-login-${uniqueSuffix()}`),
        defaultResourcePath,
        `unauth-put-${uniqueSuffix()}.xml`,
        teiXml("unauthorized put")
      )
        .then((res) => {
          expect(res).to.have.status(401);
        });
    });

    it("PUT /projects/$ed/resources/$id with unsupported media type", function () {
      const name = `unsupported-put-${uniqueSuffix()}.xml`;
      const xml = teiXml("unsupported media type put");
      return agent.put(`/projects/${sharedProjectId}/resources/unsupported-${uniqueSuffix()}`)
        .set("Content-Type", unsupportedResourceContentType)
        .send({ path: defaultResourcePath, file: { name, type: "application/xml", data: xml } })
        .then((res) => {
          expect(res).to.have.status(415);
        });
    });

    it("PUT /projects/$ed/resources/$id with non-privileged user", function () {
      const testAgent = request.agent(baseUrl);
      return loginAs(testAgent, "test", "test")
        .then(() => {
          return uploadResourceMultipart(
            testAgent.put(`/projects/${sharedProjectId}/resources/forbidden-${uniqueSuffix()}`),
            defaultResourcePath,
            `forbidden-put-${uniqueSuffix()}.xml`,
            teiXml("forbidden put")
          );
        })
        .then((res) => {
          expect(res).to.have.status(403);
        })
        .finally(() => {
          testAgent.close();
        });
    });

    it("PUT /projects/$ed/resources/$id with wrong payload keys", function () {
      return uploadResourceMultipart(
        agent.put(`/projects/${sharedProjectId}/resources/wrong-keys-${uniqueSuffix()}`),
        defaultResourcePath,
        `wrong-keys-put-${uniqueSuffix()}.xml`,
        teiXml("wrong keys put"),
        { invalid: true }
      )
        .then((res) => {
          expect(res).to.have.status(422);
        });
    });

    it("PUT /projects/$ed/resources/$id with a missing project", function () {
      return uploadResourceMultipart(
        request.execute(baseUrl).put(`/projects/missing-${uniqueSuffix()}/resources/missing-id-${uniqueSuffix()}`),
        defaultResourcePath,
        `missing-project-put-${uniqueSuffix()}.xml`,
        teiXml("missing project put")
      )
        .then((res) => {
          expect(res).to.have.status(404);
        });
    });

    it("PUT /projects/$ed/resources/$id with invalid XML", function () {
      return uploadResourceMultipart(
        agent.put(`/projects/${sharedProjectId}/resources/invalid-xml-${uniqueSuffix()}`),
        defaultResourcePath,
        `invalid-xml-put-${uniqueSuffix()}.xml`,
        "<broken><xml>"
      )
        .then((res) => {
          expect(res).to.have.status(422);
        });
    });

    it("PUT /projects/$ed/resources/$id with mismatching xml:id in content", function () {
      const urlId = `url-id-${uniqueSuffix()}`;
      const xmlId = `xml-id-${uniqueSuffix()}`;
      return uploadResourceMultipart(
        agent.put(`/projects/${sharedProjectId}/resources/${urlId}`),
        defaultResourcePath,
        `mismatch-${uniqueSuffix()}.xml`,
        teiXml("id mismatch", xmlId)
      )
        .then((res) => {
          expect(res).to.have.status(422);
        });
    });

    it("PUT /projects/$ed/resources/$id creates a new XML resource (201)", function () {
      const id = `put-created-${uniqueSuffix()}`;
      const path = defaultResourcePath;
      const name = `created-${uniqueSuffix()}.xml`;
      const xml = teiXml("put created");

      return uploadResourceMultipart(
        agent.put(`/projects/${sharedProjectId}/resources/${id}`),
        path,
        name,
        xml
      )
        .then((res) => {
          expect(res).to.have.status(201);
        });
    });

    it("PUT /projects/$ed/resources/$id returns 204 for identical content", function () {
      const id = `put-identical-${uniqueSuffix()}`;
      const path = defaultResourcePath;
      const name = `identical-${uniqueSuffix()}.xml`;
      const xml = teiXml("put identical");

      return uploadResourceMultipart(
        agent.put(`/projects/${sharedProjectId}/resources/${id}`),
        path,
        name,
        xml
      )
        .then((res) => {
          expect(res).to.have.status(201);
          return uploadResourceMultipart(
            agent.put(`/projects/${sharedProjectId}/resources/${id}`),
            path,
            name,
            xml
          );
        })
        .then((res) => {
          expect(res).to.have.status(204);
        });
    });

    it("PUT /projects/$ed/resources/$id returns 204 for same ID/path with changed content", function () {
      const id = `put-update-${uniqueSuffix()}`;
      const path = defaultResourcePath;
      const name = `update-${uniqueSuffix()}.xml`;
      const firstXml = teiXml("put update v1");
      const secondXml = teiXml("put update v2");

      return uploadResourceMultipart(
        agent.put(`/projects/${sharedProjectId}/resources/${id}`),
        path,
        name,
        firstXml
      )
        .then((res) => {
          expect(res).to.have.status(201);
          return uploadResourceMultipart(
            agent.put(`/projects/${sharedProjectId}/resources/${id}`),
            path,
            name,
            secondXml
          );
        })
        .then((res) => {
          expect(res).to.have.status(204);
        });
    });

    it("PUT /projects/$ed/resources/$id returns 409 for existing path with different ID", function () {
      const existingId = `path-existing-${uniqueSuffix()}`;
      const otherId = `path-other-${uniqueSuffix()}`;
      const path = defaultResourcePath;
      const name = `path-conflict-${uniqueSuffix()}.xml`;
      const xml = teiXml("path conflict");

      return uploadResourceMultipart(
        agent.put(`/projects/${sharedProjectId}/resources/${existingId}`),
        path,
        name,
        xml
      )
        .then((res) => {
          expect(res).to.have.status(201);
          return uploadResourceMultipart(
            agent.put(`/projects/${sharedProjectId}/resources/${otherId}`),
            path,
            name,
            xml
          );
        })
        .then((res) => {
          expect(res).to.have.status(409);
        });
    });

    it("PUT /projects/$ed/resources/$id returns 409 for existing ID with different path", function () {
      const id = `id-conflict-${uniqueSuffix()}`;
      const name = `id-conflict-${uniqueSuffix()}.xml`;
      const firstPath = defaultResourcePath;
      const firstXml = teiXml("id conflict v1");
      const secondPath = "/texts2";
      const secondXml = teiXml("id conflict v2");

      return uploadResourceMultipart(
        agent.put(`/projects/${sharedProjectId}/resources/${id}`),
        firstPath,
        name,
        firstXml
      )
        .then((res) => {
          expect(res).to.have.status(201);
          return uploadResourceMultipart(
            agent.put(`/projects/${sharedProjectId}/resources/${id}`),
            secondPath,
            name,
            secondXml
          );
        })
        .then((res) => {
          expect(res).to.have.status(409);
        });
    });

    it("PUT /projects/$ed/resources/$id returns 409 for existing hash with different ID and path", function () {
      const id1 = `hash-existing-${uniqueSuffix()}`;
      const id2 = `hash-other-${uniqueSuffix()}`;
      const xml = teiXml("hash conflict put");
      const firstPath = defaultResourcePath;
      const firstName = `hash-put-1-${uniqueSuffix()}.xml`;
      const secondPath = "/texts2";
      const secondName = `hash-put-2-${uniqueSuffix()}.xml`;

      return uploadResourceMultipart(
        agent.put(`/projects/${sharedProjectId}/resources/${id1}`),
        firstPath,
        firstName,
        xml
      )
        .then((res) => {
          expect(res).to.have.status(201);
          return uploadResourceMultipart(
            agent.put(`/projects/${sharedProjectId}/resources/${id2}`),
            secondPath,
            secondName,
            xml
          );
        })
        .then((res) => {
          expect(res).to.have.status(409);
        });
    });
  });

  describe("DELETE", function () {
    /**
     * @type {ChaiHttp.Agent}
     */
    let agent;
    
    before(function () {
      agent = request.agent(baseUrl);
      return loginAsAdmin(agent);
    });

    after(function () {
      if ( agent ) {
        agent.close();
      }
    });
    
    it("DELETE /projects/project without login", function ( ) {
      return request.execute(baseUrl)
        .delete("/projects/project")
        .then(( res ) => {
          expect(res).to.have.status(401);
        });
    });

    it("DELETE /projects/missing-project with login", function ( ) {
      return agent.post("/login")
        .set("Content-Type", "multipart/form-data")
        .field("user", "wdbadmin")
        .field("password", "wdbadmin")
        .then(( res ) => {
          expect(res).to.have.status(200);
          return agent.delete("/projects/missing-project")
            .then(( res ) => {
              expect(res).to.have.status(404);
            });
        });
    });

    it("DELETE /projects/project with login", function ( ) {
      return agent.delete(`/projects/${sharedProjectId}`)
        .then(( res ) => {
          expect(res).to.have.status(204);
          return request.execute(baseUrl)
            .get(`/projects/${sharedProjectId}`)
            .set("Accept", "application/xml")
            .then(( res ) => {
              expect(res).to.have.status(404);
              /* delete the project that has been created by POST above to avoid erroneous 409 */
              return agent.delete("/projects/" + idCreatedByPost)
                .then(( res ) => {
                  expect(res).to.have.status(204);
                  return request.execute(baseUrl)
                    .get("/projects")
                    .set("Accept", "application/xml")
                    .then(( res ) => {
                      expect(res).to.have.status(200);

                      let xml = parser.parseFromString(res.body.toString(), "application/xml")
                        , projectNodes = Array.from(xml.getElementsByTagName("project"))
                        , projectIds = projectNodes.map(node => node.getAttribute("id")?.split("/").at(-1)).sort();
                      expect(projectIds).to.deep.equal(["data", "documentation"]);

                      return request.execute(baseUrl)
                        .get("/projects/data/subprojects")
                        .set("Accept", "application/xml")
                        .then(( res ) => {
                          expect(res).to.have.status(200);
                          let subprojects = parser.parseFromString(res.body.toString(), "application/xml");
                          expect(subprojects.documentElement.getAttribute('total')).to.equal('0');
                        });
                    });
                });
            });
        });
    });
  });
});