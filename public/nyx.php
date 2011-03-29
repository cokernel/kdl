<?php

function sanitize($us_href) {
  $s_href = '';
  if (preg_match("#^http://nyx.uky.edu/dips/([-\w]+)/data/([-\w]+)/([-\w]+).txt$#", $us_href)) {
    $s_href = $us_href;
  }
  if (preg_match("#^http://nyx.uky.edu/tiles/tile.php\?Path=http://nyx.uky.edu/dips/([-\w]+)/data/([-\w]+)/.AND.Image=([-\w]+).AND.Start=(\d+).AND.Length=(\d+).AND.Format=jpg$#", $us_href)) {
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
    "http://nyx.uky.edu/tiles/tile.php?Path=http://nyx.uky.edu/dips/sample_aip/data/0001/.AND.Image=0001.AND.Start=53030.AND.Length=23104.AND.Format=jpg",
    "http://nyx.uky.edu/dips/KUK_ada_1916/data/ada_1916_001/ada_1916_001.txt",
  );
  foreach ($array as $us_href) {
    print sanitize($us_href) . "\n";
  }
}

?>
