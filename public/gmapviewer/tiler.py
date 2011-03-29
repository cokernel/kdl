#!/usr/bin/env python
# tiler.py
#
# Generate tile files (with metadata and thumbnails) suitable for use 
# with the Google Maps image viewer.  Tiles are named via the template
#
#     {zoom level}_{column}_{row}.jpg
#
# By default, tile files are concatenated into a single TLS file.  An
# image metadata file mapping tile names into byte locations in the TLS
# file is automatically generated.  An extraction script (tile.php or
# equivalent) is required to pull individual tiles from the TLS file
# when required by the Google Maps image viewer.
#
# Optionally, tiles can be stored as separate image files.  An image
# metadata file is still generated.  The image files are named according
# to the template above.  The Google Maps image viewer will simply
# request the static files, so no extraction script is required.
#
# See README.txt for a description of the TLS and image metadata file
# structures.
#
# Original author: Ben Legler, University of Wyoming Libraries, 2009-12-08
# Modified by: Michael Slone, University of Kentucky Libraries, 2011-03-15
#
# Requirements:
# *  Python                     
#      (tested with 2.4+)       http://www.python.org
# *  Python Image Library (PIL) 
#      (tested with 1.1.6)      http://www.pythonware.com/products/pil/
# *  ImageMagick                
#      (tested with 6.5.6-Q16)  http://www.imagemagick.org/script/download.php
#
# ImageMagick is only required if PIL cannot read some images.

def default_configuration():
    config = Config()
    dict = {
        'path_to_ImageMagick_convert': '/usr/bin/convert',
        'file_types_to_process':       '\.(tif|tiff)$',
        'input_directory':             '/tmp/tiler/input/',
        'output_directory':            '/tmp/tiler/output/',
        'processed_directory':         '/tmp/tiler/processed/',
        'file':                        None,
        'verbose':                     True,
        'move_input_files':            True,
        'delete_input_files':          False,
        'concatenated_tls_required':   True,
        'tile_size':                   256,
        'thumb_width':                 150,
        'reference_width':             'max',
        'pdf_width':                   'max',
        'image_scale':                 283,
        'quality':                     85,
        'image_scale_unit':            'in',
        'line_ending':                 "\n",
    }
    config.update(dict)
    config.set('processed', 0)
    config.set('errors', 0)
    return config

def process():
    config = Config().check_paths()
    log_start_processing()
    
    if config.get('file') is None:
        process_directory(config.get('input_directory'))
    else:
        process_file(config.get('file'))
    
    log_stop_processing()

def process_directory(directory):
    for root, dirs, files in os.walk(directory):
        for name in files:
            if re.search(Config().get('file_types_to_process'), name, re.IGNORECASE):
                BaseImage(os.path.join(root, name)).generate_tiles()

def process_file(file):
    path = os.path.join(Config().get('input_directory'), file)
    if os.path.exists(path):
        BaseImage(path).generate_tiles()

class ZoomLayer:
    def __init__(self, base_image):
        self.base_image = base_image
        self.pathmaster = self.base_image.pathmaster
        self.metadata = self.base_image.metadata

    def generate_tiles(self):
        self.log_generating_tiles()
        tile_size = Config().get('tile_size')
        rows = int(ceil(self.base_image.image_height / tile_size))
        columns = int(ceil(self.base_image.image_width / tile_size))
        for column in range(0, columns+1):
            for row in range(0, rows+1):
                self.create_tile_for(column, row)

    def create_tile_for(self, column, row):
        self.tile_name = "%i_%i_%i.jpg" % (self.base_image.current_layer, column, row)
        self.tile_path = os.path.join(self.pathmaster.output_dir, self.tile_name)
        tile_size = Config().get('tile_size')
        if (self.base_image.image_width - column*tile_size) > 0 and (self.base_image.image_height - row*tile_size) > 0:
            tile = self.base_image.crop(column, row)
            if tile.size[0] < tile_size or tile.size[1] < tile_size:
                tile2 = Image.new("RGB", (tile_size,tile_size), 0x000000)
                tile2.paste(tile, (0,0))
                self.save_tile(tile2)
            else:
                self.save_tile(tile)
            self.flush_tile_file()

    def save_tile(self, tile):
        path = self.tile_path
        if Config().get('concatenated_tls_required'):
            path = self.metadata.tile_file
        tile.save(path, "jpeg", quality=Config().get('quality'))

    def flush_tile_file(self):
        if Config().get('concatenated_tls_required'):
            self.metadata.tile_file.flush()
            tile_length = self.metadata.tile_file.tell() - self.base_image.tile_start
            self.metadata.get_metadata_file().write("%s\t%i\t%i%s" % (self.tile_name, self.base_image.tile_start, tile_length, Config().get('line_ending')))
            self.base_image.tile_start = self.metadata.tile_file.tell()

    def log_generating_tiles(self):
        if Config().get('verbose'):
            print "Generating tiles for layer", self.base_image.current_layer

