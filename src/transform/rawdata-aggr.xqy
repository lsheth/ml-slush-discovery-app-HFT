xquery version "1.0-ml";
module namespace trns = "http://marklogic.com/transform/topsongs";
declare namespace stud = "http://MarkLogic.com/Songs";

declare function trns:transform(
  $content as map:map,
  $context as map:map
) as map:map*
{
  let $doc := map:get($content, 'value')
  let $song-key := $doc/stud:*/stud:ID/text()
  let $weeks := cts:search(
    collection('weeks'),
    cts:element-value-query(xs:QName("stud:Song_Id"),$song-key))
  let $formats := cts:search(
    collection('formats'),
    cts:element-value-query(xs:QName("stud:Song_Id"),$song-key))
  let $lengths := cts:search(
    collection('lengths'),
    cts:element-value-query(xs:QName("stud:Song_Id"),$song-key))
  let $writers := cts:search(
    collection('writers'),
    cts:element-value-query(xs:QName("stud:Song_Id"),$song-key))
  let $producers := cts:search(
    collection('producers'),
    cts:element-value-query(xs:QName("stud:Song_Id"),$song-key))
  let $descs := cts:search(
    collection('Song_desc'),
    cts:element-value-query(xs:QName("stud:Song_Id"),$song-key))
  let $genres := cts:search(
    collection('genre'),
    cts:element-value-query(xs:QName("stud:Song_Id"),$song-key))
   let $doc :=
    typeswitch($doc)
      case document-node() return
        $doc/*
      default return
        $doc
  let $_ := xdmp:log(("weeks: ",$weeks)) 
  let $doc-ns := fn:namespace-uri($doc)
  let $enriched-doc :=
    element { fn:node-name($doc) }
    {
      $doc/namespace::*,
      $doc/@*,
      $doc/*,
      element stud:Weeks {
          for $week in $weeks order by $week/stud:*/stud:CanonicalWeek descending
		  return ($week/stud:*/stud:CanonicalWeek, $week/stud:*/stud:CanonicalYear) },
      element stud:Genres {
          for $genre in $genres 
      return $genre/stud:*/stud:Genre },
      element stud:Formats {
          for $format in $formats 
      return $format/stud:*/stud:Format },
      element stud:Lengths {
          for $length in $lengths 
      return $length/stud:*/stud:Length },
      element stud:Writers {
          for $writer in $writers 
      return $writer/stud:*/stud:Writer },
      element stud:Producers {
          for $producer in $producers 
      return $producer/stud:*/stud:Producer },
      element stud:Desc {
          for $desc in $descs 
      return $desc/stud:*/stud:Description }
	}
  let $_ := map:put($content, 'value', document { $enriched-doc })
  return $content
};
