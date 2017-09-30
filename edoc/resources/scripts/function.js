function marginPos (){
    var tar = window.location.hash;
    window.location.hash = '#';
    
	var mRefs = $("a.mref");
	if (mRefs.length > 0) {										   // Show margin container only if any are to be shown
		//$('#content').css('width', '79.5%');					 // changed values due to changed layout; 2016-07-25 DK
		$('#content').css('width', 'calc(80% - 0.15em)');
		$('#content').css('padding-left', '20%');
		$('#marginalia_container').height($('#content').height())
		navbarHeight = $('#navBar').height();
		mRefs.each(positionMarginalia);
		$('#marginalia_container').show();
	}
	
	window.location.hash = tar;
};
function positionMarginalia (index, element){
	var mRefs = $("a.mref");
	var thisRefPos = $(element)[0].offsetTop;
	var thisRefID = $(element).attr('id');
	var targetMargID = "#text_" + thisRefID;
	
	if (index > 0) {											  // the first element can in any case stay where it is
		var prevRefID = mRefs.eq(index-1).attr('id');
		var prevMargID = "#text_" + prevRefID;
		var prevMargTop = $(prevMargID)[0].offsetTop;
		var prevMargHeight = $(prevMargID)[0].offsetHeight;
	}
	else {
		prevMargTop = 0;
		prevMargHeight = 0;
	}
	
	if (thisRefPos > (prevMargTop + prevMargHeight))
		var targetTop = thisRefPos;
	else {
		var targetTop = prevMargTop + prevMargHeight + 1;
	}
	
	$(targetMargID)[0].style.top = targetTop - navbarHeight + 'px';
};

var loaded = false;
$(document).ready(function() {
	loaded = true;
});

var timer;
$(window).on('load resize', function() {
	//if (!loaded) return;
	
	clearTimeout(timer);
	timer = setTimeout(marginPos, 250);
});

// Für Hervorhebung einer Abfolge von Elementen
$(document).ready(function() {
    if (window.location.search.indexOf('&l') > -1) {
        var range = window.location.search.split('&l=')[1];
        var from = range.split('-')[0];
        var to = range.split('-')[1];
        $('#' + from).css('background-color', 'red');
        $('#' + from).nextUntil('#' + to).css('background-color', 'red');
        $('#' + to).css('background-color', 'red');
        var scrollto = $('#' + from).offset().top - $('#navBar').innerHeight(); // minus fixed header height
        console.log($('#' + from).offset().top);
        $('html, body').animate({scrollTop:scrollto}, 0);
    }
});
$(window).bind('hashchange', function() {
	var target = $(':target')
	if (!(target === undefined)) {
		var offset = $(':target').offset();
		console.log(offset);
        if ($('#navBar').innerHeight() > 0) {
            var scrollto = offset.top - $('#navBar').innerHeight(); // minus fixed header height
        } else {
            var scrollto = offset.top;
        }
        console.log(scrollto);
		
		$('html, body').animate({scrollTop:scrollto}, 0);

		if (window.location.hash) sprung();
	} else {
		console.log('no target - logout?')
	}
});

$(document).ready(function() {
	$('.fn_number').hover(mouseIn, mouseOut);
});

function mouseIn (event) {
	var maxWidth = 400;
	var me = $(this),
		fm = $(me.attr('href')).html(),
		id = 'i' + me.attr('href').substring(1),
		cont = $('<span id="' + id + '" class="infoContainer" style="display: block;"></span>"'),
		content = $('<span class="infoContent" style="display: block; white-space: nowrap;">' + fm + '</span>');
																	// nowrap to get the length of the string in pixels
	$('#ann').html(content.html());
	$('#ann').append('<a onclick="clear();" href="javascript:clear()">[x]</a>')
	
	/*var fn = cont.append(content);
	me.after(fn);
	
	var tPos, lPos, fWidth;
	if (fn.innerWidth() > maxWidth) fWidth = maxWidth;
	else fWidth = fn.innerWidth();
	
	if ((fWidth + me.offset().left + 20) > window.innerWidth) {								// position the info window
		lPos = window.innerWidth - fWidth - 20 - (window.innerWidth - $(window).width());
		tPos = me.position().top + 20;
		fn.offset({ left: lPos, top: tPos});
		fn.css('top', tPos);
	}
	else {
		lPos = me.position().left + 20;
		tPos = me.position().top + 20;
		fn.css('left', lPos).css('top', tPos);
	}
	
	fn.css('max-width' , maxWidth);
	content.css('white-space', 'normal');								   // allow word wrapping to fit into max width
	fn.outerWidth(fWidth);*/
}

function clear () {
	$('#ann').html('');
}

function mouseOut (event) {
	var id = '#i' + $(this).attr('href').substring(1);
	console.log(id);
	setTimeout(detach, 2000, id);
}

function detach (id) {
	$(id).detach();
}

function commonAncestor (e1, e2) {
	var p1 = e1.parents().get().reverse();
	var p2 = e2.parents().get().reverse();
	
	for (var i = 0; i < p1.length; i++) {
		if (p1[i] != p2[i]) return p1[i - 1];
	}
}

