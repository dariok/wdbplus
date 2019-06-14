/* W.DB+ common functions
 * author: Dario Kampkaspar, dario.kampkaspar@oeaw.ac.at
 * https://github.com/dariok/wdbplus
 */

/* global variables */
var timer;                 // timer for marginalia positioning
var internalUniqueId = 0;  // basis for globally unique IDs
var id = $("meta[name='id']").attr("content");
var rest = $("meta[name='rest']").attr("content");
let ar = window.location.search.substr(1).split("&");
var params = new Object();
for (let i = 0; i < ar.length; i++) {
  let te = ar[i].split("=");
  params[te[0]] = te[1];
}

/* Collect all $(document).ready() .on('load') etc. functions*/

/* set/reset timer for marginalia positioning and invoke actual function */
$(window).on('load resize', function (event) {
    clearTimeout(timer);
    timer = setTimeout(marginPos, 500);
});

// Für Hervorhebung einer Abfolge von Elementen
$(document).ready(function () {
    if (params.hasOwnProperty('l')) {
        var range = window.location.search.split('&l=')[1];
        var from = range.split('-')[0];
        var to = range.split('-')[1];
        $('#' + from).css('background-color', 'red');
        $('#' + from).nextUntil('#' + to).css('background-color', 'red');
        $('#' + to).css('background-color', 'red');
        var scrollto = $('#' + from).offset().top - $('#navBar').innerHeight();
        // minus fixed header height
        console.log($('#' + from).offset().top);
        $('html, body').animate({
            scrollTop: scrollto
        },
        0);
        
        var pb = $('#' + from).parents().has('.pagebreak').first().find('.pagebreak a');
        displayImage(pb.attr('href'));
    }
});
$(document).ready(function() {
  if (params.hasOwnProperty('i')) {
    let ids = params.i.split(',');
    for (let i = 0; i < ids.length; i++) {
      $('#' + ids[i]).css('background-color', 'lightblue');
    }
  }
});

/* autoload image */
// ... when jumping to target
$(window).bind('hashchange', function () {
    loadTargetImage();
});
// when loading; or load p. 1 when no target is present
$(document).ready(function () {
    if($('.pagebreak').length > 0) {
		var target = $('.pagebreak > a').first().attr('href');
	    var tar = window.location.hash;
	    
	    if (tar !== '' && tar !== 'undefined') {
	        loadTargetImage();
	    } else {
	        displayImage(target);
	    }
    } else {
    	// TODO Text oder Image, wenn kein pb vorhanden
    	// TODO ggf. getrennt für "verschollen"
    }
});

/* Login and logout */
// url: 'edoc/modules/auth.xql'
$(document).ready(function () {
	$('#login').submit(function (e) { login(e) });
})
function login (e) {
	e.preventDefault();
	username = $('#user').val();
	password = $('#password').val();
	console.log('login request');
	
	$.ajax({
		url: 'login',
		method: 'post',
		data: {
			user: username,
			password: password,
			edition: $('#edition').val()
		},
		success: function (data) {
			try {
				$('#auth').replaceWith(data);
				console.log('logged in');
				console.log(data);
			} catch (e) {
				console.log('logged in, tried to replace #login with:');
				console.log(data);
				console.log(e);
			}
		},
		dataType: 'text'
	});
	Cookies.set('wdbplus', btoa(username + ':' + password));
}
function doLogout () {
	console.log('logout request');
	Cookies.remove('wdbplus');
	$.ajax({
		url: 'login',
		method: 'post',
		data: {
			logout: 'logout'
		},
		success: function (data) {
			try {
				$('#auth').replaceWith(data);
				console.log('trying to log off' + data);
			} catch (e) {
				console.log('logging out, tried to replace #logout with:');
				console.log(data);
			}
		},
		dataType: 'text'
	});
}
/* END login and logout */

// load image in right div when clicking on a page number
$(document).ready(function () {
    $('.pagebreak a').click(function (event) {
        event.preventDefault();
        href = $(this).attr('href');
        displayImage(href);
    });
});
/* END GLOBAL FUNCTIONS */

/* OTHER FUNCTIONS */
/* autoloading of images */
function loadTargetImage () {
    var target = $(':target');
    if (target.length > 0) {
        if (target.attr('class') == 'pagebreak') {
            console.log($(':target > a').attr('href'));
            displayImage($(':target > a').attr('href'));
        } else {
            var pb = target.parents().has('.pagebreak').first().find('.pagebreak a');
            displayImage(pb.attr('href'));
        }
    } else {
        
        console.log('no target - logout?');
    }
}

