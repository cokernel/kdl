
# gmaptilerv02.py:
#
# Loops through images within a specified directory and creates tiles for each image for use in the GMaps Image Viewer.
# Tiles are named according to the template z_c_r.jpg where z = zoom level, c = column, r = row
# Tiles are either concatenated into a single physical file (.tls file), or are stored as separate image files.
# If tiles are stored in a single .tls file:
#    A text file is generated that contains image metadata and a list of tile byte locations and lengths within the .tls file.
#    The .tls file simply contains all the tiles bytes concatenated back-to-back in the order they are created (see code below).
#    An extraction script (tile.php or equivalent) is needed to pull individual tiles from the .tls file when requested by the GMaps Image Viewer.
# If tiles are stored as separate image files:
#    A text file is generated that contains image metadata.
#    Tile image files are saved according to the naming convention described above.
#    The GMaps Image Viewer will simply request the static tiles; no extraction script is required.
# see README.txt for a description of the .tls and metadata file structures.

#
# Author: Ben Legler, University of Wyoming Libraries
# 12/8/2009
#
#
# Requirements:
#  1) Python (tested with version 2.6)
#	  (http://www.python.org/)
#  1) Python Image Library (PIL) (tested with version 1.1.6)
#     (http://www.pythonware.com/products/pil/)
#  2) ImageMagick, installed somewhere on the computer (tested with version 6.5.6-Q16).
#     (note: if PIL can open all your images then this dependency can be removed; to do so, edit lines 81-96)
#     (http://www.imagemagick.org/script/download.php)
#
#
# Example Windows command-line usage:
# C:\Python26\python.exe C:\wamp\www\gmapviewer\gmaptilerv02.py


# CONFIGURATION:

# Path to ImageMagick "convert" executable:
imageMagick_convert_path = "C:\\wamp\\ImageMagick-6.5.6-Q16\\convert.exe";

# List of file types that will be sent to the image tiler:
# (This script should be able to handle any image file type recognized by ImageMagick)
# (This list is case-insensitive)
fileTypes = "\.(jpg|jpeg|bmp|png|gif|tif|tiff)$"

# Temp directory containing images to be processed:
dropboxDir = 'C:\\wamp\\www\\gmapviewer\\dropbox\\'

# Directory where tiles should be stored:
tileDir = 'C:\\wamp\\www\\gmapviewer\\tiles\\'

# Directory where images should be archived:
#   Images can simply be added to the dropbox, with this script set to run on a schedule to process any images in dropbox and transfer them to archive.
#   This eliminates the need to manually track which images have or have not been processed, thereby simplifying the tile creation workflow.
archiveDir = 'C:\\wamp\\www\\gmapviewer\\archive\\'

# Tile storage method:
#   True = Concatenate tiles into a single .tls file and add tile list to metadata file.
#   False = Store tiles as separate image files, and omit tile list from metadata file.
generate_tls = True

# size of a single image tile, in pixels (both width and height):
tileSize = 256

# width of thumbnail image, in pixels:
thumbnailWidth = 150

# image scale, in pixels per imageScaleUnit:
# (imageScaleUnit is one of: "mm", "cm", "m", "km", "in", "ft", "mi"
imageScale = 283
imageScaleUnit = "in"

# New line character for metadata text file output. Change this to suite your web server's OS (e.g., "\r", "\n", "\r\n"):
newLine = "\r\n"

# END CONFIGURATION


import os, os.path, sys, re, shutil
from time import strftime
from math import *
import Image