class Metadata:
    def __init__(self, pathmaster):
        self.pathmaster = pathmaster
        self._opened = False

    def __del__(self):
        self.close()
        self.close_tile_file()

    def get_metadata_file(self):
        if not(self._opened):
            self.open_metadata_files()
        return self._metadata_file

    def open(self, file):
        path_to_metadata_file = os.path.dirname(file)
        if not os.path.exists(path_to_metadata_file):
            os.makedirs(path_to_metadata_file)
        self._metadata_file = open(file, "wb")

    def close(self):
        self._metadata_file.close()

    def write_header(self, base_name, image_width, image_height, layer_count):
        if not(self._opened):
            self.open_metadata_files()
        line_ending = Config().get('line_ending')
        lines = [
            "name\t%s%s" % (base_name, line_ending),
            "width\t%i%s" % (image_width, line_ending),
            "height\t%i%s" % (image_height, line_ending),
            "maxzoom\t%i%s" % (layer_count, line_ending),
            "tilesize\t%i%s" % (Config().get('tile_size'), line_ending),
            "scale\t%i%s" % (Config().get('image_scale'), line_ending),
            "scaleunit\t%s%s" % (Config().get('image_scale_unit'), line_ending),
            "format\tjpg%s" % (line_ending),
        ]
        for line in lines:
            self._metadata_file.write(line)

    def open_tile_file(self):
        if not os.path.exists(self.pathmaster.output_dir):
            os.makedirs(self.pathmaster.output_dir)

        if Config().get('concatenated_tls_required'):
            tile_filename = self.pathmaster.tile_filename
            if os.path.exists(tile_filename):
                self.tile_file = open(tile_filename, "wb")
            else:
                self.tile_file = open(tile_filename, "ab")

    def close_tile_file(self):
        if Config().get('concatenated_tls_required'):
            self.tile_file.close()

    def open_metadata_files(self):
        if (self._opened):
            return
        self.open(self.pathmaster.metadata_location)
        self.open_tile_file()
        self._opened = True

class PathMaster:
    def __init__(self, source_file):
        self.source_file = source_file
        self.source_dir = os.path.dirname(self.source_file)
        self.name = os.path.basename(self.source_file)
        self.base_name = re.sub('\.\w+$', '', self.name)
        self.prefix = relpath(self.source_dir, Config().get('input_directory'))
        self.output_dir = os.path.join(Config().get('output_directory'), self.prefix, self.base_name)
        self.tile_filename = os.path.join(self.output_dir, self.base_name + ".tls")
        self.jpeg_path = os.path.join(self.source_dir, self.base_name + "_tb.jpg")
        self.thumbnail_path = os.path.join(self.output_dir, self.base_name + "_tb.jpg")
        self.metadata_location = os.path.join(self.output_dir, self.base_name + ".txt")
        self.derivative_path = {
            'thumb': os.path.join(self.output_dir, self.base_name + "_tb.jpg"),
            'reference': os.path.join(self.output_dir, self.base_name + ".jpg"),
            'pdf': os.path.join(self.output_dir, self.base_name + ".pdf"),
        }

class DerivativeImage:
    def __init__(self, base_image, type):
        self.base_image = base_image
        self.pathmaster = self.base_image.pathmaster
        self.type = type
        self.width = Config().get(self.type + '_width')

    def save(self):
        source_image = self.base_image.source_image
        image_width = self.base_image.image_width
        image_height = self.base_image.image_height
        if self.width == 'max':
            self.width = image_width
            self.height = image_height
        self.height = int(ceil(image_height * (self.width / image_width)))
        self.log_creating_derivative_image()
        derivative = source_image.resize((self.width, self.height), Image.ANTIALIAS)
        if self.type == 'pdf':
          derivative.save(self.pathmaster.derivative_path[self.type], "pdf", quality=Config().get('quality'))
        else:
          derivative.save(self.pathmaster.derivative_path[self.type], "jpeg", quality=Config().get('quality'))

    def log_creating_derivative_image(self):
        if Config().get('verbose'):
            print "Creating %s for %s" % (self.type, self.pathmaster.name)

