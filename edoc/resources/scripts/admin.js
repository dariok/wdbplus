/* globals wdb */
/* jshint browser: true */
/* globals wdb */

const wdbAdmin = {
  displayRight: function ( url ) {
    $.ajax({
      method: "get",
      url: url,
      cache: false,
      dataType: "json",
      success: function (data) {
        this.getPaths(data);
        $("input[type='submit']").prop("disabled", false);
        $("aside").html("");
      },
      error: function (response) {
        console.log(response);
        $("aside").html("<p>Kein Projekt mit der ID " + wdb.params.id + " gefunden oder Projekt für den aktuellen Benutzer nicht lesbar.</p>");
      }
    });
    $('#selectTarget').show();
  },
  
  getPaths: function ( data ) {
    if (data.hasOwnProperty("path"))
      $('#selectTarget select').append("<option>" + data.path + "</option>");
    if (data.hasOwnProperty("collection"))
      if (data.collection instanceof Array) data.collection.forEach(function(coll) { this.getPaths(coll); });
      else $('#selectTarget select').append("<option>" + data.collection.path + "</option>");
  },

  // show info for a file
  showFile: function ( ed, file ) {
    let url = 'projects.html?ed=' + ed + '&file=' + file;
    this.displayRight(url);
  },

  // execute a job and show results
  showJob: function ( job, file ) {
    let url = 'projects.html?job=' + job + '&file=' + file;
    this.displayRight ( url );
  },

  /* actual upload */
  doUpload: async function (method, url, headers, formdata, item) {
    return $.ajax({
      method: method,
      url: url,
      headers: headers,
      data: formdata,
      contentType: false,
      processData: false,
      success: function (response, textStatus) {
        $(item).children("span")[0].innerText = "✓";
        $(item).append('<span class="success">' + textStatus + '</span>');
      },
      error: function (response) {
        $(item).children("span")[0].innerText = "✕";
        $(item).append('<span class="error">Error: ' + response.status + "</span>");
        console.error("error " + method.toUpperCase() + "ing to " + url, response);
      }
    });
  },

  uploadFiles: function ( collectionContent ) {
    $('p img').show();
    
    for (let i = 0; i < this.files.length; i++) {
      let reader = new FileReader(),
          file = this.files[i],
          listItem = $('#results').children()[i];
      
      /* jshint loopfunc: true*/
      reader.onload = async function ( readFile ) {
        $(listItem).children("span")[0].innerText = "…";
        let fileContent = readFile.target.result,
            parser = new DOMParser(),
            parsed;
        
        // try to parse as XML (for now, we only handle XML files here)
        try {
          parsed = parser.parseFromString(fileContent, "application/xml");
        } catch (e) {
          wdbAdmin.reportProblem("error parsing XML from " + file.name, e, listItem);
          return false;
        }

        // try to find an ID for the XML file
        let xml = $(parsed),
            fileID = xml.find("TEI").attr("xml:id");
        
        if (fileID === undefined || fileID == "") {
          wdbAdmin.reportProblem("no @xml:id found in " + file.name, {}, listItem);
          return false;
        }

        console.log("parsed file’s ID: " + fileID);

        let delimiter = (wdb.meta.rest.substr(wdb.meta.rest.length - 1)) == '/' ? "" : "/";

        let formdata = new FormData(),
            mdMode = $('#selectTask input:checked').attr("id") == "do" ? "" : "?meta=1";

        formdata.append("file", file);
        formdata.append("filename", file.webkitRelativePath);
          
        try {
          if (collectionContent.hasOwnProperty(fileID)) {
            $(listItem).children("span")[0].innerText = "……";
            //wdbAdmin.doUpload("put", wdb.meta.rest + delimiter + "resource/" + fileID + mdMode, wdb.restHeaders, formdata, listItem);
            uploadManager.queueRequest(["put", wdb.meta.rest + delimiter + "resource/" + fileID + mdMode, wdb.restHeaders, formdata, listItem]);
          } else {
            $(listItem).children("span")[0].innerText = "……";
            //wdbAdmin.doUpload("post", wdb.meta.rest + delimiter + "collection/" + wdb.parameters.ed + mdMode, wdb.restHeaders, formdata, listItem);
            uploadManager.queueRequest(["post", wdb.meta.rest + delimiter + "collection/" + wdb.parameters.ed + mdMode, wdb.restHeaders, formdata, listItem]);
          }
        } catch (e) {
          wdbAdmin.reportProblem("error uploading " + file.name + " to collection " + wdb.parameters.ed, e, listItem);
          return false;
        }
      };
      /* jshint loopfunc: false */

      reader.readAsText(file, "UTF-8");
    }
    $('p img').hide();
  },

  /* usually used internally to signal errors */
  reportProblem: function ( message, problem, listItem ) {
    console.error(message, problem);
    $(listItem).children("span")[0].innerText = "✕";
    $(listItem).append('<span class="error">' + message + '</span>');
  },

  files: {},
  setFiles: function ( fileList ) {
    this.files = fileList;
    
    $('#results').children().remove();
    for (let file of fileList) {
      let task = $('#selectTask input:checked').attr("id"),
          filePath = task == "fi" ? file.name : file.webkitRelativePath;
      
      $('#results').append("<li>" + filePath + "<span></span></li>");
    }

    $("input[type='submit']").prop("disabled", false);
  }
};
//Object.freeze(wdbAdmin);

