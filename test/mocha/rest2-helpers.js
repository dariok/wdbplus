import * as chai from "chai";
import { request } from "chai-http";

const expect = chai.expect;

const baseUrl = "http://localhost:8080/exist/apps/edoc/api/v2";
const unsupportedResourceContentType = "application/json";
const sharedResourceProjectId = "project";
const sharedResourceCollection = "test40";
const defaultResourcePath = "/edition";

function uniqueSuffix() {
  return `${Date.now()}-${Math.floor(Math.random() * 100000)}`;
}

/**
 * @param {import("superagent/lib/node").Request} req
 * @param {string} path
 * @param {string} name
 * @param {string} xml
 */
function uploadResourceMultipart( req, path, name, xml, extraFields = {} ) {
  req.set("Content-Type", "multipart/form-data");

  let multipartReq = req.field("path", path);
  
  for ( const [key, value] of Object.entries(extraFields) ) {
    multipartReq = multipartReq.field(key, String(value));
  }

  return multipartReq.attach("file", Buffer.from(String(xml), "utf8"), name);
}

/**
 * @param {ChaiHttp.Agent} agent
 * @param {string} user
 * @param {string} password
 */
function loginAs( agent, user, password ) {
  return agent.post("/login")
    .set("Content-Type", "multipart/form-data")
    .field("user", user)
    .field("password", password)
    .then((res) => {
      expect(res).to.have.status(200);
      return res;
    });
}

/**
 * @param {ChaiHttp.Agent} agent
 */
function loginAsAdmin( agent ) {
  return loginAs(agent, "admin", "admin");
}

/**
 * @param {ChaiHttp.Agent} agent
 */
function ensureSharedProject( agent ) {
  return request.execute(baseUrl)
    .get(`/projects/${sharedResourceProjectId}`)
    .set("Accept", "application/xml")
    .then((res) => {
      if (res.status === 200) {
        return res;
      }

      if (res.status === 404) {
        return loginAsAdmin(agent)
          .then(() => {
            return agent.put(`/projects/data/subprojects/${sharedResourceProjectId}`)
              .set("Content-Type", "application/json")
              .send({
                title: `Shared resource tests ${sharedResourceProjectId}`,
                short: "Created by mocha",
                collection: sharedResourceCollection
              });
          })
          .then((createRes) => {
            expect([201, 409]).to.include(createRes.status);
            return createRes;
          });
      }

      throw new Error(`Unexpected status while checking shared project: ${res.status}`);
    });
}

export {
  baseUrl,
  defaultResourcePath,
  ensureSharedProject,
  loginAs,
  loginAsAdmin,
  sharedResourceCollection,
  sharedResourceProjectId,
  uniqueSuffix,
  unsupportedResourceContentType,
  uploadResourceMultipart
};
