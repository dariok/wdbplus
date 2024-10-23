"use strict";

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
      },
      error: function ( response ) {
        wdb.report("error", "Kein Projekt mit der ID " + wdb.params.id + " gefunden oder Projekt für den aktuellen Benutzer nicht lesbar.",
          response, $('aside'));
      }
    });
    $('#selectTarget').show();
  },
  
  getPaths: function ( data ) {
    if (data instanceof Array) {
      data.forEach(function( subcollection ) {
        if (subcollection == "texts") {
          $('#selectTarget select').append('<option selected="selected">' + subcollection + '</option>');
        } else {
          $('#selectTarget select').append("<option>" + subcollection + "</option>");
        }
      });
    } else {
      // only one entry
      $('#selectTarget select').append('<option selected="selected">' + data + '</option>');
    }
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

  ingestAction: function ( event ) {
    if ( event.target.id === "fi" ) {
      $('#picker').attr({'webkitdirectory': null, 'multiple': 'multiple'});
      $('#selectInputDir label').text("Datei auswählen");
    }
    else {
      $('#picker').attr({'webkitdirectory': 'true', 'multiple': null});
      $('#selectInputDir label').text("Verzeichnis auswählen");
    }
  },

  /* actual upload */
  dirupload: async function ( event ) {
    event.preventDefault();
  
    // try to determine whether a file with that ID already exists in the target collection
    /* NB: if a file with fileID exists in a different collection or in this collection but under a different name,
     * a 409 will be returned upon POST or PUT */
    let collectionContent = {}
      , delimiter = (wdb.meta.rest.substr(wdb.meta.rest.length - 1)) == '/' ? "" : "/";
    
    await $.ajax({
      method: "get",
      dataType: "json",
      url: wdb.meta.rest + delimiter + "collection/" + wdb.parameters.ed,
      success: function ( data, textStatus, jqXHR ) {
        if ( jqXHR.status == 204 ) {
          collectionContent = { resources: [] };
        } else {
          collectionContent = data;
        }
      },
      error: function ( response ) {
        wdb.report("error", "error getting contents of collection " + wdb.parameters.ed, response, $('p.status'));
        return false;
      }
    });
  
    let contents = {};
    if ( Array.isArray(collectionContent.resources) ) {
      for ( let content of collectionContent.resources ) {
        contents[content.id] = content.label;
      }
    } else if ( collectionContent.resources.hasOwnProperty("id") ) {
      contents[collectionContent.resources.id] = collectionContent.resources.label;
    }
  
    wdbAdmin.uploadFiles(contents);
  },
  
  successfulUL: 0,
  failedUL: 0,
  numFiles: 0,

  uploadFiles: function ( collectionContent ) {
    $('main p').html('<span id="q"></span> — <span id="d"></span>');
    this.numFiles = this.files.length;
    
    for (let i = 0; i < this.files.length; i++) {
      let reader = new FileReader(),
          file = this.files[i],
          tableRow = $('#results').children()[i + 1], // first child: table head
          tableData = tableRow.children[2];           // last child: status column
      
      /* jshint loopfunc: true*/
      reader.onload = async function ( readFile ) {
        tableData.innerText = ".";
        let fileContent = readFile.target?.result;
        if ( fileContent === undefined || fileContent === "" || fileContent === null ) {
          wdb.report("error", "empty", "no file content", tableData);
          return false;
        }

        let parser = new DOMParser()
          , parsed;
        
        // try to parse as XML (for now, we only handle XML files here)
        try {
          parsed = parser.parseFromString(fileContent, "application/xml");
        } catch (e) {
          wdb.report("error", "error parsing XML from " + file.name, e, tableData);
          return false;
        }

        // try to find an ID for the XML file
        let xml = $(parsed)
          , fileID = xml.find("tei\\:TEI, TEI").attr("xml:id")
          , parserError = xml.find("parsererror");
        
        if ( xml.find("parsererror").length > 0 ) {
          wdb.report("error", "parser error", parserError.text(), tableData);
          return false;
        }
        if ( fileID === undefined || fileID === "" ) {
          wdb.report("error", "ID missing", "no @xml:id found in " + file.name, {}, tableData);
          return false;
        }

        wdb.report("info", "parsed file’s ID: " + fileID);

        let delimiter = (wdb.meta.rest.substr(wdb.meta.rest.length - 1)) == '/' ? "" : "/";

        let formdata = new FormData(),
            mdMode = $('#selectTask input:checked').attr("id") == "do" ? "" : "?meta=1";
        
        let filenameBase = file.webkitRelativePath == "" ? $('select').val() + '/' + file.name : $('select').val() + '/' + file.webkitRelativePath,
            filenameMod = filenameBase.replaceAll(',', '').replaceAll(' ', '_').replaceAll('&', '-').replaceAll('ä', 'ae')
                .replaceAll('Ä', 'Ae').replaceAll('ö', 'oe').replaceAll('Ö', 'Oe').replaceAll('ü', 'ue').replaceAll('Ü', 'Ue')
                .replaceAll('ß', 'ss');

        formdata.append("file", file);
        formdata.append("filename", filenameMod);
          
        try {
          if (collectionContent.hasOwnProperty(fileID)) {
            tableData.innerText = "…";
            //wdbAdmin.doUpload("put", wdb.meta.rest + delimiter + "resource/" + fileID + mdMode, wdb.restHeaders, formdata, listItem);
            uploadManager.queueRequest([
                "put",
                wdb.meta.rest + delimiter + "resource/" + fileID + mdMode,
                wdb.restHeaders,
                formdata,
                tableData
            ]);
          } else {
            tableData.innerText = "…";
            //wdbAdmin.doUpload("post", wdb.meta.rest + delimiter + "collection/" + wdb.parameters.ed + mdMode, wdb.restHeaders, formdata, listItem);
            uploadManager.queueRequest([
                "post",
                wdb.meta.rest + delimiter + "collection/" + wdb.parameters.ed + mdMode,
                wdb.restHeaders,
                formdata,
                tableData
            ]);
          }
        } catch (e) {
          wdb.report("error", "error uploading " + file.name + " to collection " + wdb.parameters.ed, e, tableData);
          return false;
        }
      };
      /* jshint loopfunc: false */

      reader.readAsText(file, "UTF-8");
    }
  },

  doUpload: async function (method, url, headers, formdata, item) {
    return $.ajax({
      method: method,
      url: url,
      headers: headers,
      data: formdata,
      contentType: false,
      processData: false,
      dataType: "text",
      success: function (response, textStatus) {
        $('#d').html(++wdbAdmin.successfulUL + " erfolgreich, " + wdbAdmin.failedUL + " fehlgeschlagen von insgesamt " + wdbAdmin.numFiles + " Dateien");
        wdb.report("success", "uploaded to " + url, textStatus, item);
      },
      error: function (response) {
        $('#d').html(wdbAdmin.successfulUL + " erfolgreich, " + ++wdbAdmin.failedUL + " fehlgeschlagen von insgesamt " + wdbAdmin.numFiles + " Dateien");
        wdb.report("error", "Error uploading to " + url + " : " + response.status, response.responseText, item);
      }
    });
  },

  files: {},
  setFiles: function ( fileList ) {
    this.files = fileList;
    
    $('#results').children().remove();
    $('#results').append("<tr><th>Local file</th><th>Target path</th><th>Status</th>");
    for (let file of fileList) {
      let task = $('#selectTask input:checked').attr("id"),
          filePath = task == "fi" ? file.name : file.webkitRelativePath,
          targetPath = $('pre').text() + "/" + $('select').val() + "/" + filePath;
      
      $('#results').append("<tr><td>" + filePath + "</td><td>" + targetPath + "</td><td></td>");
    }

    $("input[type='submit']").prop("disabled", false);
  }
};
//Object.freeze(wdbAdmin);