/* postioning of marginalia */
function marginPos () {
    var mRefs = $("a.mref");
    if (mRefs.length > 0) {
        // Show margin container only if any are to be shown
        var tar = window.location.hash;
        if (tar !== '' && tar !== 'undefined') {
            window.location.hash = '#';
        }
        
        //$('#content').css('width', 'calc(80% - 1em)');
        //$('#content').css('padding-left', '1em');
        mRefs.each(positionMarginalia);
        $('#marginalia_container').children('span').css('visibility', 'visible');
        
        if (tar !== '' && tar !== 'undefined') {
            window.location.hash = tar;
        }
    }
};
function positionMarginalia (index, element) {
    thisRefID = $(element).attr('id');
    thisRefPos = getPosition(document.getElementById(thisRefID)).y;
    targetMargID = "#text_" + thisRefID;
    
    marginalie = $(targetMargID);
    previous = marginalie.prev();
    pid = previous.attr('id');
    
    if (previous.length == 0) {
        targetTop = thisRefPos - $('header').height();
    } else {
        pHeight = parseFloat(previous.height());
        pTop = parseFloat(previous.css('top').match(/^\d+/));
        hHeight = $('header').height();
        mTop = pHeight + pTop;
        console.log(previous.css('top'));
        console.log(thisRefID + ": pT: " + pTop + "; pH: " + pHeight + "; mTop: " + mTop + "; preTop: " + previous.position().top);
        if (Math.floor(thisRefPos - hHeight) < pTop + pHeight) {
            //targetTop = 'calc(' + (thisRefPos - $('header').height()) + 'px + ' + pHeight + 'px)';
            targetTop = (pTop + pHeight) + "px";
        } else {
            targetTop = thisRefPos - hHeight;
        }
    }
    console.log(thisRefID + ': ' + targetTop);
    // offset is relative to the document, so the header has to be substracted if top is set via
    // CSS - which is necessary because setting the offset will change position and left
    $(targetMargID).css('top', targetTop);
};
function getPosition(el) {
    var xPos = 0;
    var yPos = 0;
    
    while (el) {
        if (el.tagName == "BODY") {
            // deal with browser quirks with body/window/document and page scroll
            var xScroll = el.scrollLeft || document.documentElement.scrollLeft;
            var yScroll = el.scrollTop || document.documentElement.scrollTop;
            
            xPos += (el.offsetLeft - xScroll + el.clientLeft);
            yPos += (el.offsetTop - yScroll + el.clientTop);
        } else {
            // for all other non-BODY elements
            xPos += (el.offsetLeft - el.scrollLeft + el.clientLeft);
            yPos += (el.offsetTop - el.scrollTop + el.clientTop);
        }
        
        el = el.offsetParent;
    }
    return {
        x: xPos,
        y: yPos
    };
}
/* end marginalia */

/*****
 *  Display annotations – footnotes, critical apparatus and similar on mouseover
 *****/
/* when hovering over a footnote, display it in the right div */
$(document).ready(function () {
    $('.fn_number').hover(mouseIn, mouseOut);
});
/* load notes into right div on hover */
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
    
    // legacy code for an advanced mouseover 
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
function mouseOut (event) {
    var id = '#i' + $(this).attr('href').substring(1);
    console.log(id);
    setTimeout($(id).detach(), 2000, id);
}
/*****
 * Display “external” (i.e. not found within the current view) information such as (but not limited to) entities
 *****/

// show annotation in right div
function show_annotation (ref, xml, dir) {
    var info = $('<div class="info"></div>');
    var q = 'entity.html?id=' + ref + '&reg=' + xml + '&ed=' + dir;
    console.log(q);
    var uid = getUniqueId();
    
    $.ajax({
        url: q,
        method: 'get',
        success: function (data) {
            var ins = $('<div/>');
            var wrap = $('<div/>');
            wrap.attr('id', uid);
            var res = $.parseHTML(data);
            ins.html(data);
            wrap.append(ins.find('div'));
            wrap.append('<a href="javascript:clear(\'' + uid + '\');" title="Diesen Eintrag schließen">[x]</a>');
            wrap.append('<a href="javascript:clear();" title="Alle Informationen rechts schließen">[X]</a>');
            $('#ann').append(wrap);
        },
        dataType: 'html'
    });
}

