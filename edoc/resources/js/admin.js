"use strict";

/**
 * @type { FileList | null }
 */
let files;
/**
 * @type { String }
 */
let restUrl;

const wdbAdmin = {
  displayRight: function ( url ) {
    $.ajax({
      method: "get",
      url: url,
      cache: false,
      dataType: "json",
      success: function ( data ) {
        wdbAdmin.getPaths();
        $("input[type='submit']").prop("disabled", false);
      },
      error: function ( response ) {
        wdb.report("error", "Kein Projekt mit der ID " + wdb.parameters.get('ed') + " gefunden oder Projekt für den aktuellen Benutzer nicht lesbar.",
          response.responseText, $('aside')[0]);
      }
    });
    $('#selectTarget').show();
  },
  
  getPaths: function ( ) {
    $('#selectTarget select').append('<option selected="selected">edition</option>');
    $('#selectTarget select').append("<option>pages</option>");
    $('#selectTarget select').append('<option>resources</option>');
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

  /**
   * @param event { Event }
   */
  setFiles: function ( event ) {
    $('#results').children().remove();
    if ( !files || files.length === 0 ) return;
    $('#results').append("<tr><th>Local file</th><th>Target path</th><th>Status</th>");
    
    for ( let file of files ) {
      let task = $('#selectTask input:checked').attr("id")
        , filePath = file.webkitRelativePath === '' ? file.name : file.webkitRelativePath
        , delim = $('pre').text().endsWith('/') ? '' : '/'
        , targetPath = $('pre').text() + delim + $('select').val() + "/" + filePath;

      $('#results').append("<tr><td>" + filePath + "</td><td>" + targetPath + "</td><td></td>");
    }

    $("input[type='submit']").prop("disabled", false);
  },

  uploadFiles: async function ( ) {
    if ( !files || files.length === 0 ) return;

    const selectedFiles = Array.from(files);
    const stats = {
        numFiles: selectedFiles.length,
        successfulUL: 0,
        failedUL: 0
    };

    $('main p').html('<span id="q"></span> — <span id="d"></span>');
    $("input[type='submit']").prop("disabled", true);

    try {
      for ( let i = 0; i < selectedFiles.length; i++ ) {
        await wdbAdmin.uploadOneFile(selectedFiles[i], i, stats);
      }
    } finally {
      $("input[type='submit']").prop("disabled", false);
    }
  },

  /**
   * @param { File } file
   * @param { Number } i
   * @param { Record<string, number> } stats
   */
  uploadOneFile: async function ( file, i, stats ) {
    let tableRow = $('#results').children()[i + 1] // first row: table head
      , statusCell = tableRow.children[2];         // last cell: status column

    statusCell.textContent = ".";

    let fileContent;
    try {
      fileContent = await wdbAdmin.readFileAsText(file);
    } catch ( e ) {
      wdbAdmin.reportFileFailure(stats);
      wdb.report("error", "error reading " + file.name, e.toString(), statusCell);
      return;
    }

    if ( fileContent === undefined || fileContent === "" || fileContent === null ) {
      wdbAdmin.reportFileFailure(stats);
      wdb.report("error", "empty", "no file content", statusCell);
      return false;
    }
    // Ensure fileContent is a string (readAsText guarantees this)
    if (typeof fileContent !== 'string') {
      wdbAdmin.reportFileFailure(stats);
      wdb.report("error", "invalid content type", "expected string from readAsText", statusCell);
      return;
    }

    let parser = new DOMParser()
      , parsed;
    
    // try to parse as XML (for now, we only handle XML files here)
    try {
      parsed = parser.parseFromString(fileContent, "application/xml");
    } catch ( e ) {
      wdbAdmin.reportFileFailure(stats);
      wdb.report("error", "error parsing XML from " + file.name, e.toString(), statusCell);
      return;
    }

    // try to find an ID for the XML file
    let xml = $(parsed)
      , fileID = xml.find("tei\\:TEI, TEI").attr("xml:id")
      , parserError = xml.find("parsererror");
    if ( xml.find("parsererror").length > 0 ) {
      wdbAdmin.reportFileFailure(stats);
      wdb.report("error", "parser error", parserError.text(), statusCell);
      return;
    }
    if ( fileID === undefined || fileID === "" ) {
      wdbAdmin.reportFileFailure(stats);
      wdb.report("error", "ID missing", "no @xml:id found in " + file.name, statusCell);
      return;
    }
    wdb.report("info", "parsed file’s ID: " + fileID, '', $('<oid/>')[0]);

    let mdMode = $('#selectTask input:checked').attr("id") == "do" ? "" : "?meta=1";

    let filename = file.webkitRelativePath == "" ? $('select').val() + '/' + file.name
                                                 : $('select').val() + '/' + file.webkitRelativePath.substring(0, file.webkitRelativePath.indexOf(file.name)) + file.webkitRelativePath;
                                                   /* file.filename in the payload will be wdbkitRelativePath; as we need the subdirectory in rest-common.xqm, we need to add it here */
    let formdata = new FormData();
    formdata.append("file", file);
    formdata.append("path", filename);
    
    let fileAlreadyOnServer;
    try {
      await $.ajax({
        method: "HEAD",
        url: restUrl + "resources/" + fileID
      });
      fileAlreadyOnServer = true;
    } catch ( response ) {
      if ( response.status === 404 ) {
        fileAlreadyOnServer = false;
      } else {
        wdbAdmin.reportFileFailure(stats);
        wdb.report("error", "error retrieving information for ID " + fileID, response.responseText, statusCell);
        return;
      }
    }

    statusCell.textContent = "…";
    let method = fileAlreadyOnServer ? "PUT" : "POST"
      , uploadUrl = fileAlreadyOnServer ? restUrl + "resources/" + fileID
                                        : restUrl + "projects/" + wdb.parameters.get('ed') + "/resources";
    try {
      await wdbAdmin.doUpload(method, uploadUrl + mdMode, wdb.restHeaders, formdata, statusCell, stats);
    } catch ( e ) {
      // doUpload reports upload failures and updates stats in its error callback.
      return;
    }
  },

  /**
   * @param { File } file
   * @returns { Promise<string | ArrayBuffer | null> }
   */
  readFileAsText: function ( file ) {
    return new Promise(( resolve, reject ) => {
      let reader = new FileReader();
      reader.onload = () => { resolve(reader.result); };
      reader.onerror = () => { reject(reader.error || new Error("Error reading " + file.name)); };
      reader.readAsText(file, "UTF-8");
    });
  },

  /**
   * @param { Record<string, number> } stats
   */
  reportFileFailure: function ( stats ) {
    $('#d').html(stats.successfulUL + " erfolgreich, " + ++stats.failedUL + " fehlgeschlagen von insgesamt " + stats.numFiles + " Dateien");
  },

  /**
   * @param method { String }
   * @param url { String }
   * @param headers { Record<string, string | null | undefined> }
   * @param formdata { FormData }
   * @param item { Element }
   * @param stats { Record<string, number> }
   */
  doUpload: async function ( method, url, headers, formdata, item, stats ) {
    return $.ajax({
      method: method,
      url: url,
      // headers: headers,
      data: formdata,
      contentType: false,
      processData: false,
      dataType: "text",
      xhrFields: {
          withCredentials: true
      },
      success: ( response, textStatus ) => {
        $('#d').html(++stats.successfulUL + " erfolgreich, " + stats.failedUL + " fehlgeschlagen von insgesamt " + stats.numFiles + " Dateien");
        wdb.report("success", "uploaded to " + url, textStatus, item);
      },
      error: ( response ) => {
        wdbAdmin.reportFileFailure(stats);
        wdb.report("error", "Error uploading to " + url + " : " + response.status, response.responseText, item);
      }
    });
  }
};
Object.freeze(wdbAdmin);

function uploadHandlers ( ) {
  /**
   * @type { HTMLInputElement | null }
   */
  const picker = document.querySelector('#picker');
  if ( picker === null ) return;

  /* event listeners */
  picker.addEventListener("change", ( event ) => {
    files = picker.files;
    wdbAdmin.setFiles(event);
  });
  document.querySelector('#selectTarget select')?.addEventListener("change", ( event ) => {
    wdbAdmin.setFiles(event);
  });

  // admin.xqm will set wdb.meta.get('ed') to the empty string if wdbErr:wdb0200 (no project) is caught
  if ( wdb.meta.get('ed') !== "" ) {
    let delim = restUrl.substring(restUrl.length - 1) === '/' ? "" : "/"
      , url = restUrl + delim + "collection/" + wdb.meta.get('ed') + "/structure.json";
    wdbAdmin.getPaths();
    
    $('pre').text(wdb.meta.get('path'));
    $('#selectTarget').show();

    $('form').on("submit", ( event ) => {
      event.preventDefault();
      wdbAdmin.uploadFiles();
    });
    
    // ingestAction() is called by the fieldset’s change handler
    $('#selectTask input').on("change", ( event ) => { wdbAdmin.ingestAction(event); });
  } else {
    $('#results').append("<tr><td>meta.ed</td><td>" + wdb.meta.get('ed') + "</td></tr>");
    $('#results').append("<tr><td>parameters.ed</td><td>" + wdb.parameters.get('ed') + "</td></tr>");
    $("input[type='submit']").prop("disabled", true);
    $('#results').before('<h1>Kein Projekt mit der ID ' + wdb.parameters.get('ed') + ' gefunden</h1>');
    wdb.report("error", wdb.parameters.get('ed') + " nicht gefunden",
      "Kein Projekt mit der ID " + wdb.parameters.get('ed') + " gefunden oder Projekt für den aktuellen Benutzer nicht lesbar.",
      $('aside')[0]);
  }
}

function newProjectHandlers ( ) {
  let newProjectForm =  $("#newProjectForm");
  
  if ( newProjectForm.length === 0 ) return;
  
  newProjectForm.on("submit", ( event ) => {
    event.preventDefault();

    let baseUrl = restUrl + "projects/" + wdb.meta.get('ed') + "/subprojects/"
      , newCollectionData = { "title": $('#pName').val(), "short": $('#pShort').val(), "collection": $('#pColl').val() }
      , method = $('#pID').val() == '' ? "post" : "put";

    $.ajax({
      method: method,
      url: baseUrl + $('#pID').val(),
      contentType: "application/json",
      data: JSON.stringify(newCollectionData),
      success: function ( data ) {
        let url = new URL(window.location.href);
        url.searchParams.delete("ed");
        url.searchParams.append("pName", $('#pName').val()?.toString() ?? 'unknown');
        url.searchParams.append("pShort", $('#pShort').val()?.toString() ?? 'unknown');
        url.searchParams.append("pID", $('#pID').val()?.toString() ?? 'unknown');
        url.searchParams.append("collection", data);
        url.searchParams.append("ed", $('#pID').val()?.toString() ?? 'unknown');
        window.location.href = url.toString();
      },
      error: function ( data ) {
        $('#container').html("<p>" + data.responseText + "</p>");
      }
    });
  });
}

$( ( ) => {
  let rest = wdb.meta.get('rest').get('2')
    , delimiter = (rest.substr(rest.length - 1)) == '/' ? "" : "/";
  restUrl = rest + delimiter;

  uploadHandlers();
  newProjectHandlers();
});
