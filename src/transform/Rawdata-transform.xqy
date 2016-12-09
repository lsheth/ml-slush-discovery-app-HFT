xquery version "1.0-ml";
module namespace trns = "http://marklogic.com/transform/rawdata";
declare namespace functx = "http://www.functx.com";
 
declare function trns:transform(
  $content as map:map,
  $context as map:map
) as map:map*
{
  let $doc := map:get($content, 'value')
  let $w := $doc/*/Date
  
   let $_ := xdmp:log(("Input date: ",$w))
  let $wdt := xs:date(xdmp:parse-dateTime("[M]/[D]/[Y]", xs:string($w)))
  let $wd :=  xs:date(fn:format-date($wdt,
                 "[Y0001]-[M01]-[D01]","en","AD","US"))
  let $doc :=
    typeswitch($doc)
      case document-node() return
        $doc/*
      default return
        $doc
  let $_ := xdmp:log(("Cweek: ",$wd)) 
  let $doc-ns := fn:namespace-uri($doc)
  let $enriched-doc :=
    element { fn:node-name($doc) }
    {
      $doc/namespace::*,
      $doc/@*,
      $doc/*,
      element CanonicalDate {
    	   $wd }
	  }
  let $_ := map:put($content, 'value', document { $enriched-doc })
  return $content
};