/* display external URL */
function showAnnotation (url) {
  var info = $('<div class="info"></div>');
  var uid = getUniqueId();
  
  $.ajax({
    url: url,
    method: 'get',
    success: function (data) {
      var ins = $('<div/>');
      var wrap = $('<div/>');
      wrap.attr('id', uid);
      var res = $.parseHTML(data);
      ins.html(data);
      wrap.append(ins.find('div'));
      wrap.append('<a href="javascript:clear(\'' + uid + '\');" title="Diesen Eintrag schließen">[x]</a>');
      wrap.append('<a href="javascript:clear();" title="Alle Informationen rechts schließen">[X]</a>');
      $('#ann').append(wrap);
    },
    dataType: 'html'
  });
}
/* END hover */

/* close elements */
function clear (id) {
    if (id == '' || id == null) {
        $('#ann').html('');
        console.log('close all');
    } else {
        $('#' + id).detach();
        console.log('close ' + id);
    }
}

/* functions for highlighting arbitrary element ranges */
function commonAncestor (e1, e2) {
    var p1 = e1.parents().add(e1). get ();
    var p2 = e2.parents().add(e2). get ();
    
    for (var i = 0; i < p1.length; i++) {
        if (p1[i] != p2[i]) return p1[i - 1];
    }
}
function sprung (event) {
    var targ = window.location.hash.substring(1);
    var startMarker = $(".anchorRef#" + targ);
    if (startMarker.length == 0) return;
    
    // select with filter through specific class to avoid highlighting between crit. notes a and ae
    var endMarker = $(".anchorRef#" + targ + "e");
    // only go through this, if there actually is an end marker
    if (endMarker.length == 0) return;
    
    highlightAll (startMarker, endMarker);
}
function highlightAll (startMarker, endMarker, color, alt) {
	color = (color === 'undefined') ? '#FFEF19' : color;
	alt = (alt === 'undefined') ? '' : alt;
	
    if (startMarker.is(endMarker)) {
        // just one element selected
        startMarker.css("background-color", color);
        if (alt != '') startMarker.attr('title', alt);
    } else if (startMarker.parent().is(endMarker.parent())) {
        // both elements have the same parent
        // 1a: Wrap all of its (text node) siblings in a span: text-nodes cannot be accessed via jQuery »in the middle«
        startMarker.parent().contents().filter(function () {
            return this.nodeType === 3;
        }).wrap("<span></span>");
        
        // Colour and info for the start marker
        $(startMarker).css("background-color", color);
        if (alt != '') $(startMarker).attr('title', alt);
        
        // Colour and info for the siblings until the end marker
        sib = $(startMarker).nextUntil(endMarker);
        sib.css("background-color", color);
        if (alt != '') sib.attr('title', alt);
        
        // Colour and info for the end marker
        $(endMarker).css("background-color", color);
        if (alt != '') $(endMarker).attr('title', alt);
        //DONE
    } else {
        // check further down the ancestry
        cA = $(commonAncestor(startMarker, endMarker));
        console.log(cA);
        
        // Step 1: highlight all »startMarker/following-sibling::node()«
        // 1a: Wrap all of its (text node) siblings in a span: text-nodes cannot be accessed via jQuery »in the middle«
        startMarker.parent().contents().filter(function () {
            return this.nodeType === 3;
        }).wrap("<span></span>");
        
        // 1b: Colour its later siblings if they dont have the end point marker
        done = false;
        startMarker.nextAll().addBack().each(function () {
            if ($(this).has(endMarker).length > 0 || $(this).is(endMarker)) return; else {
                $(this).css("background-color", color);
                if (alt != '') $(this).attr('title', alt);
            }
        });
        
        // Step 2: highlight »(startMarker/parent::*/parent::* intersect endMarker/parent::*/parent::*)//*)«
        // 2a: Get startMarker's parents up to the common ancestor
        parentsList = startMarker.parentsUntil(cA);
        
        if (parentsList.has(endMarker).length === 0) {
            // go through each of these and access later siblings
            has_returned = false;
            parentsList.each(function () {
                $(this).nextAll().each(function () {
                    if (has_returned) return;
                    
                    // we need to handle the endMarker's parent differently
                    if ($(this).has(endMarker).length > 0) {
                        has_returned = true;
                        return;
                    } else {
                        $(this).css("background-color", color);
                        if (alt != '') $(this).attr('title', alt);
                    }
                });
            });
        };
        
        // Step 3: as step 1
        // 3a: Wrap alls of endMarker's siblings in a span
        endMarker.parent().contents().filter(function () {
            return this.nodeType === 3;
        }).wrap("<span></span>");
        
        //3b: Colour its earlier siblings if they dont have start marker
        $(endMarker.prevAll().addBack(). get ().reverse()).each(function () {
            if ($(this).has(startMarker).length > 0 || $(this).is(startMarker) || $(this).nextAll().has(startMarker).length > 0) return; else {
                $(this).css("background-color", color);
                if (alt != '') $(this).attr('title', alt);
            }
        });
        
        // Step 4: colour all ancestors to the common ancestor
        // Get parents up until common ancestor
        var parentsListEnd = endMarker.parentsUntil(cA.children().has(endMarker));
        if (parentsListEnd.has(startMarker).length === 0) {
            // Go through each of these and access earlier siblings
            done = false;
            parentsListEnd.each(function () {
                $(this).prevAll().each(function () {
                    if (done) return;
                    
                    if ($(this).has(startMarker).length > 0 || $(this).is(startMarker)) {
                        done = true;
                        return;
                    } else {
                        $(this).css("background-color", color);
                        if (alt != '') $(this).attr('title', alt);
                    }
                });
            });
        }
    }
}
/* END highlighting */

