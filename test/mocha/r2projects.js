import * as chai from "chai";
import { default as chaiHttp, request } from "chai-http";
import * as xmldom from "xmldom";

chai.use(chaiHttp);
chai.config.includeStack = true;

const baseUrl = "http://localhost:8080/exist/apps/edoc/api/v2";
const agent = request.agent(baseUrl);
const expect = chai.expect;
const parser = new xmldom.DOMParser();

describe("REST v2 projects", function() {
  it("OPTIONS /projects", function( ) {
    return request.execute(baseUrl)
      .options("/projects")
      .then(( res ) => {
        expect(res).to.have.status(200);
        expect(res).to.have.header("allow", "GET, POST, OPTIONS");
      });
    });
  it("GET /projects XML", function( ) {
    return request.execute(baseUrl)
      .get("/projects")
      .set("Accept", "application/xml")
      .then(( res ) => {
        expect(res).to.have.status(200);
        expect(res).to.have.header("content-type", "application/xml");
        let doc = parser.parseFromString(res.body.toString(), "application/xml");
        expect(doc.documentElement.nodeName).to.equal("result");
        expect(doc.getElementsByTagName('project')).not.to.be.empty;
        expect(doc.getElementsByTagName('project')[0].getAttribute('label')).to.equal("wdb+ main project collection");
      });
  });
  it("GET /projects JSON", function( ) {
    return request.execute(baseUrl)
      .get("/projects")
      .set("Accept", "application/json")
      .then(( res ) => {
        expect(res).to.have.status(200);
        expect(res).to.have.header("content-type", "application/json");
        // console.log(res.body);
        expect(res.body).to.have.property("project");
        expect(res.body.project).to.be.an("array");
        expect(res.body.project[0]).to.have.property("label", "wdb+ main project collection");
      });
  });
});

agent.close();
