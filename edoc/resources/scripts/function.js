/* W.DB+ common functions
 * author: Dario Kampkaspar, dario.kampkaspar@oeaw.ac.at
 * https://github.com/dariok/wdbplus
 */
/* jshint browser: true */
"use strict";

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
  let login = function (event, reload) {
    event.preventDefault();
  
    let username = $('#user').val(),
        password = $('#password').val();
    wdb.report("info", "login request");
    Cookies.remove('wdbplus');
    
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
          Cookies.set('wdbplus', btoa(username + ':' + password));
          $('#auth').replaceWith(data);
          setAuthorizationHeader();
          $('#logout').on('click', () => {
            wdb.logout();
          });
          wdb.report("info", "logged in");
          if ( reload ) {
             location.reload();
          }
        } catch (e) {
          wdb.report("error", "error logging in", e);
        }
      },
      dataType: 'text'
    });
  };

  let logout = function () {
    wdb.report("info", "logout request");
    
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
          $('#login').on('submit', (event) => {
            event.preventDefault();
            wdb.login(event);
          });
          setAuthorizationHeader();
          wdb.report("info", "logging off");
        } catch (e) {
          wdb.report("error", "error logging out", e);
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
    if ( typeof cred == "undefined" || cred.length == 0 ) {
      delete restHeaderVal.Authorization;
    } else {
      restHeaderVal.Authorization = "Basic " + cred;
    } 
  };
  setAuthorizationHeader();

  return {
    meta:           meta,
    parameters:     params,
    restHeaders:    restHeaderVal,
    setRestHeaders: setAuthorizationHeader,
    getUniqueId:    getUniqueId,
    login:          login,
    logout:         logout,

    /* usually used internally to signal errors */
    report: function ( reportType, shortInfo, longInfo, targetElement, ...args ) {
      let symbol,
          report = [shortInfo + "\n" + longInfo, ...args];

      if ( reportType == "error" ) {
        console.error(...report);
        symbol = "✕";
      } else if ( reportType == "warn" ) {
        symbol = "❗";
        console.warn(...report);
      } else if ( reportType == "info" ) {
        symbol = "ℹ";
        console.info(...report);
      } else if ( reportType == "success" ) {
        symbol = "✓";
        console.info(...report);
      } else {
        console.log(...report);
      }

      if ( targetElement ) {
        $(targetElement).append('<span class="' + reportType + '" title="' + longInfo + '">' + symbol + '</span>');
      }
    },

    /* taken from https://github.com/30-seconds/30-seconds-of-code/blob/master/snippets/URLJoin.md */
    URLJoin: ( ...args ) =>
      args
        .join('/')
        .replace(/[\/]+/g, '/')
        .replace(/^(.+):\//, '$1://')
        .replace(/^file:/, 'file:/')
        .replace(/\/(\?|&|#[^!])/g, '$1')
        .replace(/\?/g, '&')
        .replace('&', '?')
  };
})();
Object.freeze(wdb);

/* functions for manipulating the HTML document */
const wdbDocument = {
  // get the common ancestor of 2 elements
  commonAncestor: function ( element1, element2 ) {
    let parent1 = element1.parents().add(element1).get()
      , parent2 = element2.parents().add(element2).get();
    
    for ( let i = 0; i < parent1.length; i++ ) {
      if ( parent1[i] != parent2[i] ) return parent1[i - 1];
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
      
    let pb = $('#' + from).parents().has('.pagebreak').first().find('.pagebreak')[0];
    wdbUser.displayImage(pb);
  },

  /**
   * load the image for the page containing a target element or the first page if no target is given
   * @returns {void} - executes wdbUser.displayImage()
   */
  loadTargetImage: function () {
    if ( window.location.hash.length > 1 ) {
      /* JS does not know about the concept of preceding::pb, so we have to use some other means to find the immediately
         preceding pagebreak – 2022-08-01 DK */
      let all = $('*')
        , targetElement = $(window.location.hash)
        , indexOfTarget = all.index(targetElement);
      
    let prevAll = all.filter(function(index){ return index < indexOfTarget && $(this).hasClass('pagebreak') });
    
    wdbUser.displayImage(prevAll.last()[0]);
    } else {
      wdbUser.displayImage($('.pagebreak')[0]);
    }
  },

  /* postioning of marginalia */
  positionMarginalia: function () {
    let mRefs = $("a.marginaliaAnchor"),
        marginalia = $('#marginaliaContainer *');

    // Show margin container only if any are to be shown
    if (mRefs.length > 0 || marginalia.length > 0) {
      /* Save fragment identifier for later
       * – avoid jumping while reflowing marginalia */
      let tar = window.location.hash;
      if (tar !== '' && tar !== 'undefined') {
        window.location.hash = '#';
      }
      
      mRefs.each(this.marginaliaPositioningCallback);
      // need to set width by JS as CSS :has() is still not there…
      $('#content').css('width', 'calc(75% - 2em)');
      $('#marginaliaContainer').children('span').css('visibility', 'visible');
      
      if (tar !== '' && tar !== 'undefined') {
        window.location.hash = tar;
      }
    }
  },

  /* actual positioning */
  marginaliaPositioningCallback: function (index, element) {
    let referenceElementID = $(element).attr('id'),
        referenceElementTop = $(element).position().top,
        marginNote = $("#margin-" + referenceElementID),
        previousMarginNote = marginNote.prev(),
        targetTop;
    
    if (previousMarginNote.length == 0) {
      targetTop = referenceElementTop;
    } else {
      let previousNoteHeight = $(previousMarginNote).height(),
          previousNoteTop = $(previousMarginNote).position().top,
          minimumTargetTop = previousNoteHeight + previousNoteTop;
  
      if ( Math.floor(referenceElementTop) < minimumTargetTop ) {
        targetTop = previousNoteTop + previousNoteHeight;
      } else {
        targetTop = referenceElementTop;
      }
    }
    
    wdb.report("info", "position for " + referenceElementID + ': ' + targetTop);
    // offset is relative to the document, so the header has to be substracted if top is set via
    // CSS - which is necessary because setting the offset will change position and left
    marginNote.css('top', targetTop + "px");
  },

  /* load an element by ID and display it to the right */
  showInfoRight: function ( elementID ) {
    this.showDataRight($('#' + elementID));
  },
  
  /* show data passed in #ann; assumes that data are wrapped in .content */
  showDataRight: function ( data, replace ) {
    let insertID = wdb.getUniqueId(),
        insertContent = '<div id="' + insertID + '" class="infoContainer right">'
          + $(data).find('.content').html()
          + '<div class="controls">'
          + '<button onclick="wdbDocument.clear(\'' + insertID + '\')" title="Diesen Eintrag schließen">[x]</button>'
          + '<button onclick="wdbDocument.clear();" title="Alle Informationen rechts schließen">[X]</button>'
          + '</div></div>';
    
    if ( replace === true ) {
      $('#ann').html(insertContent);
    } else {
      $('#ann').append(insertContent);
    }
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
        insert = $('<div id="' + insertID + '" class="infoContainer floating"/>')
          .append(data)
          .css('display', 'inline');
    $('#ann').html(insert[0]);
    pointerElement.dataset.float = insertID;

    let inserted = $('#' + insertID);
    inserted.on('mouseenter', ( ) => {
        // mousein
        $(inserted).stop()
          .css("opacity", "1");
      }).on('mouseleave', ( ) => {
        // mouseout
        $(inserted).fadeOut(
          2000,
          function () {
            $(inserted).remove();
          }
        );
      }
    );

    // position the info box close to the pointing element
    let insertedWidth = inserted.innerWidth() ?? 0,
        mainWidth = $('main').innerWidth() ?? 0,
        pointer = $(pointerElement),
        pointerOffsetLeft = pointer.offset().left ?? 0,
        targetLeft,
        targetTop,
        targetWidth = Math.min(maxWidth, insertedWidth);
    
    // set the left coordinate for the info box. The right end must not leave the visible ares
    if ( (targetWidth + pointerOffsetLeft + distance) > mainWidth ) {
      targetLeft = mainWidth - targetWidth - distance;
      targetTop = pointer.offset().top + distance;
    } else {
      targetLeft = pointer.offset().left + distance;
      targetTop = pointer.offset().top + distance;
    }
    inserted.offset({ left: targetLeft, top: targetTop})
      .css('max-width' , maxWidth)
      .outerWidth(targetWidth);
  },
  
  mouseOut: function (pointerElement) {
    let id = '#' + pointerElement.dataset.float;
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
      $.ajax(
        {
          url: url,
          headers: wdb.restHeaders,
          dataType: 'html',
          success: function (data) {
              $('#' + target).html($(data).children('ul'));
              $('#' + target).slideToggle();
              $(me).html($(me).html().replace('→', '↑'));
          },
          error: function (xhr, status, error) {
            wdb.report("error", "Error loading " + url + " : " + status, error);
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
      wdb.report("info", "close all");
    } else {
      $('#' + id).remove();
      wdb.report("info", "close " + id);
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
          url: wdb.URLJoin(wdb.meta.rest, "collection/", edition, "/nav.html"),
          success: function (data) {
            $("nav").replaceWith($(data));
          },
          data: "html"
        });
      }
      $("nav").slideToggle();
    },

    /* toggle TOC level visibility */
    switchnav: function ( id, anchorElement ) {	
      $('#' + id).toggle();
      
      if (anchorElement !== undefined && anchorElement.length() > 0 && $(anchorElement).html() == '→') {
        $(anchorElement).html('↑');
      } else {
        $(anchorElement).html('→');
      }
    },

    /* load navigation of an imported project */
    loadNavigation: function ( event ) {
      let ed = event.currentTarget.dataset.ed;
      $.ajax({
        method: "get",
        url: wdb.meta.rest + "collection/" + ed + "/nav.html",
        success:  ( data ) => {
          let replacement = $(data).find('#' + ed).prev().addBack();
          if ( replacement.length > 0 ) {
            $(event.currentTarget).replaceWith(replacement);
          }
        },
        error: ( xhr, status, error ) => {
          wdb.report("error", "error loading navigation", status + ": " + error);
        }
      });
    }
  },
  
  /**
   * display an image in the right div – does not use an viewer but inserts an iframe
   * @param {string} url - the URL from which to load the image
   * @returns {void}
   */
  displayImageRight: function ( url ) {
    if (window.innerWidth > 768) {
      $('#fac').html('<iframe id="facsimile"></iframe><span><a href="javascript:close();">[x]</a></span>');
      $('#facsimile').attr('src', url).css('display', 'block');
    }
  },
  
  // load image into openseadragon – assumes there is only one level of images
  displayImageViewer: function ( url, viewer ) {
    if (window.innerWidth > 768 && viewer != null) {
      let pbs = $('body').find('.pagebreak'),
          pos = pbs.index(url);
      viewer.goToPage(pos);
    }
  },

  // make the left wider/smaller when resizing of div is not available
  changeMainWidth: function () {
    if ($('#wdbShowHide > button').html() == '»') {
      $('body').css('grid-template-columns', '2fr 1fr');
      $('#wdbShowHide > button').html('«').attr('title', "linke Seite schmaler");
    } else {
      $('body').css('grid-template-columns', '1fr 1fr');
      $('#wdbShowHide > button').html('»').attr("title", "linke Seite breiter");
    }
  }
};
Object.freeze(wdbDocument);

/***
 * wdbUser: functions here can be overridden by projects; in most cases, examples
 * are given for different variants.
 */
const wdbUser = {
  // load entity data
  showEntityData: function ( event ) {
    let entityID = event.target.dataset.ref,
        url = "entity.html?id=" + entityID;
    
    $.ajax({
      method:  "get",
      url:     url,
      success: function ( data ) {
        wdbDocument.showDataRight(data);
      },
      error: function (xhr, status, error) {
        wdb.logError(xhr, status, error, "Error loading entity data from " + url);
      }
    });
  },

   // what to do when the mouse enters a footnote pointer
   footnoteMouseIn: function ( event ) {
    event.preventDefault();
    
    let peer = event.target.dataset.note;
    
    // example: show info text in a float
    //wdbDocument.showInfoFloating(event.target, peer);
    
    // example: show info on the right
    wdbDocument.showInfoRight(peer);
  },

  // what to do when the mouse leaves the footnote pointer
  footnoteMouseOut: function ( event ) {
      event.preventDefault();

      // example: remove the float
      //wdbDocument.mouseOut(event.target);
  },

  /**
   * What to do to display an image
   * Default behaviour: wdbDocument.displayImageRight(url); the URL to use is taken from the element passed: either
   * html:a/@href or html:button/@data-image.
   * May be overwritten by instance or project specifics
   * @param {HTMLElement} element - The element to evaluate
   * @return {void} - (void)
   */
  displayImage: function ( element ) {
    // default: show image in an iframe
    let url;
    if ( element.attributes.hasOwnProperty('href') ) {
      url = element.getAttribute('href');
    } else if ( element.dataset.hasOwnProperty('image') ) {
      url = element.dataset['image'];
    }
    wdbDocument.displayImageRight(url);
    
    // example: show image in viewer
    // wdbDocument.displayImageViewer(url, viewer);

    // example: load image into openseadragon
    /*
      let pbs = $('body').find('.pagebreak a'),
          pos = pbs.index(element);
      viewer.goToPage(pos);
    */
  },

  /* a timer for marginalia positioning; needs to be reset upon resize */
  marginaliaTimer: {},
};

/***
 * Functions to be executed after the DOM is ready (formerly $(document).ready())
 * includes highlighting and image loading functions
 ***/
$( () => {
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
  if ( $('.pagebreak').length > 0 ) {
    wdbDocument.loadTargetImage();
  }

  // load image when clicking on a page number
  $('body').on('click', '.pagebreak', ( event ) => {
    event.preventDefault();
    wdbUser.displayImage(event.target);
  });

  $('#login').on('submit', (event) => {
    event.preventDefault();
    wdb.login(event);
  });
  $('#logout').on('click', () => {
    wdb.logout();
  });

  // load navigation
  $('#showNavLink').on('click', () => {
    wdbDocument.nav.toggleNavigation();
  });

  // toggle navigation level visibility
  $('body').on('click', '.wdbNav.level', ( event ) => {
    wdbDocument.nav.switchnav(event.currentTarget.dataset.lvl);
  });

  // load a navigation level 
  $('body').on('click', '.wdbNav.load', ( event ) => {
    wdbDocument.nav.loadNavigation(event);
  });

  // toggle width button solely for iOS Safari
  $('#wdbShowHide').on('click', () =>{
    wdbDocument.changeMainWidth();
  });

  // register hover handler for footnote link buttons
  $('.footnoteNumber').hover(wdbUser.footnoteMouseIn, wdbUser.footnoteMouseOut);
  
  // register click handler for entity information
  $('.entity').click(wdbUser.showEntityData);
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
  clearTimeout(wdbUser.marginaliaTimer);
  wdbUser.marginaliaTimer = setTimeout( () => { wdbDocument.positionMarginalia(); }, 500);
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
