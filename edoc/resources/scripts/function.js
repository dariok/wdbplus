/* W.DB+ common functions
 * author: Dario Kampkaspar, dario.kampkaspar@oeaw.ac.at
 * https://github.com/dariok/wdbplus
 */
/* jshint browser: true */

const wdb = (function() {
  // all meta elements
  let meta = {};
  for (let m of document.getElementsByTagName("meta")) {
    meta[m.name] = m.content;
  }
  
  // parsed query parameters; URLSearchParams is not supported by Edge < 17 and IE
  /* TODO https://github.com/dariok/wdbplus/issues/429
      current support data: c. 91% should support URLSearchParams – switch when support > 95% */
  let params = {};
  for (let ar of window.location.search.substr(1).split("&")) {
    let te = ar.split("=");
    params[te[0]] = te[1];
  }
  
  // unique IDs
  let internalUniqueId = 0;               // basis for globally unique IDs
  let getUniqueId = function () {
    return 'wdb' + ('000' + internalUniqueId++).substr(-4);
  };

  /* Login and logout */
  let login = function (that, event) {
	  event.preventDefault();
  
    let username = $('#user').val(),
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
          setAuthorizationHeader();
          console.log('logged in');
        } catch (e) {
          console.error('error logging in:');
          console.error(e);
        }
      },
      dataType: 'text'
    });
    Cookies.set('wdbplus', btoa(username + ':' + password));
  };

  let logout = function () {
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
          setAuthorizationHeader();
          console.log('logging off');
        } catch (e) {
          console.error('error logging out:');
          console.error(e);
        }
      },
      dataType: 'text'
    });
  };
  /* END login and logout */

  /* globals Cookies */
  /* TODO when modules are available, import js.cookie.mjs via CDN; current support 90.5% */
  // function to set REST headers
  let restHeaderVal = { };
  let setAuthorizationHeader = function () {
    let cred = Cookies.get("wdbplus");
    if (typeof cred == "undefined" || cred.length == 0)
      restHeaderVal.Authorization = "";
      else restHeaderVal = { "Authorization": "Basic " + cred };
  };
  setAuthorizationHeader();
  
  return {
    meta:           meta,
    parameters:     params,
    restHeaders:    restHeaderVal,
    setRestHeaders: setAuthorizationHeader,
    getUniqueId:    getUniqueId,
    login:          login,
    logout:         logout
  };
})();
Object.freeze(wdb);

/* functions for manipulating the HTML document */
const wdbDocument = {
  highlightRange: function ( range ) {
    let from = range.split('-')[0],
        to = range.split('-')[1];
    
    highlightAll (from, to, 'red', '');

    let scrollto = $('#' + from).offset().top - $('#navBar').innerHeight();
    // minus fixed header height
    // console.log($('#' + from).offset().top);
    $('html, body').animate({scrollTop: scrollto}, 0);
      
    let pb = $('#' + from).parents().has('.pagebreak').first().find('.pagebreak a');
    displayImage(pb);
  },

  loadTargetImage: function () {
    let target = $(':target');
    if (target.length > 0) {
      if (target.attr('class') == 'pagebreak') {
        console.log("trying to load image: " + $(':target > a').attr('href'));
        displayImage($(':target > a'));
      } else {
        let pagebreak = target.parents().has('.pagebreak').first(),
            pb = (pagebreak.find('a').length > 1) ? pagebreak.find('.pb a') : pagebreak.find('a');
        displayImage(pb);
      }
    }
  },

  /* postioning of marginalia */
  positionMarginalia: function () {
    let mRefs = $("a.mref");
    if (mRefs.length > 0) {
      // Show margin container only if any are to be shown
      let tar = window.location.hash;
      if (tar !== '' && tar !== 'undefined') {
        window.location.hash = '#';
      }
      
      mRefs.each(wdbDocument.marginaliaPositioningCallback);
      $('#marginalia_container').children('span').css('visibility', 'visible');
      
      if (tar !== '' && tar !== 'undefined') {
        window.location.hash = tar;
      }
    }
  },

  /* actual positioning */
  marginaliaPositioningCallback: function (index, element) {
    let referenceElementID = $(element).attr('id'),
        referenceElementTop = $('#' + referenceElementID).position().top,
        marginNote = $("#text_" + referenceElementID),
        previousMarginNote = marginNote.prev(),
        targetTop;
    
    if (previousMarginNote.length == 0) {
      targetTop = referenceElementTop - $('header').height();
    } else {
      let previousNoteHeight = $(previousMarginNote).height(),
          previousNoteTop = $(previousMarginNote).position().top,
          headerHeight = $('header').height(),
          minimumTargetTop = previousNoteHeight + previousNoteTop;
  
      if (Math.floor(referenceElementTop - headerHeight) < minimumTargetTop) {
        targetTop = previousNoteTop + previousNoteHeight;
      } else {
        targetTop = referenceElementTop - headerHeight;
      }
    }
    
    console.info("position for " + referenceElementID + ': ' + targetTop);
    // offset is relative to the document, so the header has to be substracted if top is set via
    // CSS - which is necessary because setting the offset will change position and left
    marginNote.css('top', targetTop + "px");
  },

  marginaliaTimer: {},

  /* load notes into right div on hover */
  showInfoRight: function ( elementID ) {
    let content = $('#' + elementID).html(),
        insertID = wdb.getUniqueId(),
        insertContent = $('<span id="' + insertID + '" class="infoContainer" style="display: block;">' +
          content +
          '<a onclick="clear();" href="javascript:clear(\'' + insertID + '\')">[x]</a></span>');
  
    $('#ann').html(insertContent);
  },

  // show content in an advanced mouseover 
  showInfoFloating: function ( pointerElement, elementID ) {
    const maxWidth = 400,
          distance = 20;
    let content = $('#' + elementID).html(),
        insertID = wdb.getUniqueId(),
        insert = '<span id="' + insertID + '" class="infoContainer" style="display: block;">' +
          content +
          '</span>';
    $(insert).insertAfter(pointerElement);
    let $inserted = $('#' + insertID);

    // position the info box close to the pointing element
    let targetTop,
        targetLeft,
        $pointer = $(pointerElement),
        targetWidth = Math.min(maxWidth, $inserted.innerWidth);
    
    // set the left coordinate for the info box. The right end must not leave the visible ares
    if ((targetWidth + $pointer.offset().left + distance) > $(window).width()) {								// position the info window
      targetLeft = $(window).width() - targetWidth - distance;
      targetTop = $pointer.position().top + distance;
    } else {
      targetLeft = $pointer.position().left + distance;
      targetTop = $pointer.position().top + distance;
    }
    $inserted.offset({ left: targetLeft, top: targetTop})
      .css('max-width' , maxWidth)
      .outerWidth(targetWidth);
  },
  
  mouseOut: function (pointerElement) {
    let id = '#wdb' + $(pointerElement).attr('href').substring(1);
    setTimeout(function(id){ $(id).remove(); }, 2000, id);
  }
};
Object.freeze(wdbDocument);

