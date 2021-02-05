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
  let login = function (event) {
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
  // get the common ancestor of 2 elements
  commonAncestor: function ( element1, element2 ) {
    let parent1 = element1.parents().add(element1).get(),
        parent2 = element2.parents().add(element2).get();
    
    for (let i = 0; i < parent1.length; i++) {
      if (parent1[i] != parent2[i]) return parent1[i - 1];
    }
  },

  // highlight a range of elements – given as "e1-e2"
  highlightRange: function ( range ) {
    let from = range.split('-')[0],
        to = range.split('-')[1];
    
    this.highlightElements (from, to, 'red', '');

    let scrollto = $('#' + from).offset().top - $('#navBar').innerHeight();
    // minus fixed header height
    $('html, body').animate({scrollTop: scrollto}, 0);
      
    let pb = $('#' + from).parents().has('.pagebreak').first().find('.pagebreak a');
    wdbUser.displayImage(pb);
  },

  loadTargetImage: function () {
    let target = $(':target');
    if (target.length > 0) {
      if (target.attr('class') == 'pagebreak') {
        console.log("trying to load image: " + $(':target > a').attr('href'));
        wdbUser.displayImage($(':target > a'));
      } else {
        let pagebreak = target.parents().has('.pagebreak').first(),
            pb = (pagebreak.find('a').length > 1) ? pagebreak.find('.pb a') : pagebreak.find('a');
        wdbUser.displayImage(pb);
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
      
      mRefs.each(this.marginaliaPositioningCallback);
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

  /* load an element by ID and display it to the right */
  showInfoRight: function ( elementID ) {
    this.showDataRight($('#' + elementID).html());
  },
  
  showDataRight: function ( data ) {
    let insertID = wdb.getUniqueId(),
        insertContent = $('<div id="' + insertID + '" class="infoContainer right">' +
          data +
          '<button onclick="wdbDocument.clear(\'' + insertID + '\')" title="Diesen Eintrag schließen">[x]</button>' +
          '<button onclick="wdbDocument.clear();" title="Alle Informationen rechts schließen">[X]</button></div>');
      $('#ann').html(insertContent);
  },

  /* toggle facsimile div visibility */
  toggleFacsimile: function () {
    let link = $('#fac span a');
    if (link.text() == '[x]') {
      $('#facsimile').css('display', 'none');
      link.text('[« Digitalisat zeigen]');
    } else {
      $('#facsimile').css('display', 'block');
      link.text('[x]');
    }
  },

  // show content in an advanced mouseover 
  showInfoFloating: function ( pointerElement, elementID ) {
    let content = $('#' + elementID).html();
    this.showDataFloating ( pointerElement, content );
  },
  
  showDataFloating: function ( pointerElement, data ) {
    const maxWidth = 400,
          distance = 20;
    let insertID = wdb.getUniqueId(),
        insert = $('<div id="' + insertID + '" class="infoContainer floating"/>').append(data);
    $('#ann').html(insert);

    let $inserted = $('#' + insertID);
    $inserted.hover(
      function () {
        // mousein
        $(this).stop()
          .css("opacity", "1");
      },
      function () {
        // mouseout
        $(this).fadeOut(
          2000,
          function () {
            $(this).remove();
          }
        );
      }
    );

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
    $(id).fadeOut(
      2000,
      function () {
        $(id).remove();
      }
    );
  },

  // retrieve info by url
  showAnnotation: async function ( url, callback ) {
    $.ajax({
      url: url,
      method: 'get',
      success: function ( data ) {
        callback ( data );
      },
      dataType: 'html'
    });
  },

  // generic laoding function
  loadContent: function ( url, target, me ) {
    if ($('#' + target).css('display') == 'none') {
      $.ajax(url,
        {
          dataType: 'html',
          success: function (data) {
              $('#' + target).html($(data).children('ul'));
              $('#' + target).slideToggle();
              $(me).html($(me).html().replace('→', '↑'));
          },
          error: function (xhr, status, error) {
            console.error('Error loading ' + url + ':',
              status, error);
          }
        }
      );
    } else {
      $('#' + target).slideToggle();
      if (me.length > 0) {
        $(me).html($(me).html().replace('↑', '→'));
      }
    }
  },

  // close one info box or all
  clear: function ( id ) {
    if (id == '' || id == null) {
      $('#ann').html('');
      console.log('close all');
    } else {
      $('#' + id).remove();
      console.log('close ' + id);
    }
  },

  // when a fragment is given, highlight the fragment itself and all following up until and end marker
  highlightFragment: function () {
    let targ = window.location.hash.substring(1),
        startMarker = $(".anchorRef#" + targ),
        endMarker = $(".anchorRef#" + targ + "e");
    
    // only highlightAll if there is anything to highlight, i.e. start and end marker must be present
    if (startMarker.length == 0 || endMarker.length == 0) return;
    
    this.highlightAll (startMarker, endMarker);
  },

  // highlight a range of elements between a start and an end marker, using a given color and an alternative text
  highlightElements: function (startMarker, endMarker, color, alt) {
    // set defaults
    color = (color === "undefined") ? "#FFEF19" : color;
    
    if (startMarker.is(endMarker)) {
      // just one element selected
      startMarker.css("background-color", color);
      if (alt !== "undefined") {
        startMarker.attr('title', alt);
      }
    } else if (startMarker.parent().is(endMarker.parent())) {
      // both elements have the same parent
      // 1a: Wrap all of its (text node) siblings in a span: text-nodes cannot be accessed via jQuery »in the middle«
      startMarker.parent().contents().filter(function () {
        return this.nodeType === 3;
      }).wrap("<span></span>");
          
      // Colour and info for the start marker
      $(startMarker).css("background-color", color);
      if (alt !== "undefined") {
        startMarker.attr("title", alt);
      }
          
      // Colour and info for the siblings until the end marker
      let sib = $(startMarker).nextUntil(endMarker);
      sib.css("background-color", color);
      if (alt !== "undefined") {
        startMarker.attr("title", alt);
      }
          
      // Colour and info for the end marker
      $(endMarker).css("background-color", color);
      if (alt !== "undefined") {
        startMarker.attr("title", alt);
      }
      //DONE
    } else {
      // check further down the ancestry
      let cA = $(this.commonAncestor(startMarker, endMarker));
      // console.info("Found common ancestor: " + cA);
      
      // Step 1: highlight all »startMarker/following-sibling::node()«
      // 1a: Wrap all of its (text node) siblings in a span: text-nodes cannot be accessed via jQuery »in the middle«
      startMarker.parent().contents().filter(function () {
        return this.nodeType === 3;
      }).wrap("<span></span>");
      
      // 1b: Colour its later siblings if they dont have the end point marker
      let done = false;
      
      startMarker.nextAll().addBack().each(function () {
        if ($(this).has(endMarker).length > 0 || $(this).is(endMarker)) {
          return;
        } else {
          $(this).css("background-color", color);
          if (alt !== "undefined") {
            startMarker.attr("title", alt);
          }
        }
      });
      
      // Step 2: highlight »(startMarker/parent::*/parent::* intersect endMarker/parent::*/parent::*)//*)«
      // 2a: Get startMarker's parents up to the common ancestor
      let parentsList = startMarker.parentsUntil(cA);
      
      if (parentsList.has(endMarker).length === 0) {
        // go through each of these and access later siblings
        let has_returned = false;
        
        parentsList.each(function () {
          $(this).nextAll().each(function () {
            if (has_returned) {
              return;
            }
            
            // we need to handle the endMarker's parent differently
            if ($(this).has(endMarker).length > 0) {
              has_returned = true;
              return;
            } else {
              $(this).css("background-color", color);
              if (alt !== "undefined") {
                startMarker.attr("title", alt);
              }
            }
          });
        });
      }
      
      // Step 3: as step 1
      // 3a: Wrap alls of endMarker's siblings in a span
      endMarker.parent().contents().filter(function () {
        return this.nodeType === 3;
      }).wrap("<span></span>");
      
      //3b: Colour its earlier siblings if they dont have start marker
      $(endMarker.prevAll().addBack(). get ().reverse()).each(function () {
        if ($(this).has(startMarker).length > 0 || $(this).is(startMarker) || $(this).nextAll().has(startMarker).length > 0) {
          return;
        } else {
          $(this).css("background-color", color);
          if (alt !== "undefined") {
            startMarker.attr("title", alt);
          }
        }
      });
      
      // Step 4: colour all ancestors to the common ancestor
      // Get parents up until common ancestor
      let parentsListEnd = endMarker.parentsUntil(cA.children().has(endMarker));
      
      if (parentsListEnd.has(startMarker).length === 0) {
        // Go through each of these and access earlier siblings
        done = false;
      
        parentsListEnd.each(function () {
          $(this).prevAll().each(function () {
            if (done) {
              return;
            }
            
            if ($(this).has(startMarker).length > 0 || $(this).is(startMarker)) {
              done = true;
              return;
            } else {
              $(this).css("background-color", color);
              if (alt !== "undefined") {
                startMarker.attr("title", alt);
              }
            }
          });
        });
      }
    }
  },

  // group navigation related methods
  nav: {
    // load navigation if necessary and toggle visibility
    toggleNavigation: function() {
      if ($("nav").css("display") == "none") {
        $("#showNavLink").text("Navigation ausblenden");
      } else {
        $("#showNavLink").text("Navigation einblenden");
      }
      
      if ($("nav").text() === "") {
        $("nav").text("lädt...");
        let edition = wdb.meta.ed;
        
        $.ajax({
          url: wdb.restHeaders + "collection/" + edition + "/nav.html",
          success: function (data) {
            $("nav").html($(data)).prepend($("<h2>Navigation</h2>"));
          },
          data: "html"
        });
      }
      $("nav").slideToggle();
    },

    /* toggle TOC level visibility */
    switchnav: function ( id, anchorElement ) {	
      $(id).children('ul').children().toggle();
      
      if (anchorElement.length() > 0 && $(anchorElement).html() == '→') {
        $(anchorElement).html('↑');
      } else {
        $(anchorElement).html('→');
      }
    }
  },

  // make the left wider/smaller when resizing of div is not available
  changeMainWidth: function () {
    if ($('#wdbShowHide > a').html() == '»') {
      $('body').css('grid-template-columns', '2fr 1fr');
      $('#wdbShowHide > a').html('«').attr('title', "linke Seite schmaler");
    } else {
      $('body').css('grid-template-columns', '1fr 1fr');
      $('#wdbShowHide > a').html('»').attr("title", "linke Seite breiter");
    }
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
  },

  /* display an image in the right div */
  displayImage: function ( element ) {
    // default: load an html that contains an image into an iframe
    if (window.innerWidth > 768) {
      let href = element.attr('href');
      $('#fac').html('<iframe id="facsimile"></iframe><span><a href="javascript:close();">[x]</a></span>');
      $('#facsimile').attr('src', href).css('display', 'block');
    }
  }
  /*
   * example: load image into openseadragon
  displayImage: function ( element, viewer ) {
    if (window.innerWidth > 768 && viewer != null) {
      let pbs = $('body').find('.pagebreak a'),
          pos = pbs.index(element);
      viewer.goToPage(pos);
    }
  }*/
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
      wdbUser.displayImage($('.pagebreak a').first());
    }
  }

  /* when hovering over a footnote, display it in the right div */
  $('.fn_number').hover(wdbUser.footnoteMouseIn, wdbUser.footnoteMouseOut);
  
  // load image when clicking on a page number
  $('.pagebreak a').click(function (event) {
    event.preventDefault();
    wdbUser.displayImage($(this));
  });

  $('#login').submit( (event) => {
    wdb.login(event);
  });
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

/* preparations to show some loading animation while doing AJAX requests */
$(document).bind({
	ajaxStart: function() {
    $("body").addClass("loading");
  },
	ajaxStop: function() {
    $("body").removeClass("loading");
  }
});
/* END window event handlers */