class BaseImage:
    def __init__(self, source_image):
        self.valid_image = False
        self.pathmaster = PathMaster(source_image)
        self.metadata = Metadata(self.pathmaster)
        self.open()

    def open(self):
        self.valid_image = False
        self.log_opening_image()
        try:
            self.source_image = Image.open(self.pathmaster.source_file)
            self.valid_image = True
        except:
            self.open_via_jpeg_conversion()
        self.set_image_metadata()
        return self.source_image

    def open_via_jpeg_conversion(self):
        self.log_converting_image_to_jpeg()
        try:
            os.system("%s +compress %s %s and exit" % (Config().get('path_to_ImageMagick_convert'), self.pathmaster.source_file, self.pathmaster.jpeg_path))
            self.source_image = Image.open(self.pathmaster.jpeg_path)
            self.valid_image = True
            os.remove(self.pathmaster.jpeg_path)
        except:
            self.clean_up_jpeg_conversion()

    def clean_up_jpeg_conversion(self):
        self.log_conversion_to_jpeg_failed()
        self.valid_image = False
        if self.pathmaster.jpeg_path != None and os.path.exists(self.pathmaster.jpeg_path):
            os.remove(self.pathmaster.jpeg_path)

    def set_image_metadata(self):
        if self.valid_image == True:
            self.image_width = self.source_image.size[0]
            self.image_height = self.source_image.size[1]
            long_dimension_in_pixels = max(self.image_width, self.image_height)
            self.layer_count = int(ceil((log(long_dimension_in_pixels) -
                                         log(Config().get('tile_size'))) / log(2)))
    
    def crop(self, column, row):
        tile_size = Config().get('tile_size')
        tile_left = column * tile_size
        tile_top = row * tile_size
        tile_right = min(column * tile_size + tile_size, self.image_width)
        tile_bottom = min(row * tile_size + tile_size, self.image_height)
        return self.source_image.crop((tile_left, tile_top, tile_right, tile_bottom))

    def halve_image_size(self):
        self.image_width = ceil(self.image_width / 2)
        self.image_height = ceil(self.image_height / 2)
        self.source_image = self.source_image.resize((self.image_width, self.image_height), Image.ANTIALIAS)

    def generate_tiles(self):
        if self.valid_image:
            self.log_intent_to_tile()
            self.metadata.write_header(self.pathmaster.base_name, self.image_width, self.image_height, self.layer_count)
            self.create_tiles_for_each_zoom_layer()
            if os.path.exists(os.path.join(self.pathmaster.output_dir, self.pathmaster.base_name + '.tls')):
                self.move_input_image_to_processed()
            else:
                self.log_failure_creating_tiles()

    def create_tiles_for_each_zoom_layer(self):
        self.current_layer = self.layer_count
        self.tile_start = 0
        DerivativeImage(self, 'reference').save()
        DerivativeImage(self, 'pdf').save()
        while self.current_layer >= 0:
            ZoomLayer(self).generate_tiles()
            self.halve_image_size()
            DerivativeImage(self, 'thumb').save()
            self.current_layer -= 1

    def move_input_image_to_processed(self):
        Config().increment('processed')
        if Config().get('move_input_files'):
            self.log_moving_image_to_processed()
            processed_dir = os.path.join(Config().get('processed_directory'), self.pathmaster.prefix)
            if not os.path.exists(processed_dir):
                os.makedirs(processed_dir)
            shutil.move(self.pathmaster.source_file, processed_dir)
        if Config().get('delete_input_files'):
            self.log_deleting_image()
            if os.path.exists(self.pathmaster.source_file):
                os.remove(self.pathmaster.source_file)

    def log_deleting_image(self):
        if Config().get('verbose'):
            print "Deleting", self.pathmaster.name

    def log_moving_image_to_processed(self):
        if Config().get('verbose'):
            print "Moving", self.pathmaster.name, "to the archival folder"

    def log_opening_image(self):
        if Config().get('verbose'):
            print "Opening", self.pathmaster.name

    def log_conversion_to_jpeg_failed(self):
        if Config().get('verbose'):
            print "  (conversion to JPEG format FAILED!!!  Tiles not created)"

    def log_converting_image_to_jpeg(self):
        if Config().get('verbose'):
            print "  (converting image to JPEG format)"

    def log_intent_to_tile(self):
        if Config().get('verbose'):
            print "-------------------------------------------"
            if os.path.exists(self.pathmaster.output_dir):
                print "TILES ALREADY EXIST AND WERE OVERWRITTEN FOR", self.pathmaster.name
            print "Tiling", self.pathmaster.source_file

    def log_failure_creating_tiles(self):
        Config().increment('errors')
        if Config().get('verbose'):
            print "ERROR: FAILURE CREATING TILES FOR", self.pathmaster.name

