<?php

function sanitize($us_href) {
  $s_href = '';
  if (preg_match("#^http://nyx.uky.edu/dips/([-\w]+)/data/([-\w,\.]+/)*([-\w,\.]+)/([-\w,\.]+).txt$#", $us_href)) {
    $s_href = $us_href;
  }
  if (preg_match("#^http://nyx.uky.edu/tiles/tile.php\?Path=http://nyx.uky.edu/dips/([-\w\.]+)/data/([-\w,\.]+/)*([-\w,\.]+)/.AND.Image=([-\w,\.]+).AND.Start=(\d+).AND.Length=(\d+).AND.Format=jpg$#", $us_href)) {
    $s_href = str_replace(".AND.", "&", $us_href);
    $s_href = str_replace("Path=http://nyx.uky.edu/dips/", "Path=tiles/", $s_href);
  }
  return $s_href;
}

if (array_key_exists('href', $_REQUEST)) {
  $s_href = sanitize($_REQUEST['href']);
  $output = '';

  if (strlen($s_href) > 0) {
    $curl = curl_init();
    curl_setopt($curl, CURLOPT_URL, $s_href);
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
    $output = curl_exec($curl);
    curl_close($curl);
  }

  if (preg_match("/Format=jpg/", $s_href)) {
    header("Content-type: image/jpeg");
  }
  print $output;
}
else {
  $array = array(
#    "http://nyx.uky.edu/tiles/tile.php?Path=http://nyx.uky.edu/dips/sample_aip/data/0001/.AND.Image=0001.AND.Start=53030.AND.Length=23104.AND.Format=jpg",
#    "http://nyx.uky.edu/dips/KUK_ada_1916/data/ada_1916_001/ada_1916_001.txt",
#    "http://nyx.uky.edu/tiles/tile.php?Path=http://nyx.uky.edu/dips/sample_collections_folder_level/data/66M37_1_01/0002/.AND.Image=0002.AND.Start=540542.AND.Length=5825.AND.Format=jpg",
#    "http://nyx.uky.edu/dips/beattyville_enterprise_20110714/data/BE_PAGE_4_7-14-11F.indd/BE_PAGE_4_7-14-11F.indd.txt",
    "http://nyx.uky.edu/dips/xt7pnv996z22/data/2011av006_1/2011av006_1_33,_34_p/2011av006_1_33a_127/2011av006_1_33a_127.txt",
    "http://nyx.uky.edu/dips/xt7pnv996z22/data/2011av006_1/2011av006_1_33_34_p/2011av006_1_33a_127/2011av006_1_33a_127.txt",
  );
  foreach ($array as $us_href) {
    print sanitize($us_href) . "\n";
  }
}

?>
