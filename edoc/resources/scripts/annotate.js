var dialog;
$( function() {
    dialog = $("#annotationDialog").dialog({
        autoOpen: false,
        width: 'auto',
        close: function() {
            $('#fta')[0].reset();
            $('#la')[0].reset();
          }
    });
    $("#annotationDialogTabs").tabs();
    
    
    
        id = $("meta[name='id']").attr("content");
    cred = Cookies.get("wdbplus");
    headers = "";
    if (typeof cred !== "undefined" && cred.length != 0)
        headers = {"Authorization": "Basic " + cred};
    
    get = $.ajax({
        method: "get",
        url: "../../restxq/edoc/anno/" + id,
        headers: headers,
        success: function(data){
            $.each(
                data.entry,
                function( index, value ) {
                    console.log(index + ": " + value);
                    if (index > 0 && value.range["from"] != '') {
	                    start = $('#' + value.range["from"]);
	                    if (value.range["to"] == '' || value.range["to"] == 'undefined')
	                        end = start;
	                        else end = $('#' + value.range["to"]);
	                    if (end.length == 0)
	                        end = start;
	                    cat = value.range["from"] + "–" + value.range["to"] + ": " + value.cat;
	                    
	                    f = value.range["from"].substring(1);
	                    t = value.range["to"].substring(1);
	                    
	                    if(t > f) highlightAll(start, end, 'red', cat);
	                    else highlightAll(end, start, 'red', cat);
	                }
                }
            );
        }
    });
    
    $('#annButton').on("click", function() {
    	anno();
    });
});

function anno(){selection = window.getSelection();
    if (selection.focusNode === null && selection.anchorNode === null)
        return false;
    
    backwards = (selection.focusNode === selection.getRangeAt(0).startContainer);
    
    if (backwards) {
        end = selection.anchorNode.wholeText.trim() == '' ? selection.anchorNode.previousElementSibling.id
            : selection.anchorNode.parentNode.id;
        start = selection.focusNode.wholeText.trim() == '' ? selection.focusNode.nextElementSibling.id
            : (selection.focusNode.parentNode.id == '' ? selection.focusNode.parentNode.parentNode.id
                : selection.focusNode.parentNode.id);
    } else {
        start = selection.anchorNode.wholeText.trim() == '' ? selection.anchorNode.nextElementSibling.id
            : (selection.anchorNode.parentNode.id == '' ? selection.anchorNode.parentNode.parentNode.id
                : selection.anchorNode.parentNode.id);
        end = selection.focusNode.wholeText.trim() == '' ? selection.focusNode.previousElementSibling.id
            : selection.focusNode.parentNode.id;
    }
    
    $('#annText').text(selection.toString());
    $('#annFrom').text(start);
    $('#annTo').text(end);
    
    dialog.dialog("open");
};

cred = Cookies.get("wdbplus");
headers = "";
if (typeof cred !== "undefined" && cred.length != 0)
headers = {"Authorization": "Basic " + cred};

function parsefta() {
    id = $("meta[name='id']").attr("content");
    
    start = $('#annFrom').text();
    end = $('#annTo').text()
    annoText = $('#ftaText').val();
    dialog.dialog("close");
    
    put = $.ajax({
        method: "post",
        url: "../../restxq/edoc/anno/" + id,
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
        
    get = $.getJSON(
        "../../restxq/edoc/anno/" + id,
        function(data){ console.log(data); }
    );
    
    startElem = $('#' + start);
    endElem = $('#' + end);
    
    highlightAll(startElem, endElem, 'red', annoText);
}

function chgLayout(rend) {
    console.log(rend);
}

function identifyEntity() {
    id = $("meta[name='id']").attr("content");
    edit = $("#identity").val();
    type = $("#type").val();
    dialog.dialog("close");
    
    put = $.ajax({
        method: "post",
        url: "../../restxq/edoc/anno/entity/" + id,
        headers: headers,
        data: JSON.stringify({
            from: start,
            to: end,
            type: type,
            identity: identity
        }),
        contentType: "application/json; charset=UTF-8",
        dataType: 'json',
        success: function(data) {
            ins = data["#text"][0] + data.pc;
            if (data.lb) ins += "<br>";
            ins += data["#text"][1];
            $('#' + start).html(ins);
        }
    });
}

function editText() {
    id = $("meta[name='id']").attr("content");
    edit = $("#corr").val();
    dialog.dialog("close");
    
    if (start != end)
        alert("You can only change one word at a time!");
    else
    put = $.ajax({
        method: "post",
        url: "../../restxq/edoc/anno/word/" + id,
        headers: headers,
        data: JSON.stringify({
            id: start,
            text: edit,
            job: "edit"
        }),
        contentType: "application/json; charset=UTF-8",
        dataType: 'json',
        success: function(data) {
            ins = data["#text"][0] + data.pc;
            if (data.lb) ins += "<br>";
            ins += data["#text"][1];
            $('#' + start).html(ins);
        }
    });
}

function fshow(id) {
	anc = $(id).closest("form");
	anc.children().hide();
	$(id).show();
}