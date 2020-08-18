/* 
 * wdb+ online annotations
 * author: Dario Kampkaspar <dario.kampkaspar@tu-darmstadt.de>
 */

var dialogue; // to contain the dialogue box object 

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
    success: function(data, textStatus, jqXHR){
      if (jqXHR.status == 200) {
        $.each(
          data.entry,
          function( index, value ) {
            if (value.range.from != '') {
              /* find the target elements */
              let start = $('#' + value.range.from),
                  end = (value.range.to == '' || value.range.to === undefined)
                    ? start
                    : $('#' + value.range.to);
              
              /* hightlight the target elements */
              let from = value.range.from.substring(1),
                  to = value.range.to.substring(1);
              let entry = '<dd id="' + value.id + '"><i>' + value.user + ':</i>&nbsp;'
                  + value.cat + '&nbsp; <button onclick="annoDelete(\'' 
                  + value.id + '\')" title="Eintrag löschen">&#x1F5D1;</button></dd>';
              
              if(to > from)
                highlightAll(start, end, 'red', entry);
                else highlightAll(end, start, 'red', entry);
            } else {
              console.log("annotation error: incorrect full text annotation:\n"
                + index + ": " + value.from + "–" + value.to + " = " + value.cat);
            }
          }
        );
      } else {
        console.log("GETting annotations returned status " + jqXHR.status);
      }
    }
  });
  
  // for all entity annotations, add their info to the list, too
  var entityEntryID = 0;
  $("button.entity").each(function () {
    let start = $(this).first(),
        end = $(this).last(),
        content = '<dd id="ent' + entityEntryID + '">Entitäten-Verknüpfung&nbsp;'
            + '&nbsp; <button onclick="entityDelete(\'ent' + entityEntryID 
            + '\')" title="Eintrag löschen">&#x1F5D1;</button></dd>';
    highlightAll(start, end, "white", content);
    entityEntryID++;
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
  
  let end, start, an, ao, fn, fo;
  if (backwards) {
    // an, ao are the start = leftmost part of the selection
    an = selection.focusNode;
    ao = selection.focusOffset;
    fn = selection.anchorNode;
    fo = selection.anchorOffset;
  } else {
    an = selection.anchorNode;
    ao = selection.anchorOffset;
    fn = selection.focusNode;
    fo = selection.focusOffset;
  }
  
  // get start
  if (an.parentNode.classList.contains("w") && ao < an.length) {  // selection started in .w
    start = an.parentNode.id;
  } else {
    // selection starts between elements – first, check whether we have a sibling to work from
    let lookForSibling;
    if (an.nextElementSibling !== null) {
      lookForSibling = an;
    } else if (an.parentNode.nextElementSibling !== null) {
      // we’re at the end of a .w which has a sibling 
      lookForSibling = an.parentNode;
    } else {
      // we’re at the end of a .w which is inside another element
      lookForSibling = an.parentNode.parentNode;
    }
    
    if (lookForSibling.nextElementSibling.classList.contains("w")) {
      // next sibling is a .w, this is our start node
      start = lookForSibling.nextElementSibling.id;
    } else {
      // some other element follows, find the first .w in there
      start = $(lookForSibling.nextElementSibling).find(".w").first()[0].id;
    }
  }
  
  // get the end
  if (fn.parentNode.classList.contains("w") && fo > 0){
    // within a .w, so this is the end of the selection
    end = fn.parentNode.id;
  } else {
    // selection ended between elements; first, check whether we ha a sibling to work from
    let lookForSibling;
    if (fn.previousElementSibling !== null) {
      lookForSibling = fn;
    } else if (fn.parentNode.previousElementSibling !== null) {
      // our parent .w has a previous sibling
      lookForSibling = fn.parentNode;
    } else {
      // our parent .w is within another element
      lookForSibling = fn.parentNode.parentNode;
    }
    
    if (lookForSibling.previousElementSibling.classList.contains("w")) {
      // previous sibling is a .w, which is the end of the selection
      end = lookForSibling.previousElementSibling.id;
    } else {
      // previous sibling is sth. else, whose last .w is the end of the selection
      end = $(lookForSibling.previousElementSibling).find(".w").last()[0].id;
    }
  }
  
  $('#annText').text(selection.toString());
  $('#annFrom').text(start);
  $('#annTo').text(end);
  
  dialogue.dialog("open");
}

function annoDelete ( id ) {
  console.log("Delete " + id);
  $.ajax({
    method: "delete",
    url: wdb.meta.rest + "anno/" + id,
    headers: wdb.restheaders,
    success: function (data, textStatus, jqXHR) {
      let container = $('#' + id).parent(),
          ancestor = $('#' + id).closest(".w");
      $('#' + id).detach();
      if (container.children("dd").length === 0) {
        container.detach();
      }
      if (ancestor.children("ul").length === 0) {
        ancestor.css("background-color", "unset");
      }
    },
    error: function (data, textStatus, jqXHR) {
      console.log (textStatus);
    }
  });
}

/* 
 * full text annotations
 */
function parsefta() {
  let start = $('#annFrom').text(),     // first ID in annotation range
      end = $('#annTo').text(),         // last ID in annotation range
      annoText = $('#ftaText').val(),   // text of the fta
      chkPublic = $("#public").prop("checked");
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
      public: chkPublic
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
    url: wdb.meta.rest + "anno/entity/" + wdb.meta.id,
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

// DELETE an entity = replace tei:rs by its contents
function deleteEntity() {
  let type = $("#deleteType").val(),    // the type of entity to be deleted
      start = $('#annFrom').text(),     // first ID in annotation range
      end = $('#annTo').text();         // last ID in annotation range
  
  if (start !== end) {
    alert("Es darf nur ein Wort ausgewählt werden!");
    return false;
  } else {
    let url = wdb.meta.rest + "anno/entity/" + wdb.meta.id + "/" + type + "/" + start;
    
    $.ajax({
      method: "delete",
      url: url,
      headers: wdb.restheaders,
      success: function (data) {
        console.info("deleted entity (ancestor of " + start + ")");
        $('#annoInfo').text("Erfolgreich gelöscht").css("background-color", "white");
        return true;
      },
      error: function ( jqXHR, textStatus, errorThrown ) {
        let errorText = jqXHR.responseText.split("\n");
        $('#annoInfo').text(errorText[1]).css("background-color", "lightcoral");
        console.error(errorThrown, textStatus, jqXHR);
      }
    });
  }
}

/* 
 * change full text
 */
function editText() {
  let edit = $("#corr").val(),          // the new text for the selection
      start = $('#annFrom').text(),     // first ID in annotation range
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
        from: start,
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