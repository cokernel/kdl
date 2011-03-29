<?php

/*

tile.php: Extracts a pre-created image tile from the .tls file and streams to the browser.

Input parameters:
 1) Path: relative or absolute path to folder containing the tiled image.
 2) Image: file name of the image from which to extract a tile.
 2) Start: starting position of tile in .tls file, in bytes.
 7) Length: length of tile, in bytes.
 8) Format: image file format (either "jpg", "png", or "gif"; can add others as needed).

Example call to this script:

http://localhost/gmapviewer/tile.php?Path=tiles/&Image=Image_0112&Start=845445&Length=6391&Format=jpg

*/

// Get URL input arguments:
$path = $_GET['Path'];
$image = $_GET['Image'];
$start = $_GET['Start'];
$length = $_GET['Length'];
$format = $_GET['Format'];

// If any of the inputs are unspecified then return the "No image" placeholder:
if($path == "" || $image == "" || $start == null || $length == null || $format == null)
{
  header("Content-type: image/jpeg");
  imagejpeg("resources/noimage256.jpg", NULL, 75);
  exit();
}

// Open the .tls file:
$tileFile = fopen("{$path}{$image}.tls", "r");
if(!$tileFile)
{
  header("Content-type: image/jpeg");
  imagejpeg("resources/noimage256.jpg", NULL, 75);
  exit();
}

// Seek to the start of the desired tile:
fseek($tileFile, $start);

// Set image type in header output (add other image formats as needed):
if($format == "jpg") header("Content-type: image/jpeg");
else if($format == "png") header("Content-type: image/png");
else if($format == "gif") header("Content-type: image/gif");

// Read in and stream the tile to the browser:
echo fread($tileFile, $length);

?>