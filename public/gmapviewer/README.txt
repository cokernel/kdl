
GMap Image Viewer Documentation

Ben Legler, University of Wyoming Libraries
12/8/2009


-------------------------------------------


	The GMap Image Viewer is based on the Google Maps API (v. 2, http://code.google.com/apis/maps/).  
It is based on the functionality used by Google Maps; however, with map layers replaced by 
a custom image tile layer and the standard map controls replaced by custom viewer buttons.  Instructions 
for embedding this viewer into your own web site are provided here.

	A tiling script written in Python (gmaptilerv02.py) is included to provide a means of generating 
image tiles for use within the GMaps Image Viewer.

	If using the second image storage method described below (the Standard Tile Storage method), 
then the image viewer requires no server-side scripts to operate and can be easily included in
most any web site with just a few short lines of HTML and JavaScript.  However, the Python script will 
still be required to generate tiles for use in the viewer.

-------------------------------------------


License:

  Open-source MIT License.  See license.txt for details.  This code relies on the Google Maps API, licensed separately.

-------------------------------------------


Image tile storage:

	Images are stored using a standard tiling approach similar to Google Maps (default size of 
256x256 pixels, jpeg format).  These tiles can be either stored as standard image tile files 
(e.g., mny separate .jpg files), or can be concatenated into a single file (.tls file) to reduce the number 
of individual files stored on the server, as described below.  The second method of concatenating 
tiles into a single file is preferable for projects involving large numbers of images.  For even 
moderately sized  images, the number of tiles can become immense.  For example, an image measuring 
3328 x 4992 pixels will produce 361 image tiles.  Projects involving thousands of images will 
quickly result in several million tiles stored on the server.  By concatenating and storing the 
image tiles in a single physical file, the number of physical files that must be stored is 
dramatically reduced, to only three files per image (.tls, .txt, and a thumbnail .jpg).

	An occasionally used alternative to this concatenation method is the jpeg2000 format combined  
with a custom codec to extract regions of interest upon request and return these as jpeg tiles.  
However, performance of jpeg2000-based tile extraction is much slower than that of pre-created 
tiles and complicated caching schemes must be used to obtain acceptable performance.  For an 
example of a jpeg2000-based image server, see the Djatoka Image Server Project
(http://sourceforge.net/apps/mediawiki/djatoka/index.php?title=Main_Page).  The concatenated tile 
storage method used here performs nearly as fast as a standard tile storage method, and much faster 
than jpeg2000-based solutions while providing the storage benefits of jpeg2000.

	Image tile names are defined by the zoom level, column, and row, in that order and separated by 
underscores like this: 5_2_4.jpg (= zoom level 5, column 2, row 4).  Column and row counts start at 
zero in the upper left corner of the image and increase to the right and down.  Zoom level 0 is the 
farthest out (where the entire image fits into a single tile when sized down from the original 
resolution by repeated factors of two).  Each subsequent increase in zoom level resulting in a 
doubling of the image dimensions and a quadrupling of the potential tile space until the native 
resolution of the original image is reached.

The two tile storage methods used by the GMaps Image Viewer are as follows:

1) Concatenated Tile Storage method:

	This method pre-creates static image tiles for each zoom level within the image, but, rather than
	storing them as separate image files, concatenates the image files into a single physical file with
	a .tls file extension.  Images are concatenated back-to-back with no spaces or separators.  They are 
	concatenated in the order defined by the Python tiling script (gmaptilerv02.py): maximum zoom level to
	minimum zoom level, then by cols, then by rows.
	
	The position and byte length of each tile in the .tls file is stored in the image metadata file.
	This metadata file takes the same name as the original image file, with a .txt extension.  The format 
	of the metadata file is a simple-tab-delimited text file with parameter name-value pairs.  An example 
	of a metadata file is provided here, with explanations of each parameter given in square brackets:
	
	name	Image_0112		[Name of the image without file extension; this also defines the image folder name]
	width	3328			[image width, in pixels]
	height	4992			[image height, in pixels]
	maxzoom	5				[maximum zoom level, starting at level 0; e.g., this image has 6 zoom levels, from 0 to 5]
	tilesize	256			[tile width and height, in pixels]
	scale	283				[image scale, in pixels per unit when viewed at maximum resolution]
	scaleunit	in			[image scale unit, one of: "mm", "cm", "m", "km", "in", "ft", or "mi"; or define others as desired]
	format	jpg				[image tile format, one of "jpg", "png", "gif"; or define others as needed]
	5_0_0.jpg	0	5056	[the first image tile in the list; name = {zoom}_{col}_{row}.{unit}; first parameter is byte position in .tls file; second parameter is byte length of tile]
	5_0_1.jpg	5056	2731
	5_0_2.jpg	7787	2691
	5_0_3.jpg	10478	4620
	5_0_4.jpg	15098	2750
	5_0_5.jpg	17848	3137
	...
	...
	...
	1_0_0.jpg	2424205	15312
	1_0_1.jpg	2439517	4082
	0_0_0.jpg	2443599	6783 [last image tile, at the minimum zoom level of 0, containing the entire image]
	
	Using this method, image tiles must be retrieved through a server-side script that can open the .tls file, 
	extract the bytes corresponding to the desired image tile, and stream these bytes back to the browser.
	A simple script, tile.php, is included with this installation that will perform this task.  However, tile
	extraction is simple enough that tile.php could be easily re-cast in most other server-side languages.
	An example call to tile.php is as follows:
	http://www.mysite.com/gmapviewer/tile.php?Path=tiles/&Image=Image_0112&Start=17848&Length=3137&Format=jpg
	

2) Standard Tile Storage method:

	This method simply stores the image tiles as separate static files.  These files can then be requested by 
	the image viewer with a simple static URL (e.g.: http://www.mysite.com/gmapviewer/tiles/Image_0139/5_0_5.jpg).
	
	Use this method if you cannot, or prefer not, to have the image viewer be dependent on server-side scripts.
	
	The image metadata file in this case does not store a list of tile positions and lengths.  Instead, metadata 
	consists only of the following parameter name-value pairs (with explanations of each given in square brackets):
	
	name	Image_0139		[Name of the image, without file extension; this also defines the image folder name]
	width	3328			[image width, in pixels]
	height	4992			[image height, in pexels]
	maxzoom	5				[maximum zoom level, starting at level 0; e.g., this image has 6 zoom levels, from 0 to 5]
	tilesize	256			[tile width and height, in pixels]
	scale	283				[image scale, in pixels per unit when viewed at maximum resolution]
	scaleunit	in			[image scale unit, one of: "mm", "cm", "m", "km", "in", "ft", "mi"; or define others as desired]
	format	jpg				[image tile format, one of "jpg", "png", "gif"; or define others as needed]


	Two sample images are included with this documentation.  The original images are located in "archive/".  The 
	tiled copies of these images are in the "tiles/" folder.  "Image_0112" was tiled using the Concatenated Tile 
	Storage method, while "Image_0139" was tiled using the Standard Tile Storage method.  Both can be directly 
	opened in the provided demo of the image viewer (gmapviewer.htm); however, to open Image_0112 PHP must be 
	installed on the server and the viewer must be opened through a URL or IP rather than directly from the file 
	system.


-------------------------------------------


Image tiling script:

	The included Python script (gmaptilerv02.py) can be used to tile images in batches for use within the 
GMap Image Viewer.  The script can be run from the command-line.  The script is designed to loop through a 
temp folder that contains images to be tiled, create tiles for those images, store the tiles in a designated 
tile folder, then transfer the original image from the temp folder to a permanent archival location.  The 
script can generate tiles for either of the two methods described above (Concatenated tile storage method 
or Standard tile storage method) by changing the value of the "generate_tls" parameter in the script's 
configuration section.

	See the configuration section in gmaptilerv02.py (lines 33-70) for instructions on how to configure the 
script for your own use.  Make sure that the user under which the script is run has read/write access to 
the drives and folders where the images and tiles will be stored.


Your computer must be configured with the following to run the tiler script:
	
	1) Python (tested with version 2.6)
	   (http://www.python.org/)
	   
	2) Python Image Library (PIL) (tested with version 1.1.6)
	   (http://www.pythonware.com/products/pil/)
	   
	3) ImageMagick, installed somewhere on the computer (tested with version 6.5.6-Q16).
	   Note: if PIL can open all your images then this dependency can be removed; to do so, edit lines 81-96
	   (http://www.imagemagick.org/script/download.php)


To test the tiling script with the included sample images, follow these steps:
	
	1) Copy the sample images from the "archive/" folder to the "dropbox/" folder.
	
	2) In the configuration section of gmaptilerv02.py, edit the following lines:
	   a) Line 36: imageMagick_convert_path must point to the location of the ImageMagick convert.exe utility.
	   b) Line 44: dropboxDir must point to the location of the "dropbox/" folder as determined by where you 
	      installed the viewer.
	   c) Line 47: tileDir must point to the location of the "tiles/" folder.
	   d) Line 52: archiveDir must point to the location of the "archive/" folder.
	   e) Line 57: generate_tls - set to True to generate a single concatenated tile file (.tls) holding all 
	      image tile files; set to False to generate separate static image tile files.
	
	3) Open a terminal window (or command prompt) and enter the following line (modified to fit the location of 
	   your installation of Python and the tiler script):
	   C:\Python26\python.exe C:\www\gmapviewer\gmaptilerv02.py


