import * as chai from "chai";
import { default as chaiHttp, request } from "chai-http";
import * as xmldom from "@xmldom/xmldom";
import { JSDOM } from "jsdom";
import * as xpath from "xpath";

chai.use(chaiHttp);
chai.config.includeStack = true;

const baseUrl = "http://localhost:8080/exist/apps/edoc/api/v2";
const expect  = chai.expect;
const parser  = new xmldom.DOMParser();
const select  = xpath.useNamespaces({ api: "https://github.com/dariok/wdbplus/api/schema/v1" });

describe("REST v2 projects – OPTIONS", function () {
  it("OPTIONS /projects", function ( ) {
    return request.execute(baseUrl)
      .options("/projects")
      .then(( res ) => {
        expect(res).to.have.status(200);
        expect(res).to.have.header("allow", "GET, POST, OPTIONS");
      });
    });
});

describe("REST v2 projects – GET", function () {
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
        // console.log(res.body);
        expect(res.body).to.have.property("projects");
        expect(res.body.projects).to.be.an("array");
        expect(res.body.projects[0]).to.have.property("label", "wdb+ main project collection");
      });
  });
});

describe("REST v2 projects – POST", function () {
  /**
   * @type {ChaiHttp.Agent}
   */
  let agent;

  before(() => {
    // Create a persistent agent for session handling
    agent = request.agent(baseUrl);
  });

  after(() => {
    // Close the agent after tests
    agent.close();
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
    return agent.post("/login")
        .set("Content-Type", "multipart/form-data")
        .field("user", "admin")
        .field("password", "admin")
        .then( ( res ) => {
          expect(res).to.have.status(200);
          expect(res).to.have.cookie('JSESSIONID');

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
  });
  it("POST /projects/data/subprojects to create without ID with login, but leave out a title", function ( ) {
    return agent.post("/login")
        .set("Content-Type", "multipart/form-data")
        .field("user", "admin")
        .field("password", "admin")
        .then( ( res ) => {
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
  });
  it("POST /projects/$parent/subprojects to create without ID, with login, but use a wrong parent", function () {
    return agent.post("/login")
        .set("Content-Type", "multipart/form-data")
        .field("user", "admin")
        .field("password", "admin")
        .then( ( res ) => {
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
  });
  it("POST /projects/data/subprojects to create project without ID with login", function ( ) {
    return agent.post("/login")
        .set("Content-Type", "multipart/form-data")
        .field("user", "admin")
        .field("password", "admin")
        .then( ( res ) => {
          return agent.post("/projects/data/subprojects")
              .set("Content-Type", "application/json")
              .set("X-Info", "true")
              .send({
                title: "New Project without ID",
                short: "Created by unit test",
                collection: "test30"
              })
              .then(( res ) => {
                expect(res).to.have.status(201);
                // expect(res.body).to.have.property("error");
                // expect(res.body.error).to.equal("Project ID is required.");
              });
            });
  });
  it("PUT /projects/data/subprojects/project to create project with ID with login", function ( ) {
    return agent.put("/login")
        .set("Content-Type", "multipart/form-data")
        .field("user", "admin")
        .field("password", "admin")
        .then( ( res ) => {
          return agent.put("/projects/data/subprojects/project")
              .set("Content-Type", "application/json")
              .set("X-Info", "true")
              .send({
                title: "New Project with ID",
                short: "Created by unit test",
                collection: "test40"
              })
              .then(( res ) => {
                expect(res).to.have.status(201);
                // expect(res.body).to.have.property("error");
                // expect(res.body.error).to.equal("Project ID is required.");
              });
            });
  });
});

describe("REST v2 specific project – GET", function () {
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
        // console.log(res.body);
        expect(res.body).to.have.property("projects");
        expect(res.body.projects).to.be.an("array");
        let filtered = res.body.projects.filter(el => el?.label === "New Project with ID");
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
