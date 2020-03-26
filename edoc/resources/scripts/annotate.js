/* 
 * wdb+ online annotations
 * author: Dario Kampkaspar <dario.kampkaspar@tu-darmstadt.de>
 */

// current file’s ID (= /*[1]/@xml:id) */
var id = $("meta[name='id']").attr("content");

// base URL for REST requests
var rest = $("meta[name='rest']").attr("content");

// set authentication header for REST request
var headers = (function() {
  let cred = Cookies.get("wdbplus");
  if (typeof cred !== "undefined" && cred.length != 0)
    return { "Authorization": "Basic " + cred };
    else return "";
})();

// to contain the dialogue box object
var dialogue;

/* 
 * when loading the page:
 * - create the dialogue
 * - get full text annotations from endpoint
 */
$(function() {
  // create the dialog
  dialogue = $("#annotationDialog").dialog({
    autoOpen: false,
    width: 'auto',
    close: function() {
      $('#fta')[0].reset();
      $('#la')[0].reset();
      }
  });
  $("#annotationDialogTabs").tabs();
  $('#annButton').on("click", function() {
  	anno();
  });
  
  // get all full text annotations (all public and private if created by current user) for the current file
  $.ajax({
    method: "get",
    url: rest + "anno/" + id,
    headers: headers,
    success: function(data){
      $.each(
        data.entry,
        function( index, value ) {
          if (index > 0 && value.range.from != '') {
            let start = $('#' + value.range.from);
            
            let end = (value.range.to == '' || value.range.to === undefined)
              ? start
              : $('#' + value.range.to);
            
            let cat = value.range.from + "–" + value.range.to + ": " + value.cat;
            
            let from = value.range.from.substring(1),
                to = value.range.to.substring(1);
            
            if(to > from)
              highlightAll(start, end, 'red', cat);
              else highlightAll(end, start, 'red', cat);
          } else {
            console.log("annotation error: unexpected full text annotation:\n"
              + index + ": " + value.from + "–" + value.to + " = " + value.cat);
          }
        }
      );
    }
  });
});

// get the selected word(s), show them in the dialogue and open it
function anno() {
  let selection = window.getSelection();
  if (selection.focusNode === null && selection.anchorNode === null)
    return false;
  
  let backwards = (selection.focusNode === selection.getRangeAt(0).startContainer);
  
  let end, start;
  // start may only be the text node within the element; also, a text-only node may be selected
  if (backwards) {
    end = selection.anchorNode.wholeText.trim() == ''
      ? selection.anchorNode.previousElementSibling.id
      : selection.anchorNode.parentNode.id;
    start = selection.focusNode.wholeText.trim() == ''
      ? selection.focusNode.nextElementSibling.id
      : (selection.focusNode.parentNode.id == ''
        ? selection.focusNode.parentNode.parentNode.id
        : selection.focusNode.parentNode.id);
  } else {
    start = selection.anchorNode.wholeText.trim() == ''
      ? selection.anchorNode.nextElementSibling.id
      : (selection.anchorNode.parentNode.id == ''
        ? selection.anchorNode.parentNode.parentNode.id
        : selection.anchorNode.parentNode.id);
    end = selection.focusNode.wholeText.trim() == ''
      ? selection.focusNode.previousElementSibling.id
      : selection.focusNode.parentNode.id;
  }
  
  $('#annText').text(selection.toString());
  $('#annFrom').text(start);
  $('#annTo').text(end);
  
  dialogue.dialog("open");
}

/* 
 * full text annotations
 */
function parsefta() {
  let start = $('#annFrom').text(),     // first ID in annotation range
      end = $('#annTo').text(),         // last ID in annotation range
      annoText = $('#ftaText').val();   // text of the fta
  dialogue.dialog("close");
  
  // POST the the fta
  $.ajax({
    method: "post",
    url: rest + "anno/" + id,
    headers: headers,
    data: JSON.stringify({
      from: start,
      to: end,
      text: annoText,
      public: $('#public').val()
    }),
    contentType: "application/json; charset=UTF-8",
    dataType: 'json'
    });
  
  // GET all annotations from server
  $.getJSON(
    rest + "anno/" + id,
    function(data){ console.log(data); }
  );
  
  let startElem = $('#' + start),
      endElem = $('#' + end);
  
  highlightAll(startElem, endElem, 'red', annoText);
}

/* 
 * change the layout of a word or block
 */
// TODO implement this feature
function chgLayout(rend) {
  console.log(rend);
}

/* 
 * identify entities
 */
// POST the data entered to the server
function identifyEntity() {
  let text = $("#search-entity").val(), // the content of the text input
      type = $("#type").val(),          // the type of entity to be used
      start = $('#annFrom').test(),     // first ID in annotation range
      end = $('#annTo').text();         // last ID in annotation range
  dialogue.dialog("close");
  
  $.ajax({
    method: "post",
    url: rest + "anno/entity/" + id,
    headers: headers,
    data: JSON.stringify({
      from: start,
      to: end,
      type: type,
      identity: text
    }),
    contentType: "application/json; charset=UTF-8",
    dataType: 'json',
    success: function(data) {
      let ins = data["#text"][0] + data.pc;
      if (data.lb) ins += "<br>";
      ins += data["#text"][1];
      $('#' + start).html(ins);
    }
  });
}

/* 
 * change full text
 */
function editText() {
  let edit = $("#corr").val(),        // the new text for the selection
      start = $('#annFrom').test(),     // first ID in annotation range
      end = $('#annTo').text();         // last ID in annotation range
  dialogue.dialog("close");
  
  // currently, we are limited to changing one word
  if (start != end)
    alert("You can only change one word at a time!");
  else
    $.ajax({
      method: "post",
      url: rest + "anno/word/" + id,
      headers: headers,
      data: JSON.stringify({
        id: start,
        text: edit,
        job: "edit"
      }),
      contentType: "application/json; charset=UTF-8",
      dataType: 'json',
      success: function(data) {
        let ins = "";
        if (data.lb) 
        ins = data["#text"][0] + data.pc["#text"] + "<br>" + data["#text"][1];
        else 
        ins = data["#text"];
        
        $('#' + start).html(ins);
      }
    });
}

/* 
 * switch to the selected function
 */
function fshow(id) {
  let anc = $(id).closest("form");
  anc.children().hide();
  $(id).show();
}