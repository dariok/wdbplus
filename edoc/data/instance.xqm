xquery version "3.1";

module namespace wdbPF	= "https://github.com/dariok/wdbplus/projectFiles";

declare namespace tei	= "http://www.tei-c.org/ns/1.0";

declare function wdbPF:getInstanceName () as xs:string {
  doc('wdbmeta.xml')//*:title[1]
};