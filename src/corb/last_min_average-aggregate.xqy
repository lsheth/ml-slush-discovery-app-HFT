xquery version "1.0-ml";
declare variable $URI as xs:string external;

let $doc := fn:doc($URI) 

let $last_min_Avg := fn:avg((cts:search(collection("Raw_data"),cts:element-range-query(xs:QName("Minute"), "=" , xs:int("390"))))/Raw_data/xs:long(Volume))
let $last_m_above_avg := 1.30 * $last_min_Avg
let $last_m_below_avg := 0.70 * $last_min_Avg

let $day_Avg := fn:avg((cts:search(collection("Raw_data"),cts:element-range-query(xs:QName("Minute"), "<" , xs:int("390"))))/Raw_data/xs:long(Volume))
let $day_above_avg := 1.30 * $day_Avg
let $day_below_avg := 0.70 * $day_Avg
let $Flag := ""
If /$doc/*/Volume <= $day_below_avg
  then $Flag := "Below_Avg"
If /$doc/*/Volume >= $day_above_avg
  then $Flag := "Above_Avg"

let $enriched-doc := 
     element { fn:node-name($doc) }
    {
      $doc/namespace::*,
      $doc/@*,
      $doc/*,
      element Avg_Aggregate_data
       { 
         element Daily_Avg { $day_Avg },
         element Flag  { $Flag }
       }
    }
return
  xdmp:document-insert(
    $URI,
    $enriched-doc,
    xdmp:document-get-permissions($URI),
    "Raw_data")