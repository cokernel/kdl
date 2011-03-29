<?php

function sanitize($us_href) {
  $s_href = '';
  if (preg_match("#^http://nyx.uky.edu/dips/([^/?]+)/data/(\d+)/(\d+).txt$#", $us_href)) {
    $s_href = $us_href;
  }
  if (preg_match("#^http://nyx.uky.edu/tiles/tile.php\?Path=http://nyx.uky.edu/dips/([^/?]+)/data/(\d+)/.AND.Image=(\d+).AND.Start=(\d+).AND.Length=(\d+).AND.Format=jpg$#", $us_href)) {
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
  $us_href = "http://nyx.uky.edu/tiles/tile.php?Path=http://nyx.uky.edu/dips/sample_aip/data/0001/.AND.Image=0001.AND.Start=53030.AND.Length=23104.AND.Format=jpg";
  print sanitize($us_href) . "\n";
}

?>
