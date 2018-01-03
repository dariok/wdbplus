function show ( ed, file ) {
	url = 'projects.html?ed=' + ed + '&file=' + file;
	html = $.ajax({
			url: url,
			cache: false,
			success: function ( data ) {
					var result = $('<div/>').append( data ).find( '#data' ).html();
					console.log( result );
					$( '#rightSide' ).html( result );
				}
		});
}

/** fixed div at top of page: body needs offset for correct scrolling */
$(document).ready(function() {
	$('body').css('margin-top', $('#navBar').innerHeight());
});