-------------------------------------------


Viewer installation and basic usage:

1) Unzip gmapviewer.zip to a suitable location within your web directory.

2) Generate tiles for your images using the included tiling script (gmaptilerv02.py).
   (or, skip this step and test the viewer using one of the included pre-tiled images)

3) Open gmapviewer.htm and edit the following lines:
   Line 8: Replace the existing Google API Key with your own key.
           (a key can be obtained at http://code.google.com/apis/maps/signup.html)
   Line 20: Modify the copyright text as desired for your images.
   Line 21: Change the image URL to point to your image (the URL can be relative or absolute).
   
4) Open a web browser and point it to your modified copy of gmapviewer.htm
   NOTE: if you are using the concatenated tile storage method then PHP must be
   installed on your server and you must call gmapviewer via an IP or a URL such as
   localhost, rather than simply opening gmapviewer.htm in a browser from the file
   system.


-------------------------------------------


How to embed the GMap Image Viewer in your own pages:

	The basic process is described here.  It is possible to include multiple copies of the viewer 
on a single page by creating separate <div> tags for each viewer instance then creating multiple 
instances of the viewer object, with each instance assigned to a separate <div> tag.

1) Include the following scripts in the head of your HTML page.  Be sure to replace the Google Maps 
API Key with your own key.  Also edit the relative path to the "resources/" folder as needed.

   <script src="http://maps.google.com/maps?file=api&v=2.x&key=ABQIAAAAJMY_gvg_FFHwMirOGyyGGRQ-oq_YVKkvra0B8jFQ1CvewHcGgBRh-wtCgAW_x1h9Vp1PJGDZYvIknw" type="text/javascript"></script>
   <script src="resources/elabel.js" type="text/javascript"></script>
   <script src="resources/dragzoom.js" type="text/javascript"></script>
   <script src="resources/gmapviewer.js" type="text/javascript"></script>

2) Include the following JavaScript code in the head of your HTML page.  Also edit the image 
   path in viewer.loadImage() to point to your image, and modify the copyright text as desired
   in viewer.setCopyright().

   <script type="text/javascript">

   var viewer = null;

   function load()
   {
     viewer = new GMapViewer("viewer");
     viewer.setCopyright("Image", "&copy; 2009 <a href='http://www.uwyo.edu'>University of Wyoming</a>");
     viewer.loadImage("tiles/Image_0139/Image_0139.txt");
   }

   </script>

3) Add the following onload event handler to the <body> tag:

   onload="load();"

4) Insert a <div> on the page to hold the viewer.  For example:

   <div id="viewer" style="width: 800px; height: 650px;"></div>

