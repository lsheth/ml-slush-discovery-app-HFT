xquery version "1.0-ml";
declare variable $URI as xs:string external;
let $doc := fn:doc($URI) 
let $aggrkey := $doc/*/Aggr_Key
let $dates := cts:search(
    collection('Raw_data'),
    cts:element-value-query(xs:QName("Aggr_Key"),$aggrkey))
let $new-uri := fn:concat("/Aggregated/", $aggrkey) 
let $_ := xdmp:log(("Aggr-Key: ",$aggrkey))
let $enriched-doc :=
      element Aggregate_data
       { 
         $aggrkey,
         $doc/*/Ticker,
         $doc/*/Minute,
         element Dates
          {for $date in $dates order by $date/*/CanonicalDate descending
          return ($date/*/CanonicalDate,$date/*/Volume)}
       }
return
  xdmp:document-insert(
    $new-uri,
    $enriched-doc,
    xdmp:document-get-permissions($new-uri),
    "Aggregate_data")