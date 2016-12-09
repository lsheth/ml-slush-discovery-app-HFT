xquery version "1.0-ml";

let $uris :=  cts:uris('', 'document',cts:collection-query(("Raw_data")))
return (count($uris), $uris)

