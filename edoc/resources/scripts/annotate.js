/* 
 * wdb+ online annotations
 * author: Dario Kampkaspar <dario.kampkaspar@tu-darmstadt.de>
 */

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
    url: wdb.meta.rest+ "anno/" + wdb.meta.id,
    headers: wdb.restheaders,
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
  
  // no selection has been made
  if (selection.focusNode == null && selection.anchorNode == null) {
    alert("keine Auswahl!");
    return false;
  }
  // a selection has been made outside main (hence, not in the annotateable area
  if (selection.anchorNode.parentElement.closest("main") == null) {
    alert("Nur im Text auswählen!");
    return false;
  }
  
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
    url: wdb.meta.rest+ "anno/" + wdb.meta.id,
    headers: wdb.restheaders,
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
   wdb.meta.rest+ "anno/" + wdb.meta.id,
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
// GET entity information from the server
$(document).ready(function(){
  // select2 to GET info while typing (at least 2 chars)
  $('#search-entity').select2({
    dropdownParent: $('#annotationDialog'),
    placeholder: "Auszeichnen und identifizieren von Personen, Orten, Sachen",
    minimumInputLength: 2,
    escapeMarkup: function (markup) {
      return markup;
    },
    templateResult: function (data) {
      return data.text;
    },
    templateSelection: function (data) {
      return data.text;
    },
    ajax: {
      url: function (params) {
        let url = wdb.meta.rest + "entities/scan/" + $("#type").val() + "/"
          + wdb.meta.ed + ".xml";
        return url;
      },
      processResults: function (data) {
        return {
          results: process(data, $('#type').val())
        };
      },
      error: function ( jqXHR, textStatus, errorThrown ) {
        console.log (jqXHR);
        console.log (textStatus, errorThrown );
      }
    }
  });
  $('#search-entity').on('mousedown', positionResults);
});

function positionResults() {
  let sel = $('.select2-dropdown.select2-dropdown--below');
  sel.css('position', 'fixed');
  sel.css('left',
    sel.parent().position().left
      + sel.closest("[role = 'dialog']").position().left
      + parseInt(sel.closest("[role = 'dialog']").css('borderLeftWidth'))
      + parseInt($('#annotationDialogTabs').css('borderLeftWidth'))
      + parseInt($('.select2-selection.select2-selection--single').css('borderLeftWidth'))
      + 1
    );
}
// process reply from server (overwrite if a special format is required)
function process(data, type) {
//  let result = { results: [] };
  results = [];
  $(data).find('result').each(function (index, element) {
    switch (type) {
      case "per":
        let sn = element.getElementsByTagName("surname").length > 0
              ? element.getElementsByTagName("surname")[0].textContent : "",
            fn = element.getElementsByTagName("forename").length > 0
              ? Array.from(element.getElementsByTagName("forename")) : "",
            fo = (fn.length > 0)
              ? fn.map(function(elem){ return elem.textContent; }).join(" ") : "",
            sc = (sn.length > 0 && fo.length > 0)
              ? ", " : "",
            nl = element.getElementsByTagName("nameLink").length > 0
              ? " " + element.getElementsByTagName("nameLink")[0].textContent : "",
            bi = element.getElementsByTagName("birth"),
            de = element.getElementsByTagName("death"),
            da = "";
        if (bi.length > 0 || de.length > 0) {
          da = " (";
          da += bi.length > 0 ? bi[0].textContent : "";
          da += bi.length > 0 && de.length > 0 ? "–" : "";
          da += de.length > 0 ? de[0].textContent : "";
          da += bi.length > 0 || de.length > 0 ? ")" : "";
        }
        let text = sn + nl + sc + fo + da;
        results.push({
          id: element.id,
          "text": text
        });
        break;
      case "pla":
        let placeName = element.getElementsByTagName("placeName")[0].textContent,
            id = element.id;
        results.push({
          id: id,
          text: placeName
        });
        break;
    }
  });
  
  positionResults();
  
  return results;
}
// POST the data entered to the server
function identifyEntity() {
  let text = $("#search-entity").val(), // the content of the text input
      type = $("#type").val(),          // the type of entity to be used
      start = $('#annFrom').text(),     // first ID in annotation range
      end = $('#annTo').text();         // last ID in annotation range
  dialogue.dialog("close");
  
  $.ajax({
    method: "post",
    url: wdb.meta.rest+ "anno/entity/" + wdb.meta.id,
    headers: wdb.restheaders,
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
  let edit = $("#corr").val(),          // the new text for the selection
      start = $('#annFrom').test(),     // first ID in annotation range
      end = $('#annTo').text();         // last ID in annotation range
  dialogue.dialog("close");
  
  // currently, we are limited to changing one word
  if (start != end)
    alert("You can only change one word at a time!");
  else
    $.ajax({
      method: "post",
      url: wdb.meta.rest+ "anno/word/" + wdb.meta.id,
      headers: wdb.restheaders,
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