/***
 * wdbUser: functions here can be overridden by projects; in most cases, examples
 * are given for different variants.
 */
const wdbUser = {
  // what to do when the mouse enters a footnote pointer
  footnoteMouseIn: function ( event ) {
    event.preventDefault();

    // example: show info text in a float
    //wdbDocument.showInfoFloating(event.target, event.target.hash.substring(1));

    // example: show info on the right
    wdbDocument.showInfoRight(event.target.hash.substring(1));
  },

  // what to do when the mouse leaves the footnote pointer
  footnoteMouseOut: function ( event ) {
      event.preventDefault();

      // example: remove the float
      //wdbDocument.mouseOut(event.target);
  }
};

/***
 * Functions to be executed after the DOM is ready (formerly $(document).ready())
 * includes highlighting and image loading functions
 ***/
$(function () {
  // highlight a range of elements given by the »l« query parameter and scroll there
  if (wdb.parameters.hasOwnProperty('l')) {
    wdbDocument.highlightRange(wdb.parameters.l);
  }

  // highlight several elements given by a comma separated list in the »i« query parametter
  if (wdb.parameters.hasOwnProperty('i')) {
    for (let ids of wdb.parameters.i.split(',')) {
      $('#' + ids).css('background-color', 'lightblue');
    }
  }

  // load image for target page (or first page if no fragment requested)
  if($('.pagebreak').length > 0) {
    if (window.location.hash != "") {
      wdbDocument.loadTargetImage();
    } else {
      displayImage($('.pagebreak a').first());
    }
  }

  /* when hovering over a footnote, display it in the right div */
  $('.fn_number').hover(wdbUser.footnoteMouseIn, wdbUser.footnoteMouseOut);
});
/* END DOM ready functions */

/***
 *  event handlers on window properties
 ***/
// load image when jumping to target
$(window).bind('hashchange', function () {
  wdbDocument.loadTargetImage();
});

/* set/reset timer for marginalia positioning and invoke actual function */
$(window).on('load resize', function () {
  clearTimeout(wdbDocument.marginaliaTimer);
  wdbDocument.marginaliaTimer = setTimeout(wdbDocument.positionMarginalia(), 500);
});
/* END window event handlers */

/***
 * other event handlers
 */
// load image when clicking on a page number
$('.pagebreak a').click(function (event) {
  event.preventDefault();
  displayImage($(this));
});
/* END other event handlers */


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
        id = $('meta[name="ed"]').attr('content');
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
              $(me).html($(me).html().replace('→', '↑'));
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
      $(me).html($(me).html().replace('↑', '→'));
    }
}

/* display an image in the right div */
function displayImage(element) {
    let href = element.attr('href');
    $('#fac').html('<iframe id="facsimile"></iframe><span><a href="javascript:close();">[x]</a></span>');
    $('#facsimile').attr('src', href);
    $('#facsimile').css('display', 'block');
    //$('#facsimile').css('width', '100%').css('height', '100%');
}

/* width of main: 50% or 66% */
function toggleRightside() {
    if ($('#wdbShowHide > a').html() == '»') {
        $('body').css('grid-template-columns', '2fr 1fr');
        $('#wdbShowHide > a').html('«').attr('title', "linke Seite schmaler");
    } else {
        $('body').css('grid-template-columns', '1fr 1fr');
        $('#wdbShowHide > a').html('»').attr("title", "linke Seite breiter");
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