/** Navigation **/
function toggleNavigation() {
    if ($('nav').css('display') == 'none')
    $('#showNavLink').text('Navigation ausblenden'); else $('#showNavLink').text('Navigation einblenden');
    
    if ($('nav').text() === '') {
        $('nav').text('lädt...');
        id = $('meta[name="id"]').attr('content');
        res = $. get (rest + 'collection/' + id + '/nav.html', '',
        function (data) {
            $('nav').html($(data)).prepend($('<h2>Navigation</h2>'));
        },
        'html');
    }
    $('nav').slideToggle();
}

function load (url, target, me) {
    if ($('#' + target).css('display') == 'none') {
      res = $.ajax(url,
        {
          dataType: "html",
          success: function (data) {
              $('#' + target).html($(data).children('ul'));
              $('#' + target).slideToggle();
              $(me).html('↑');
          },
          error: function (xhr, status, error) {
            console.log("error");
            console.log(status);
            console.log(error);
          }
        }
      );
    } else {
      $('#' + target).slideToggle();
      $(me).html('→');
    }
}

/* create a runtime unique global ID */
function getUniqueId() {
    return 'd' + internalUniqueId++;
}

/* display an image in the right div */
function displayImage(href) {
    $('#fac').html('<iframe id="facsimile"></iframe><span><a href="javascript:close();">[x]</a></span>');
    $('#facsimile').attr('src', href);
    $('#facsimile').css('display', 'block');
    //$('#facsimile').css('width', '100%').css('height', '100%');
}

/* toggle rightSide visibility */
function toggleRightside() {
    if ($('#wdbShowHide > a').html() == '»') {
        //$('#wdbRight').width('1em');
        $('#wdbContent').css('max-width', '75%');
        $('#wdbShowHide > a').html('«');
        //$('#container').width('calc(100% - 1.5em)');
    } else {
        //$('#wdbRight').width('calc(50% - 3em)');
        $('#wdbContent').css('max-width', 'calc(50% - 3em)');
        $('#wdbShowHide > a').html('»');
        //$('#container').width('50%');
    }
}

/* close one or all info displayed to the right */
function close() {
    link = $('#fac span a');
    if (link.text() == '[x]') {
        $('#facsimile').css('display', 'none');
        link.text('[« Digitalisat zeigen]');
    } else {
        $('#facsimile').css('display', 'block');
        link.text('[x]');
    }
}

/* toggle TOC level visibility */
function switchnav(id) {	
  $(id).children('ul').children().toggle();
}
function switchnav(id, a) {	
  $(id).children('ul').children().toggle();
  $(a).html() == '→' ? $(a).html('↑') : $(a).html('→');
}

/* preparations to show some loading animation while doing AJAX requests */
$(document).bind({
	ajaxStart: function() { $("body").addClass("loading"); },
	ajaxStop: function() { $("body").removeClass("loading"); }
});