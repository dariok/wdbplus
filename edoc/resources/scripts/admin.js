var rest = $("meta[name='rest']").attr("content");
var files;

$("document").ready(function() {
  if (params['id'] !== undefined)
  {
    let delim = (rest.substr(rest.length - 1)) == '/' ? "" : "/";
    let url = rest + delim + "collection/" + params["id"] + "/collections.json";
    $.ajax({
      method: "get",
      url: url,
      success: function (data) {
        getPaths(data);
      }
    });
    $('#selectTarget').show();
  }
});
function getPaths (data) {
  if (data.hasOwnProperty("path"))
    $('#selectTarget select').append("<option>" + data["path"] + "</option>");
  if (data.hasOwnProperty("collection"))
    if (data.collection instanceof Array) data["collection"].forEach(function(coll) { getPaths(coll); });
    else $('#selectTarget select').append("<option>" + data.collection["path"] + "</option>");
}

function show ( ed, file ) {
  url = 'projects.html?ed=' + ed + '&file=' + file;
  rightSide ( url );
}

function job ( job, file ) {
  url = 'projects.html?job=' + job + '&file=' + file;
  rightSide ( url );
}

function rightSide ( url ) {  
  html = $.ajax({ 
      url: url, 
      cache: false, 
      success: function ( data ) {  
          var result = $('<div/>').append( data ).find( '#data' ).html(); 
          $( '#rightSide' ).html( result ); 
        } 
    }); 
}

$('#picker').on("submit", dirupload);
$(document).on("change", "#picker", function() {
  $('#results').children().remove();
  let dir = $(this).attr('webkitdirectory');
  files = this.files;
  
  for (let i = 0; i < files.length; i++) {
    let path = $('#selectTask input:checked').attr("id") == "fi" ? files[i].name : files[i].webkitRelativePath;
    $('#results').append("<li>" + path + "<span></span></li>");
  }
});

async function sendData (file, i, fileid, headers) {
  try {
    let task = $('#selectTask input:checked').attr("id"),
        type = (task == "fi") ? file.name.substr(file.name.length - 3) : file.webkitRelativePath.substring(file.webkitRelativePath.length - 3),
        content = (type == 'xml' || type == 'xsl') ? "application/xml" : "application/octet-stream",
        item = $('#results').children()[i],
        text = (task == "fi") ? file.name : item.innerText,
        collection = $('#selectTarget select').val() !== undefined ? $('#selectTarget select').val() : params['collection'],
        delim = (rest.substr(rest.length - 1)) == '/' ? "" : "/",
        pathToEd = $('#selectTarget').find('option')[0].innerHTML,
        edRoot = pathToEd.substr(pathToEd.lastIndexOf('/') + 1),
        relpath = task == "fi"
          ? collection.substr(pathToEd.length + 1) + '/' + text
          : text.substr(0, edRoot.length) == edRoot
            ? text.substr(edRoot.length + 1)
            : collection.substr(collection.indexOf('/' + edRoot) + edRoot.length + 1) + '/' + text,
        mode = task == "do" ? "" : "?meta=1";
    
    console.log("fileid: " + fileid);
    if (fileid !== "undefined" && fileid !== 0) {
      let formdata = new FormData();
      formdata.append("file", file);
      formdata.append("filename", relpath);
      formdata.append("targetCollection", collection)
      
      $.ajax({
        method: "get",
        url: rest + delim + "resource/" + fileid,
        success: function (response, textStatus, xhr) {
          if (xhr.status == 200) {
            $(item).children("span")[0].innerText = "…";
            doUpload("put", rest + delim + "resource/" + fileid, headers, formdata, item, text);
          } else {
            console.log(response);
            $(item).children("span").innerText = "✕";
            $(item).children("span").attr("title", "Unexpected return code: " + xhr.status);
          }
        },
        error: function (response) {
          if (response.status == 404) {
            $(item).children("span")[0].innerText = "…";
            doUpload("post", rest + delim + "collection/" + params["id"], headers, formdata, item, text);
          } else {
            console.log(response);
            $(item).children("span")[0].innerText = "✕";
            $(item).children("span").attr("title", "Unexpected return code: " + response.status);
          }
        }
      });
    }
  } catch (e) {
    console.log(e);
    console.log(e.stack);
  }
}
async function doUpload(method, url, headers, formdata, item, text) {
  $.ajax({
    method: method,
    url: url,
    headers: headers,
    data: formdata,
    contentType: false,
    processData: false,
    success: function (response, textStatus, xhr) {
      $(item).children("span")[0].innerText = "✓";
      $(item).append('<span class="success">' + textStatus + '</span>');
    },
    error: function (response) {
      $(item).children("span")[0].innerText = "✕";
      $(item).append('<span class="error">Error: ' + response.status + "</span>");
    }
  });
}

function dirupload (event) {
  event.preventDefault();
  $('p img').show();
  
  let cred = Cookies.get("wdbplus");
  let headers = (typeof cred !== "undefined" && cred.length != 0)
    ? {"Authorization": "Basic " + cred}
    : "";
  
  for (let i = 0; i < files.length; i++) {
    let file = files[i],
        item = $('#results').children()[i],
        text = item.innerText;
    console.log("processing " + file.name);
    
    let reader = new FileReader();
    reader.onload = function(readFile) {
      $(item).children("span").innerText = "…";
      let content = readFile.target.result,
          fileid = 0;
      try {
        let parsed = $.parseXML(content.substring(content.indexOf("<TEI")));
        let xml = $(parsed);
        fileid = xml.find("TEI").attr("xml:id");
      } catch (e) {
        console.log("error parsing XML from " + file.name);
        console.log(e);
        item.innerText = text.substring(0, text.length) + "✕ Parser Error ";
      }
      
      if (fileid !== undefined && fileid !== 0) {
        console.log("parsed file’s ID: " + fileid);
        sendData(file, i, fileid, headers);
      } else {
        console.log("no @xml:id found in " + file.name);
        item.innerText = text.substring(0, text.length) + "✕ No xml:id found ";
      }
    };
    reader.readAsText(file, "UTF-8");
  }
  
  $('p img').hide();
}

function ingestAction(event) {
  if(event.target.id == "fi") { $('#picker').attr('webkitdirectory', null); }
  else { $('#picker').attr('webkitdirectory', 'true'); }
}

