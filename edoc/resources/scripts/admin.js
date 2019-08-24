var rest = $("meta[name='rest']").attr("content");

$("document").ready(function() {
  if (params['action'] == "multi")
  {
    let url = rest + "/collection/" + params["id"] + "/collections.json";
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
    data["collection"].forEach(function(coll) { getPaths(coll); });
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
  
  let files = event.target[0].files;
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
    
    try {
      await $.ajax({
        method: "post",
        url: rest + "/admin/ingest/dir?name=" + file.webkitRelativePath + "&collection=" + params['collection'],
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