/* W.DB+ common functions
 * author: Dario Kampkaspar, dario.kampkaspar@oeaw.ac.at
 * https://github.com/dariok/wdbplus
 */
/* jshint browser: true */
/* globals Cookies */
"use strict";

const wdb = (function() {
  // all meta elements
  let meta = new Map();
  for ( let m of document.getElementsByTagName("meta") ) {
    if ( m.name == 'rest' ) { 
      let contents = m.content.split('; ')
        , values = new Map();
      for ( let c of contents ) {
        let url = c.split(': ');
        values.set(url[0], url[1]);
      }
      meta.set("rest", values);
    }
    else meta.set(m.name, m.content);
  }
  
  // unique IDs
  let internalUniqueId = 0;               // basis for globally unique IDs
  let getUniqueId = function () {
    return 'wdb' + ('000' + internalUniqueId++).substring(-4);
  };

  /* Login and logout */
  /**
   * Perform the actual login. Reload the page if parameter is true
   * @param { Boolean } reload 
   * @param { String } base
   */
  let login = function ( reload, base='' ) {
    let user = $('#user').val()
      , pass = $('#password').val()
      , username = user === undefined ? '' : String(user)
      , password = pass === undefined ? '' : String(pass);

    let formdata = new FormData();
    formdata.append("user", username);
    formdata.append("password", password);

    let url = base === '' ? wdb.restUrl : base;
    
    $.ajax({
      url: new URL('login', url).toString(),
      method: 'post',
      data: formdata,
      success: ( data ) => {
        try {
          $('#auth').append("<div id='userdata'></div>");
          $('#userdata').append(data.user);
          $('#login').hide();
          if ( reload ) {
            location.reload();
          }
          wdb.report("info", "logged in as " + username);
        } catch ( e ) {
          wdb.handleError("logging in", e);
        }
      }
    });
  };

  /**
   * Perform the logout call
   * @param { String } base 
   */
  let logout = function ( base='' ) {
    wdb.report("info", "logout request");
    let url = base === '' ? wdb.restUrl : base;
    
    $.ajax({
      url: new URL('logout', url).toString(),
      method: 'get',
      success: function (data) {
        try {
          $('#userdata').remove();
          $('#login').show();
          wdb.report("info", "logging off");
        } catch ( e ) {
          wdb.handleError("logging off", e);
        }
      }
    });
  };
  /* END login and logout */

  /* globals Cookies */
  /* TODO when modules are available, import js.cookie.mjs via CDN; current support 90.5% */

  return {
    meta:           meta,
    parameters:     new URLSearchParams(window.location.search),
    restUrl:        new URL("api/v2/", meta.get('rest').get('2')).toString(),
    getUniqueId:    getUniqueId,
    login:          login,
    logout:         logout,

    /**
     * Handle general errors, taking care of type checking the error
     * @param { String } text 
     * @param { unknown } e 
     */
    handleError: function ( text, e ) {
      if ( e instanceof Error ) {
        wdb.report("error", "error when " + text, e.toString());
      } else {
        wdb.report("error", "an unknown type of error occurred when " + text);
      }
      return true;
    },

    /**
     * Standard reporting to console
     * @param { String } reportType 
     * @param { String } shortInfo 
     * @param { String } longInfo 
     * @param { Element } targetElement 
     * @param { ...String } args 
     */
    report: function ( reportType, shortInfo, longInfo = '', targetElement = document.createElement('div'), ...args ) {
      let symbol,
          report = [shortInfo + "\n" + longInfo, ...args];

      if ( reportType == "error" ) {
        console.trace();
        console.error(...report);
        symbol = "✕";
      } else if ( reportType == "warn" ) {
        console.trace();
        symbol = "❗";
        console.warn(...report);
      } else if ( reportType == "info" ) {
        symbol = "ℹ";
        console.info(...report);
      } else if ( reportType == "success" ) {
        symbol = "✓";
        console.info(...report);
      } else {
        console.trace();
        console.log(...report);
      }

      if ( targetElement ) {
        $(targetElement).append('<span class="' + reportType + '" title="' + longInfo + '">' + symbol + '</span>');
      }

      return true;
    }
  };
})();
Object.freeze(wdb);

