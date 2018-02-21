function anno(){
    selection = window.getSelection();
    backwards = (selection.focusNode === selection.getRangeAt(0).startContainer);
    
    if (backwards) {
        end = selection.anchorNode.wholeText.trim() == '' ? selection.anchorNode.previousElementSibling.id
            : selection.anchorNode.parentNode.id;
        start = selection.focusNode.wholeText.trim() == '' ? selection.focusNode.nextElementSibling.id
            : selection.focusNode.parentNode.id;
        
        /*console.log('a: ' + start + ': ' + selection.anchorNode.wholeText);
        console.log('f: ' + end + ': ' + selection.focusNode.wholeText);*/
    } else {
        start = selection.anchorNode.wholeText.trim() == '' ? selection.anchorNode.nextElementSibling.id
            : selection.anchorNode.parentNode.id;
        end = selection.focusNode.wholeText.trim() == '' ? selection.focusNode.previousElementSibling.id
            : selection.focusNode.parentNode.id;
    }
    
    annoText = window.prompt("Anmerkung", "");
    id = $("meta[name='id']").attr("content");
    
    put = $.get("insert.xql", 
        {
            file: id,
            from: start,
            to: end,
            cat: annoText
        });
        
    get = $.getJSON(
        "return.xql",
        {file: id},
        function(data){ console.log(data); }
    );
    
    startElem = $('#' + start);
    endElem = $('#' + end);
    
    highlightAll(startElem, endElem, 'red', annoText);
}

$(document).ready(function() {
    id = $("meta[name='id']").attr("content");
    get = $.getJSON(
        "return.xql",
        {file: id},
        function(data){
            $.each(
                data.entry,
                function( index, value ) {
                    if (index > 0) {
	                    start = $('#' + value.range["from"]);
	                    end = $('#' + value.range["to"]);
	                    cat = value.cat;
	                    
	                    highlightAll(start, end, 'red', cat);
	                }
                }
            );
        }
    );
});