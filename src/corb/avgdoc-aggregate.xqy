xquery version "1.0-ml";
declare variable $URI as xs:string external;
let $doc := fn:doc($URI) 
let $aggrkey := $doc/*/Ticker
let $day_Avg := fn:avg((cts:search(collection("Raw_data"),cts:element-range-query(xs:QName("Minute"), "<" , xs:int("390"))))/Raw_data/xs:long(Volume))
let $last_min_Avg := fn:avg((cts:search(collection("Raw_data"),cts:element-range-query(xs:QName("Minute"), "=" , xs:int("390"))))/Raw_data/xs:long(Volume))
let $day_above_avg := 1.30 * $day_Avg
let $day_below_avg := 0.70 * $day_Avg
let $lastmin_above_avg := 1.30 * $last_min_Avg
let $lastmin_below_avg := 0.70 * $last_min_Avg
let $new-uri := fn:concat("/Avg-Aggregated/", $aggrkey) 
let $enriched-doc :=
      element Avg-Aggregate_data
       { 
         element Aggr_Key { $aggrkey },
         element Ticker {$doc/*/Ticker},
         element Day_avg {$day_Avg},
         element Last_min_avg {$last_min_Avg},
         element Day_above_avg {$day_above_avg},
         element Day_below_avg {$day_below_avg},
         element Last_min_below_avg {$lastmin_below_avg},
         element Last_min_above_avg {$lastmin_above_avg}
       }
return
  xdmp:document-insert(
    $new-uri,
    $enriched-doc,
    xdmp:document-get-permissions($new-uri),
    "Avg-Aggregate_data")