/* event listeners */
$(document).on("change", "#picker", function() {
  wdbAdmin.setFiles(this.files);
});
$(document).on("change", "select[name=target]", () => {
  wdbAdmin.setFiles($('#picker')[0].files);
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
      
      wdb.report("info", "queuing " + request[0]);
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
  let filename = window.location.pathname.substring(window.location.pathname.lastIndexOf('/') + 1);

  // admin.xqm will set wdb.meta.ed to the empty string if wdbErr:wdb0200 (no project) is caught
  if ( filename === "directoryForm.html" && wdb.meta.ed !== "" ) {
    let delim = wdb.meta.rest.substr(wdb.meta.rest.length - 1) === '/' ? "" : "/"
      , url = wdb.meta.rest + delim + "collection/" + wdb.meta.ed + "/structure.json";
    $.ajax({
      method: "get",
      url: url,
      success: function ( data ) {
        let key = Object.keys(data)[0];
        $('#selectTarget pre').first().text(key);
        wdbAdmin.getPaths(data[key]);
        $("input[type='submit']").prop("disabled", false);
      },
      error: function ( response ) {
        wdb.report("error", "When trying to create upload form for project " + wdb.parameters.ed + ": ",
          response.responseText, $('aside'));
      }
    });
    $('#selectTarget').show();

    // dirupload() is called by the form’s formaction handler
    $('form').on("submit", ( event ) => { wdbAdmin.dirupload(event); });
    
    // ingestAction() is called by the fieldset’s change handler
    $('#selectTask input').on("change", ( event ) => { wdbAdmin.ingestAction(event); });
  } else if ( filename === "directoryForm.html" ) {
    $('#results').append("<tr><td>meta.ed</td><td>" + wdb.meta.ed + "</td></tr>");
    $('#results').append("<tr><td>parameters.ed</td><td>" + wdb.parameters.ed + "</td></tr>");
    $("input[type='submit']").prop("disabled", true);
    $('#results').before('<h1>Kein Projekt mit der ID ' + wdb.parameters.ed + ' gefunden</h1>');
    wdb.report("error", wdb.parameters.ed + " nicht gefunden",
      "Kein Projekt mit der ID " + wdb.parameters.ed + " gefunden oder Projekt für den aktuellen Benutzer nicht lesbar.",
      $('aside'));
  }
});
