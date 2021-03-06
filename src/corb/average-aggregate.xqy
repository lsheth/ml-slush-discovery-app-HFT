xquery version "1.0-ml";
declare variable $URI as xs:string external;

let $doc := fn:doc($URI) 
let $day_Avg := cts:search(collection("Avg-Aggregate_data"),cts:element-value-query(xs:QName("Ticker"),$doc/*/Ticker))/*/Day_avg
let $day_above_avg := fn:round(1.30 * $day_Avg)
let $day_below_avg := fn:round(0.70 * $day_Avg)
let $lastmin_avg := cts:search(collection("Avg-Aggregate_data"),cts:element-value-query(xs:QName("Ticker"),$doc/*/Ticker))/*/Last_min_avg
let $lastmin_above_avg := fn:round(1.30 * $lastmin_avg)
let $lastmin_below_avg := fn:round(0.70 * $lastmin_avg)

let $Flag :=
    if ( $doc/*/Volume <= $day_below_avg )
      then "Below_Avg" 
       else if ( $doc/*/Volume >= $day_above_avg )
         then "Above_Avg" 
           else ()
let $doc :=
    typeswitch($doc)
      case document-node() return
        $doc/*
      default return
        $doc
let $enriched-doc := 
      element { fn:node-name($doc) }
      {
      $doc/namespace::*,
      $doc/@*,
      $doc/*,
      element Avg_Aggregate_data
         { 
           $day_Avg,
           element Flag {$Flag}
         }
      }
 return
  xdmp:document-insert(
    $URI,
    $enriched-doc,
    xdmp:document-get-permissions($URI),
    "Raw_data")