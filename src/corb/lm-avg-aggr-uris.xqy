xquery version "1.0-ml";

let $uris :=  cts:uris("/Raw_data/", 'document',cts:element-range-query(xs:QName("Minute"), "=" , xs:int("390")))
return (count($uris), $uris)