class Config:
    """
    Borg config object
    """
    __we_are_one = {}
    __myvalue = {}

    def __init__(self):
        self.__dict__ = self.__we_are_one

    def setdefault(self, key, value=None):
        if value:
            self.__myvalue.setdefault(key, value)
        return self.__myvalue.get(key)

    def increment(self, key):
        self.__myvalue[key] += 1

    def get(self, key):
        return self.__myvalue.get(key)

    def update(self, dict):
        for key in dict.keys():
            if not(self.__myvalue.has_key(key)):
                self.setdefault(key, dict.get(key))

    def set(self, key, value):
        self.__myvalue[key] = value

    def check_paths(self):
        keys = [
            'path_to_ImageMagick_convert',
            'input_directory',
            'output_directory',
            'processed_directory',
        ]
        for key in keys:
            value = self.get(key)
            if value == "" or not(os.path.exists(value)):
                message = "ERROR: %s=%s does not exist" % ( key.replace('_', ' '), value )
                print message # this is an error, not subject to verbose/quiet
                sys.exit()
        return self

def log_start_processing():
    if Config().get('verbose'):
        print "\nBatch tiler run started on", strftime("%Y-%m-%d %H:%M:%S"),"\n"

def log_stop_processing():
    config = Config()
    if Config().get('verbose'):
        print "\nBatch tiler run completed on", strftime("%Y-%m-%d %H:%M:%S."), config.get('processed'), "images processed.", config.get('errors'), "errors encountered."

import warnings
warnings.filterwarnings("ignore")

import Image
from optparse import OptionParser
import os
import os.path
import re
import shutil
import sys
from math import *
from time import strftime

# backport os.path.relpath to Python 2.4
#
# Immediate source:
#     http://www.saltycrane.com/blog/2010/03/ospathrelpath-source-code-python-25/
#
# Taken from James Gardner's BareNecessities package:
#     http://jimmyg.org/work/code/barenecessities/index.html
#
# Additional modifications made to push from Python 2.5 to 2.4.
def relpath(path, start=os.curdir):
    """Return a relative version of a path"""
    if not path:
        raise ValueError("no path specified")
    start_list = os.path.abspath(start).split(os.sep)
    path_list = os.path.abspath(path).split(os.sep)
    # Work out how much of the filepath is shared by start and path.
    i = len(os.path.commonprefix([start_list, path_list]))
    rel_list = [os.pardir] * (len(start_list)-i) + path_list[i:]
    if not rel_list:
        return os.curdir
    return os.path.join(*rel_list)

def handle_options(options):
    config = Config()
    keys = [
        'input_directory',
        'output_directory',
        'processed_directory',
        'move_input_files',
        'delete_input_files',
        'file',
        'verbose',
    ]
    for key in keys:
        if getattr(options, key) is not None:
            config.set(key, getattr(options, key))
            
def main(argv=None):
    if argv is None:
        argv = sys.argv
    config = default_configuration()
    parser = OptionParser()
    parser.add_option("-i", "--input-directory", dest="input_directory", help="read raw images from INPUT_DIRECTORY")
    parser.add_option("-o", "--output-directory", dest="output_directory", help="write tiles to OUTPUT_DIRECTORY")
    parser.add_option("-p", "--processed-directory", dest="processed_directory", help="move raw images to PROCESSED_DIRECTORY after making tiles")
    parser.add_option("--no-move", action="store_false", dest="move_input_files", help="don't move raw images after making tiles")
    parser.add_option("--move", action="store_true", dest="move_input_files", help="move raw images after making tiles")
    parser.add_option("--no-delete", action="store_false", dest="delete_input_files", help="don't delete raw images after making tiles")
    parser.add_option("--delete", action="store_true", dest="delete_input_files", help="delete raw images after making tiles")
    parser.add_option("--file", dest="file", help="only process FILE instead of INPUT_DIRECTORY")
    parser.add_option("-v", "--verbose", action="store_true", dest="verbose", help="be verbose")
    parser.add_option("-q", "--quiet", action="store_false", dest="verbose", help="be quiet")
    (options, arguments) = parser.parse_args()
    handle_options(options)
    process()

if __name__ == "__main__":
    sys.exit(main())