let annotationsCount = 0;
function addAnnotation ( targetElement, content ) {
  // create element for annotations
  if ( $(targetElement).children(".annotations").length === 0 ) {
    /*$(targetElement).append('<ul class="annotations" role="complementary"><dt>Annotationen an dieser Stelle:</dt></ul>');*/
    $('<ul class="annotations" role="complementary" id="ann' + annotationsCount + '" '
        + 'onmouseover="annotationMouseIn(event)" onmouseout="annotationMouseOut(event)" '
        + 'onmousemove="annotationMouseIn(event)"><dt>Annotationen an dieser Stelle:</dt></ul>').insertAfter(targetElement);
    $(targetElement).attr("aria-describedby", "ann" + annotationsCount);
  }
  $("#ann" + annotationsCount).append(content);
  annotationsCount++;
}

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
    
    if ( document.getElementById(from) === null ) return;

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
      /* TODO: since support is > 94%, use document.evaluate with an XPath to do this
         JS does not know about the concept of preceding::pb, so we have to use some other means to find the immediately
         preceding pagebreak – 2022-08-01 DK */
      let all = $('*')
        , targetElement = $(window.location.hash)
        , indexOfTarget = all.index(targetElement);
      
      let prevAll = all.filter(function(index){ return index < indexOfTarget && $(this).hasClass('pagebreak'); });
      
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
  marginaliaPositioningCallback: function ( index, element ) {
    let referenceElementID = $(element).attr('id')
      , marginNote = $("#margin-" + referenceElementID)
      , previousMarginNote = marginNote.prev();
      
    try {
      let referenceElementTop = $(element).position().top
        , targetTop;
      
      if ( previousMarginNote.length == 0 ) {
        targetTop = referenceElementTop;
      } else {
        let previousNoteHeight = $(previousMarginNote).height() ?? 0
          , previousNoteTop = $(previousMarginNote).position().top
          , minimumTargetTop = previousNoteHeight + previousNoteTop;
        
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
    } catch ( e ) {
      wdb.report("error", "Error positioning margin note #" + index + " for " + referenceElementID, e);
    }
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
          + '<button data-clear="' + insertID + '" title="Diesen Eintrag schließen">[x]</button>'
          + '<button title="Alle Informationen rechts schließen">[X]</button>'
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

  /*
  function wdbTooltipMouseIn ( event ) {
  let tPos, lPos, fWidth,
      maxWidth = 500,
      annotationElement,
      target = event.target;
  
  if (target.classList.contains("annotations")) {
    annotationElement = $(target);
  } else if ($(target).children(".annotations").length > 0) {
    annotationElement = target.children(".annotations");
  } else {
    let annotationID;
    if (target.hasAttribute("aria-describedby")) {
      annotationID = target.attributes["aria-describedby"].value;
    } else if (target.parentNode.hasAttribute("aria-describedby")) {
      annotationID = target.parentNode.attributes["aria-describedby"].value;
    }
    annotationElement = $('#' + annotationID);
  }
  
  $(annotationElement).clearQueue();
  
  if (annotationElement.innerWidth() > maxWidth)
    fWidth = maxWidth;
  else fWidth = annotationElement.innerWidth();
  
  if ((fWidth + $(target).offset().left + 20) > window.innerWidth) {								// position the info window
    lPos = window.innerWidth - fWidth - 20 - (window.innerWidth - $(window).width());
    tPos = $(target).position().top + 5;
    annotationElement.offset({ left: lPos, top: tPos});
    annotationElement.css('top', tPos);
  } else {
    lPos = $(target).position().left;
    tPos = $(target).position().top + 5;
    annotationElement.css('left', lPos).css('top', tPos);
  }
  
  annotationElement.css('max-width' , maxWidth);
  annotationElement.css('white-space', 'normal');								   // allow word wrapping to fit into max width
  annotationElement.outerWidth(fWidth);
  annotationElement.show();
}
function wdbTooltipMouseOut ( event ) {
let annotationElement,
target = event.target;

if (target.classList.contains("annotations")) {
annotationElement = $(target);
} else if ($(target).children(".annotations").length > 0) {
annotationElement = $(target).children(".annotations");
} else {
let annotationID;
if (target.hasAttribute("aria-describedby")) {
annotationID = target.attributes["aria-describedby"].value;
} else if (target.parentNode.hasAttribute("aria-describedby")) {
annotationID = target.parentNode.attributes["aria-describedby"].value;
}
annotationElement = $('#' + annotationID);
}

$(annotationElement).delay(1000).fadeOut(500);
}
function annotationMouseIn ( event ) {
let target = event.target;
$(target).closest(".annotations").stop(true);
}
function annotationMouseOut ( event ) {
let target = event.target;
$(target).closest(".annotations").stop(true);
$(target).closest(".annotations").delay(1000).fadeOut(500);
}
  */

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
    $('main').append(insert[0]);
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
        targetWidth = Math.min(maxWidth, insertedWidth + 2); // insertedWidth + 2px for border
    
    // set the left coordinate for the info box. The right end must not leave the visible area
    if ( (targetWidth + pointerOffsetLeft + distance) > mainWidth ) {
      targetLeft = mainWidth - targetWidth - distance;
    } else {
      targetLeft = pointer.offset().left + distance;
    }
    
    /* set the top coordiante for the info box. Its lower end must not cover the footer or leave the visible area
       first, we need to set the width of the box so we get its resulting height */
    inserted.css('max-width' , maxWidth);
    /* next, get its height and the height of the footer and the inner height of the browser window;
     * use the top of the pointer element as start for vertical placement of the box; as there is no reliable way to get
     * the text’s baseline or the superscript-baseline, we use 1.5 * the pointer’s height
     * 2022-09-22 DK */
    let visibleHeight = window.innerHeight
      , footerHeight = $('body > footer').outerHeight()
      , ownHeight = inserted.height()
      , pointerRelTop = 1.5 * pointer.height() + pointer.offset().top;
    
    inserted.offset({
        left: targetLeft,
        top: 1.5 * pointer.height() + pointer.offset().top
      })
      .css('display', 'flex');
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
  
  showInfoTab: function ( data ) {
    $('#ann').prepend($('.content', data));
    $('#wdbRight').tabs('option', 'active', 1);
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
  /**
   * @param url { string }
   * @param target { string }
   * @param me { Element }
   */
  loadContent: function ( url, target, me = document.createElement('div'), selector = "") {
    if ( !me.isConnected ) { // nothing to toggle, so replace contents
      $.ajax({
        url: url,
        method: 'get',
        dataType: 'html',
        success: function ( data ) {
          let newContent = selector !== '' ? $(data).children(selector) : data;
          $('#' + target).html(newContent);
        },
        error: function ( xhr, status, error ) {
          wdb.report("error", "Error loading " + url + " : " + status, error);
        }
      });
    } else if ( $('#' + target).children().length == 0 ) { // no children: load and show
      $.ajax({
        url: url,
        method: 'get',
        dataType: 'html',
        success: function ( data ) {
          let newContent = selector !== '' ? $(data).children(selector) : data;
          $('#' + target).html(newContent);
          $('#' + target).slideDown();
          $(me).html('⮭').attr('title', 'Hide results');
        },
        error: function ( xhr, status, error ) {
          wdb.report("error", "Error loading " + url + " : " + status, error);
        }
      });
    } else { // children already present: toggle visibility
      $('#' + target).slideToggle();
      $(me).html($(me).visible ? '⮭' : '⮯').attr('title', $(me).visible ? 'Hide results' : 'Show results');
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

   /* TODO use the Range API to make this easier and more comprehensible */
  // highlight a range of elements between a start and an end marker, using a given color and an alternative text
  highlightElements: function (startMarker, endMarker, color, alt) {
    if ( startMarker === undefined || endMarker === undefined ) return;
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

   // highlight a word (or words) from a search result
  highlightSearch: function ( term, color ) {
    let lTerm = term.toLocaleLowerCase()
      , texts = $("section *")
        .filter( function ( index ) {
            let lCaseText = this.textContent.toLocaleLowerCase().replaceAll('-', '');
            return this.nodeName.toLocaleLowerCase() !== "span" && lCaseText.indexOf(lTerm) > -1
          });
         
      texts.each( ( index, element ) => {
        $(element.childNodes).each ( ( childIndex, childNode ) => {
          let termIndex = childNode.textContent.toLocaleLowerCase().replaceAll('-', '').indexOf(lTerm);
          if ( childNode.nodeType === Node.TEXT_NODE && termIndex > -1 ) {
            let nodeTerm = childNode.textContent.substr(termIndex, lTerm.length)
              , newText = childNode.textContent
                  .replace(nodeTerm, '<span style="background-color: ' + color + ';">' + nodeTerm + '</span>');
            
            $(childNode).replaceWith(newText);
          } else if ( childNode.nodeType === Node.ELEMENT_NODE && childNode.localName == 'span' && termIndex > -1 ) {
            $(childNode).attr('style', $(childNode).attr('style') + '; background-color: ' + color + ';');
          }
        })
      });
      
      $(window.location.hash)[0].scrollIntoView();
  },
/* END highlighting */

/** Navigation **/
// group navigation related methods
  nav: {
    // load navigation if necessary and toggle visibility
    toggleNavigation: function( ) {
      if ( $("header nav").css("display") === "none" ) {
        $("#showNavLink").text("Navigation ausblenden");
      } else {
        $("#showNavLink").text("Navigation einblenden");
      }
      
      if ( $("header nav").text() === "" ) {
        $("header nav").text("lädt...");
        let edition = wdb.meta.get('ed;')
        
        $.ajax({
          url: new URL("projects/" + wdb.meta.get('ed') + "/views/navigation", wdb.restUrl).toString(),
          success: function (data) {
            $("header nav").replaceWith($(data));
          },
          data: "html"
        });
      }
      $("header nav").slideToggle();
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
        url: wdb.restUrl + "projects/" + ed + "/views/navigation",
        dataType: "html",
        success:  ( data ) => {
          let replacement = $(data).find('#' + ed);//.prev().addBack();
          if ( replacement.length > 0 ) {
            $(event.currentTarget).after(replacement);
            $(event.currentTarget).removeClass('load').addClass('level');
          }
        },
        error: ( xhr, status, error ) => {
          wdb.report("error", "error loading navigation", status + ": " + error);
        }
      });
    }
  },
  
  /**
   * display an image in the right div – does not use any viewer but inserts an iframe
   * @param { String } url - the URL from which to load the image
   * @returns { void }
   */
  displayImageRight: function ( url ) {
    if ( window.innerWidth > 768 ) {
      $('#fac').html('<iframe id="facsimile"></iframe><span><button>[x]</button></span>');
      $('#facsimile').attr('src', url).css('display', 'block');
      $('document').on('click', 'iframe button', ( event ) => {
        $('#fac').empty();
      });
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
  if ( wdb.parameters.has('l') ) {
    wdbDocument.highlightRange(wdb.parameters.get('l'));
  }

  // highlight several elements given by a comma separated list in the »i« query parametter
  if ( wdb.parameters.has('i') ) {
    const ids = wdb.parameters.get('i');
    if ( ids !== null && ids !== '' ) {
      for ( let id of ids.split(',') ) {
        if ( id === '' ) continue;
        $('#' + id).css('background-color', 'lightblue');
      }
    }
  }

  // if a search word is present, highlight it
  if ( wdb.meta.get('wdbTemplate') !== 'templates/function.html' && wdb.parameters.has('q') ) {
    wdbDocument.highlightSearch(wdb.parameters.get('q'), 'yellow');
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
  $('body').on('mouseenter', '.footnoteNumber', wdbUser.footnoteMouseIn)
           .on('mouseleave', '.footnoteNumber', wdbUser.footnoteMouseOut);
  
  // handler to close one or all footnotes
  $('body').on('click', '.controls button', ( event ) => {
    if ( event.target.dataset.clear !== undefined ) {
      wdbDocument.clear(event.target.dataset.clear);
    } else {
      wdbDocument.clear();
    }
  });
  
  // register click handler for entity information
  $('body').on('click', '.entity', wdbUser.showEntityData);

  // register listeners for login and logout
  $(document).on('submit', '#login', ( event ) => {
    event.preventDefault();
    wdb.login(false);
  });
  $(document).on('click', '#logout', () => {
    wdb.logout();
  });
  $('#auth button').on('click', ( ) => { $('#login').toggle(); });
});
/* END DOM ready functions */

/***
 *  event handlers on window properties
 ***/
// load image when jumping to target
$(window).on('hashchange', function () {
  wdbDocument.loadTargetImage();
});

/* set/reset timer for marginalia positioning and invoke actual function */
$(window).on('load resize', function () {
  clearTimeout(wdbUser.marginaliaTimer);
  wdbUser.marginaliaTimer = setTimeout( () => { wdbDocument.positionMarginalia(); }, 500);
});

/* preparations to show some loading animation while doing AJAX requests */
$(document).on({
	ajaxStart: function() {
    $("body").addClass("loading");
  },
	ajaxStop: function() {
    $("body").removeClass("loading");
  }
});
/* END window event handlers */