/* event listeners */
$(document).on("change", "#picker", function() {
  wdbAdmin.setFiles(this.files);
});

// limit the number of concurrent PUT/POST requests to avoid lockups in eXist
let uploadManager = (function() {
  const MAX_REQUESTS = 1;           // local test: produces Jetty errors (“blocking message ...”) for 2 or more...
  let queue = [],
      activeRequests = 0;
  
  function queueRequest( request ) {
    queue.push(request);
    checkQueue();
  }
  
  function requestComplete () {
    activeRequests--;
    checkQueue();
  }

  function checkQueue() {
    if (queue.length && activeRequests < MAX_REQUESTS) {
      let request = queue.shift();
      if (!request) {
        return;
      }
      
      activeRequests++;
      
      console.log("queuing " + request[0]);
      wdbAdmin.doUpload(request[0], request[1], request[2], request[3], request[4])
        .then(function () {
          requestComplete();
        })
        .catch(function( ) {
          requestComplete();
        });
    }
  }

  return {
    queueRequest: queueRequest,
  };
})();

$(function() {
  if (wdb.parameters.ed !== undefined) {
    let delim = (wdb.meta.rest.substr(wdb.meta.rest.length - 1)) == '/' ? "" : "/";
    let url = wdb.meta.rest + delim + "collection/" + wdb.parameters.ed + "/collections.json";
    $.ajax({
      method: "get",
      url: url,
      success: function () {
        $("input[type='submit']").prop("disabled", false);
        $("aside").html("");
      },
      error: function (response) {
        console.error(response);
        $("aside").html("<p>Kein Projekt mit der ID " + wdb.parameters.ed + " gefunden oder Projekt für den aktuellen Benutzer nicht lesbar.</p>");
      }
    });
    $('#selectTarget').show();
  }
});

// dirupload() is called by the form’s formaction handler
$('form').on("submit", dirupload);
async function dirupload ( event ) {
  event.preventDefault();

  // try to determine whether a file with that ID already exists in the target collection
  /* NB: if a file with fileID exists in a different collection or in this collection but under a different name,
   * a 409 will be returned upon POST or PUT */
  let collectionContent,
      delimiter = (wdb.meta.rest.substr(wdb.meta.rest.length - 1)) == '/' ? "" : "/";
  
  await $.ajax({
    method: "get",
    dataType: "json",
    url: wdb.meta.rest + delimiter + "collection/" + wdb.parameters.ed,
    success: function ( data ) {
      collectionContent = data;
    },
    error: function ( response ) {
      wdbAdmin.reportProblem("error getting contents of collection " + wdb.parameters.ed, response, $('p.status'));
      collectionContent = false;
    }
  });

  if (collectionContent === false || collectionContent === undefined) {
    return false;
  }

  let contents = {};
  for (let content of collectionContent.resources) {
    contents[content["@id"]] = content["@label"];
  }

  wdbAdmin.uploadFiles(contents);
}

// ingestAction() is called by the fieldset’s change handler
$('#selectTask').on("change", ingestAction);
function ingestAction(event) {
  if(event.target.id == "fi") {
    $('#picker').attr('webkitdirectory', null);
    $('#selectInputDir label').text("Datei auswählen");
  }
  else {
    $('#picker').attr('webkitdirectory', 'true');
    $('#selectInputDir label').text("Verzeichnis auswählen");
  }
}
