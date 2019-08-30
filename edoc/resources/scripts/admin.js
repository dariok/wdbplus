var rest = $("meta[name='rest']").attr("content");

$("document").ready(function() {
  if (params['id'] !== undefined && params['action'] == "dir")
  {
    let delim = (rest.substr(rest.length - 1)) == '/' ? "" : "/";
    let url = rest + delim + "collection/" + params["id"] + "/collections.json";
    $.ajax({
      method: "get",
      url: url,
      success: function (data) {
        let json = JSON.parse(data);
        getPaths(json);
      }
    });
    $('#selectTarget').show();
  }
});
function getPaths (data) {
  if (data.hasOwnProperty("@path"))
    $('#selectTarget select').append("<option>" + data["@path"] + "</option>");
  if (data.hasOwnProperty("collection"))
    if (data.collection instanceof Array) data["collection"].forEach(function(coll) { getPaths(coll); });
    else $('#selectTarget select').append("<option>" + data.collection["@path"] + "</option>");
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

async function dirupload (event) {
  event.preventDefault();
  $('#results').children().remove();
  $('p img').show();
  
  let files = event.target[2].elements[0].files;
  let cred = Cookies.get("wdbplus");
  let headers = (typeof cred !== "undefined" && cred.length != 0)
    ? {"Authorization": "Basic " + cred}
    : "";
  
  for (let i = 0; i < files.length; i++) {
    $('#results').append("<li>" + files[i].webkitRelativePath + "…</li>");
  }
  
  for (let i = 0; i < files.length; i++) {
    let file = files[i];
    let type = file.webkitRelativePath.substring(file.webkitRelativePath.length - 3);
    let content = (type == 'xml' || type == 'xsl') ? "application/xml" : "application/octet-stream";
    let item = $('#results').children()[i];
    let text = item.innerText;
    let collection = $('#selectTarget select').val() !== undefined ? $('#selectTarget select').val() : params['collection']
    let endpoint = params['action'] !== undefined ? "file" : "dir"
    let delim = (rest.substr(rest.length - 1)) == '/' ? "" : "/";
    
    try {
      await $.ajax({
        method: "post",
        url: rest + delim + "admin/ingest/" + endpoint + "?name=" + file.webkitRelativePath + "&collection=" + collection,
        headers: headers,
        data: file,
        contentType: content,
        processData: false,
        success: function (response, textStatus, xhr) {
          console.log(response);
          item.innerText = text.substring(0, text.length - 1) + "✓";
        },
        error: function (response) {
          console.log(response);
          item.innerText = text.substring(0, text.length - 1) + "✕";
        }
      });
    } catch (e) {
      console.log(e);
    }
  }

  $('p img').hide();
}