# Opens a source image and creates tiles
class Tiler:
    
    def __init__(self, source_path, name, output_path):
        # Reads in the source image and sets some image parameters:
        
        self.source_path = source_path
        self.name = name
        self.base_name = re.sub('\.\w+$', '', self.name)
        self.output_path = output_path
        self.jpeg_path = None
        self.valid_image = False
        print "Opening", self.name
        
        # First try to directly open the image with PIL; if that fails then use ImageMagick to convert to jpeg and open the jpeg with PIL:
        try:
            self.source_image = Image.open(self.source_path)
            self.valid_image = True
        except:
            print "  (converting image to JPEG format)"
            try:
                self.jpeg_path = re.sub('\.\w+$', '.jpg', self.source_path)
                os.system("%s +compress %s %s and exit" % (imageMagick_convert_path, self.source_path, self.jpeg_path))
                self.source_image = Image.open(self.jpeg_path)
                self.valid_image = True
                os.remove(self.jpeg_path)
            except:
                print "  (conversion to JPEG format FAILED!!!  Tiles not created)"
                self.valid_image = False
                if self.jpeg_path != None and os.path.exists(self.jpeg_path):
                    os.remove(self.jpeg_path)
        
        if self.valid_image == True:
            self.image_width = self.source_image.size[0]
            self.image_height = self.source_image.size[1]
            
            # calculate number of zoom levels (zero-based):
            width_min = (log(self.image_width) - log(tileSize)) / log(2)
            height_min = (log(self.image_height) - log(tileSize)) / log(2)
            self.layer_count = int(ceil(max(width_min, height_min)))
    
    def generateTiles(self):
        # Tiles the image, starting at the max zoom level and working out until the entire image fits into a single tile:
        # Also creates the metadata file as the tiles are generated.
        # Also creates the thumbnail one step before the image width drops below the thumbnail width.
        
        if not os.path.exists(self.output_path):
            os.makedirs(self.output_path)
        
        # Remove the .tls tileFile if it already exists (it will be opened for appending, so if it exists then the new tiles will be improperly appended to the old tiles)
        if generate_tls:
            if os.path.exists(os.path.join(self.output_path, self.base_name + ".tls")):
                os.remove(os.path.join(self.output_path, self.base_name + ".tls"))

        # Create/open the metadata file and .tls tile file:
        metaFile = open(os.path.join(self.output_path, self.base_name + ".txt"), "wb")
        if generate_tls:
            tileFile = open(os.path.join(self.output_path, self.base_name + ".tls"), "ab")  # append, binary mode

        metaFile.write("name\t%s%s" % (self.base_name, newLine))
        metaFile.write("width\t%i%s" % (self.image_width, newLine))
        metaFile.write("height\t%i%s" % (self.image_height, newLine))
        metaFile.write("maxzoom\t%i%s" % (self.layer_count, newLine))
        metaFile.write("tilesize\t%i%s" % (tileSize, newLine))
        metaFile.write("scale\t%i%s" % (imageScale, newLine))
        metaFile.write("scaleunit\t%s%s" % (imageScaleUnit, newLine))
        metaFile.write("format\tjpg%s" % (newLine))
        
        # Loop through each zoom layer, starting with the max zoom and stepping down to the min zoom, adding each tile to tileFile:
        # Tiles are ordered in tileFile from max zoom to min zoom by col then by row.
        current_layer = self.layer_count
        tile_start = 0
        tile_length = 0
        while current_layer >= 0:
            print "Generating tiles for layer", current_layer
            rows = int(ceil(self.image_height / tileSize))
            cols = int(ceil(self.image_width / tileSize))
            
            # Loop through rows and cols for this zoom level, and create tiles:
            for c in range(0, cols+1):
                for r in range(0, rows+1):
                    tile_name = "%i_%i_%i.jpg" % (current_layer, c, r)
                    tile_path = os.path.join(self.output_path, tile_name)
                    if (self.image_width - c*tileSize) > 0 and (self.image_height - r*tileSize) > 0:
                        tile_left = c*tileSize
                        tile_top = r*tileSize
                        tile_right = min(c*tileSize + tileSize, self.image_width)
                        tile_bottom = min(r*tileSize + tileSize, self.image_height)
                        tile = self.source_image.crop((tile_left, tile_top, tile_right, tile_bottom))
                        if tile.size[0] < tileSize or tile.size[1] < tileSize:
                            tile2 = Image.new("RGB", (256,256), 0x000000)
                            tile2.paste(tile, (0,0))
                            if generate_tls:
                                tile2.save(tileFile, "jpeg", quality=85)
                            else:
                                tile2.save(tile_path, "jpeg", quality=85)
                        else:
                            if generate_tls:
                                tile.save(tileFile, "jpeg", quality=85)
                            else:
                                tile.save(tile_path, "jpeg", quality=85)
                        if generate_tls:
                            tileFile.flush()
                            tile_length = tileFile.tell() - tile_start
                            metaFile.write("%s\t%i\t%i%s" % (tile_name, tile_start, tile_length, newLine))
                            tile_start = tileFile.tell()
            
            # Reduce the image size by 1/2 for the next zoom level:
            current_layer = current_layer - 1
            self.image_width = ceil(self.image_width / 2)
            self.image_height = ceil(self.image_height / 2)
            self.source_image = self.source_image.resize((self.image_width, self.image_height), Image.ANTIALIAS)
            
            # Create the thumbnail image:
            if self.image_width > thumbnailWidth and (self.image_width/2) <= thumbnailWidth:
                print "Creating thumbnail for", self.name
                thumbnailHeight = int(ceil(self.image_height * (thumbnailWidth / self.image_width)))
                thumbnail = self.source_image.resize((thumbnailWidth, thumbnailHeight), Image.ANTIALIAS)
                thumbnail.save(os.path.join(self.output_path, self.base_name + "_tb.jpg"), "jpeg", quality=85)
        
        metaFile.close()
        if generate_tls:
            tileFile.close()


