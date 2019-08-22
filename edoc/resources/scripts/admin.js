var rest = $("meta[name='rest']").attr("content");

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

function dirupload (event) {
  event.preventDefault();
  $('#results').children().remove();
  $('p img').show();
  let files = event.target[0].files;
  
  let cred = Cookies.get("wdbplus");
  let headers = "";
  if (typeof cred !== "undefined" && cred.length != 0)
    headers = {"Authorization": "Basic " + cred};
    
  for (let i = 0; i < files.length; i++) {
    let file = files[i];
    let type = file.webkitRelativePath.substring(file.webkitRelativePath.length - 3);
    let content = (type == 'xml' || type == 'xsl') ? "application/xml" : "application/octet-stream";
    $.ajax({
      method: "post",
      url: rest + "/admin/ingest/file?name=" + file.webkitRelativePath + "&collection=" + params['collection'],
      headers: headers,
      data: file,
      contentType: content,
      processData: false,
      async: false,
      success: function (response, textStatus, xhr) {
        console.log(response);
        let li = "<li>" + response + "</li>";
        $('#results').append(li);
      },
      error: function (response) {
        console.log(response);
      }
    });
  };
  $('p img').hide();
}