/* jshint browser: true */
"use strict";

function cookieConsent() {
  Cookies.set("wdbplus_consent", "dismissed");
  $('#cookieConsent').hide();
}

$(function(){
  let consent = Cookies.get("wdbplus_consent");

  if (consent !== "dismissed") {
    $('main').prepend('<div id="cookieConsent"\
        style="background-color: black; color: white; padding: 15px;\
        display: flex;"><span>This website uses cookies to enable you to sign up\
      to our services and improve your experience. We do not knowingly share any\
      information with third parties. <a href="imprint.html">Learn more</a></span>\
      <br /><button id="cookieConsentOK"\
        style="background-color: yellow; padding: 10px; border-radius: 7.5px; \
        height: 1.5rem; flex: 1 0 auto;">Got it!</button></div>');
    }

  $(document).on('click', '#cookieConsentOK', () => { cookieConsent() });
});