if __name__ == "__main__":

    print "\nBatch tiler run started on", strftime("%Y-%m-%d %H:%M:%S"),"\n"
    
    # Check for valid configuration paths:
    if imageMagick_convert_path == "" or os.path.exists(imageMagick_convert_path) == False:
        print "ERROR: Path to ImageMagick not valid"
        sys.exit()
    if dropboxDir == "" or os.path.exists(dropboxDir) == False:
        print "ERROR: Dropbox directory not valid"
        sys.exit()
    if tileDir == "" or os.path.exists(tileDir) == False:
        print "ERROR: Tile directory not valid"
        sys.exit()
    if archiveDir == "" or os.path.exists(archiveDir) == False:
        print "ERROR: Archive directory not valid"
        sys.exit()
    
    processed = 0
    errors = 0
    
    # Loop through all image files in the dropbox directory (including any subfolders):
    for root, dirs, files in os.walk(dropboxDir):
        for name in files:

            # Only process files if they are one of the specified image formats:
            if re.search(fileTypes, name, re.IGNORECASE):
                        
                print "-------------------------------------------"
                        
                source_path = os.path.join(root, name)
                base_name = re.sub('\.\w+$', '', name)
                output_path = os.path.join(tileDir, base_name)
                        
                # See if a tiled image with the same name already exists; if so, log a message (but still tile the image and overwrite the existing one):
                tileExists = os.path.exists(output_path)
                if tileExists:
                    print "TILES ALREADY EXIST AND WERE OVERWRITTEN FOR", name
                        
                # Read in the image and initialize image parameters:
                tiled_image = Tiler(source_path, name, output_path)
                        
                # Generate metadata file and tiles (plus thumbnail image):
                if tiled_image.valid_image:
                    print "Tiling", source_path
                    tiled_image.generateTiles()
                        
                # Check to see that the tiled image actually exists. If not, log an error message:
                # If it does exist then move the original image to the archive folder and create blank record in MySQL types database
                if os.path.exists(os.path.join(output_path, base_name + ".tls")) == False:
                    print "ERROR: FAILURE CREATING TILES FOR", name
                    errors=errors+1
                else:
                    processed=processed+1
                            
                    # Copy the original image to the archive folder:
                    print "Moving", name, "to the archival folder"
                    shutil.move(source_path, os.path.join(archiveDir, name))
    
    print "\nBatch tiler run completed on", strftime("%Y-%m-%d %H:%M:%S."), processed, "images processed.", errors, "errors encountered."