function sprung (event) {
    console.log(event);
	var targ = window.location.hash.substring(1);
	var startMarker = $(".anchorRef#" + targ);
	if (startMarker.length == 0) return;
	
	// select with filter through specific class to avoid highlighting between crit. notes a and ae
	var endMarker = $(".anchorRef#" + targ + "e");
	// only go through this, if there actually is an end marker
	if (endMarker.length == 0) return;
	
	var cA = $(commonAncestor(startMarker, endMarker));
	
	// Step 1: highlight all »startMarker/following-sibling::node()« 
	// 1a: Wrap all of its siblings in a span: text-nodes cannot be accessed via jQuery »in the middle«
	startMarker.parent().contents().filter(function() {
		return this.nodeType === 3;
	}).wrap("<span></span>");
	
	// 1b: Colour its later siblings if they dont have the end point marker
	var done = false;
	startMarker.nextAll().addBack().each(function() {
		if ($(this).has(endMarker).length > 0 || $(this).is(endMarker)) return;
		else {
			$(this).css("background-color", "#FFEF19");
		}
	});
	
	// Step 2: highlight »(startMarker/parent::*/parent::* intersect endMarker/parent::*/parent::*)//*)«
	// 2a: Get startMarker's parents up to the common ancestor
	var parentsList = startMarker.parentsUntil(cA);
	
	if (parentsList.has(endMarker).length === 0) {
		// go through each of these and access later siblings
		var has_returned = false;
		parentsList.each(function() {
			$(this).nextAll().each(function() {
				if (has_returned) return;
				
				// we need to handle the endMarker's parent differently
				if ($(this).has(endMarker).length > 0) {
					has_returned = true;
					return;
				} else {
					$(this).css("background-color", "#FFEF19");
				}
			});
		});
	};
	
	// Step 3: as step 1	
	// 3a: Wrap alls of endMarker's siblings in a span
	endMarker.parent().contents().filter(function() {
		return this.nodeType === 3;
	}).wrap("<span></span>");
	
	//3b: Colour its earlier siblings if they dont have start marker
	$(endMarker.prevAll().addBack().get().reverse()).each(function() {
		if ($(this).has(startMarker).length > 0
				|| $(this).is(startMarker)
				|| $(this).nextAll().has(startMarker)
		) return;
		else {
			$(this).css("background-color", "#FFEF19");
		}
	});
	
	// Step 4: colour all ancestors to the common ancestor
	// Get parents up until common ancestor
	var parentsListEnd = endMarker.parentsUntil(cA.children().has(endMarker));
	if (parentsListEnd.has(startMarker).length === 0) {
		// Go through each of these and access earlier siblings
		done = false;
		parentsListEnd.each(function() {
			$(this).prevAll().each(function() {
				if (done) return;
				
				if ($(this).has(startMarker).length > 0 || $(this).is(startMarker)) {
					done = true;
					return;
				} else {
					$(this).css("background-color", "#FFEF19");
				}
			});
		});
	}
}

/** fixed div at top of page: body needs offset for correct scrolling */
$(document).ready(function() {
	$('body').css('margin-top', $('#navBar').innerHeight());
});
//$(window).on('resize', function() {
//	$('#navBar').innerWidth($('body').innerWidth());
//});

/** Navigation sidebar **/
function toggleSidebar() {
	if ($('#sideBar').css('display') == 'none')
		$('#liSB').text('Navigation ausblenden');
	else $('#liSB').text('Navigation einblenden');
	
	if($('#sideBar').text() === '') {
		$('#sideBar').text('lädt...');
		var id = $('meta[name="edition"]').attr('content');
		var res = $.get('http://dev2.hab.de/apps/wdb/modules/mets.xql?id=' + id, '',
				function(data) { $('#sideBar').html($('div > ul', data).attr('id', 'nav')).prepend($('<h2>Navigation</h2>')); },
				'html');
	}
	$('#sideBar').slideToggle();
}

/*function pView(target) {
	var disp = $('#facsimile');
	disp.text(target);
	disp.toggle();
}*/

function show_annotation (dir, xml, xsl, ref, height, width) {
	var info = $('<div class="info"></div>');
	var q = 'http://dev2.hab.de/edoc/entity.html?id=' + ref + '&reg=' + xml + '&ed=' + dir;
	console.log(q);
	
	$.ajaxSetup({ cache: false });
	var res = $.get(q, '', function(data, textStatus, jqXHR) { 
        var ins = $('<div></div>');
        ins.append($(data).find("#navBar").html());
        ins.append($(data).find(".content").html());
        ins.append('<a href="javascript:clear();">[x]</a>');
        $('#ann').html(ins.html());
	}, 'html');
}

function switchlayer(Layer_Name) {
	var target = '#' + Layer_Name.replace( /(,|:|\.|\[|\])/g, "\\$1" );
	$(target).toggle();
}

/** AJAX functions to enable login in NavBar **/
// url: '/apps/wdb/modules/auth.xql',
$(document).ready(function(){
	$('#login').submit(function(e){
		$.ajax({
		    url: 'login',
		    method: 'post',
			data: {user: $('#user').val(),
				password: $('#password').val(),
				edition: $('#edition').val()
			},
			success: function(data) {
				try {
				    $('#login').html(data);
					console.log('logged in');
					console.log(data);
				}
				catch (e) {
				    console.log('logged in, tried to replace #login with:');
				    console.log(data);
				    console.log(e);
				}
			},
			dataType: 'text'}
		);
		e.preventDefault();
	});
})
$(document).ready(function(){
    $('#logout-button').click(function(e){
        $.ajax({
            url: 'login',
            method: 'post',
            data: {logout: 'logout'},
            success: function(data) { 
                try {
                	$('#logout').html(data);
                	console.log('trying to log off' + data);
                }
                catch (e) {
                    console.log('logging out, tried to replace #logout with:');
                    console.log(data);
                    console.log(e);
                }},
            dataType: 'text'}
        );
    });
});

// Parallel view
$(document).ready(function(){
	$('.pagebreak > a').click(function(event){
		event.preventDefault();
		href = $(this).attr('href');
		$('#fac').html('<iframe id="facsimile"></iframe>');
		$('#facsimile').attr('src', href);
		$('#facsimile').css('display', 'block');
	});
});