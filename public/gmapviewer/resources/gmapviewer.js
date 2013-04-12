function bound(value, opt_min, opt_max) {
  if (opt_min != null) value = Math.max(value, opt_min);
  if (opt_max != null) value = Math.min(value, opt_max);
  return value;
}

function degreesToRadians(deg) {
  return deg * (Math.PI / 180);
}

function radiansToDegrees(rad) {
  return rad / (Math.PI / 180);
}

function MercatorProjection() {
  var TILE_SIZE = 256;
  this.pixelOrigin_ = new google.maps.Point(TILE_SIZE / 2, TILE_SIZE / 2);
  this.pixelsPerLonDegree_ = TILE_SIZE / 360;
  this.pixelsPerLonRadian_ = TILE_SIZE / (2 * Math.PI);
}

MercatorProjection.prototype.fromLatLngToPoint = function(latLng, opt_point) {
  var me = this;
  var point = opt_point || new google.maps.Point(0, 0);
  var origin = me.pixelOrigin_;

  point.x = origin.x + latLng.lng() * me.pixelsPerLonDegree_;

  var siny = bound(Math.sin(degreesToRadians(latLng.lat())), -0.9999, 0.9999);
  point.y = origin.y + 0.5 * Math.log((1 + siny) / (1 - siny)) * -me.pixelsPerLonRadian_;
  return point;
};

MercatorProjection.prototype.fromPointToLatLng = function(point) {
  var me = this;
  var origin = me.pixelOrigin_;
  var lng = (point.x - origin.x) / me.pixelsPerLonDegree_;
  var latRadians = (point.y - origin.y) / -me.pixelsPerLonRadian_;
  var lat = radiansToDegrees(2 * Math.atan(Math.exp(latRadians)) - Math.PI / 2);
  return new google.maps.LatLng(lat, lng);
};

function TileSet() {
  var me = this;
  me.DEFAULT_MAX_ZOOM = 6;
  me.DEFAULT_PIXEL_DIMENSION = 256;
  
  me.initialize = function () {
    me.config = new GMapConfig();
    me.tiles = [];
    me.has_tiles = false;
    me.url = "";
    me.no_url = me.config.resources_url_prefix + "noimage256.jpg";
    me.path = "";
    me.name = "";
    me.format = "jpg";
    me.width = me.DEFAULT_PIXEL_DIMENSION;
    me.height = me.DEFAULT_PIXEL_DIMENSION;
    me.tile_size = me.DEFAULT_PIXEL_DIMENSION;
    me.max_zoom = me.DEFAULT_MAX_ZOOM;
    me.zoom_shift = me.DEFAULT_MAX_ZOOM;
  };

  me.add_tile = function (name, start, length) {
    me.tiles[name] = [start, length];
    me.has_tiles = true;
  };

  me.getNormalizedCoord = function (coord, zoom) {
    var y = coord.y;
    var x = coord.x;

    var tileRange = 1 << zoom;

    if (y < 0 || y >= tileRange) {
      return null;
    }

    if (x < 0 || x >= tileRange) {
      return null;
    }

    return {
      x: x,
      y: y
    };
  };

  me.getTileUrl = function (coord, zoom) {
    var normalizedCoord = me.getNormalizedCoord(coord, zoom);
    if (!normalizedCoord) {
      return me.no_url;
    }

    var tile = zoom + "_" + normalizedCoord.x + "_" + normalizedCoord.y + "." + me.format;

    if (me.has_tiles) {
      if (me.tiles[tile]) {
        var start = me.tiles[tile][0];
        var length = me.tiles[tile][1];
        var retval = me.no_url;
        if (length > 0) {
          retval = me.config.tile_url_prefix + "tile.php?Path=" + me.path + ".AND.Image=" + me.name + ".AND.Start=" + start + ".AND.Length=" + length + ".AND.Format=" + me.format;
        }
        return retval;
      }
      else {
        return me.no_url;
      }
    }
    else {
      return me.path + tile;
    }
  };

  me.initialize();
}

function TileSetParser(tile_set, callback) {
  var me = this;
  var imageXMLHttp = null;

  me.initialize = function () {
    me.tile_set = tile_set;
    me.callback = callback;
    me.config = new GMapConfig();
  };

  me.parse = function (url) {
    me.tile_set.url = url;
  
    if (window.ActiveXObject) {
      imageXMLHttp = new ActiveXObject("Microsoft.XMLHTTP");
    }
    else if (window.XMLHttpRequest) {
      imageXMLHttp = new XMLHttpRequest();
    }
    else {
      return false;
    }
  
    imageXMLHttp.open("GET", me.config.image_url_prefix + me.tile_set.url, true);
    imageXMLHttp.onreadystatechange = me.add_tiles;
    imageXMLHttp.send(null);

    return true;
  };

  me.add_tiles = function () {
    var i;
    var lines = [];
    var fields = [];

    if (imageXMLHttp.readyState == 4 && imageXMLHttp.status == 200) { 
      lines = imageXMLHttp.responseText.split(me.config.lineEnding);
      for(i = 0; i < lines.length; i++) {
        fields = lines[i].split("\t");
      
        // Tile positions:
        if(fields[0].indexOf(".") > 0) {
          var tile = fields[0];
          var start = parseInt(fields[1], 10);
          var length = parseInt(fields[2], 10);
          me.tile_set.add_tile(tile, start, length);
        }
        // General image metadata:
        else {
          switch(trim(fields[0])) {
            case "name": 
              me.tile_set.name = trim(fields[1]);
              break;
  
            case "width": 
              me.tile_set.width = parseInt(fields[1], 10);
              break;
  
            case "height": 
              me.tile_set.height = parseInt(fields[1], 10);
              break;
  
            case "maxzoom": 
              me.tile_set.max_zoom = parseInt(fields[1], 10); 
              break;
  
            case "tilesize": 
              me.tile_set.tile_size = parseInt(fields[1], 10); 
              break;
  
            case "format": 
              me.tile_set.format = trim(fields[1]); 
              break;
          }
        }
      }
    
      me.tile_set.path = me.tile_set.url.replace(me.tile_set.name + ".txt", "")
      imageXMLHttp = null;
      me.callback();
    }
    else {
      return false;
    }
  };

  me.initialize();
}

function BoundingBoxSet() {
  var me = this;

  me.initialize = function () {
    me.rectangles = [];
    me.overlays = [];
    me.visible_highlight = true;
  };

  me.toggle = function () {
    if(me.visible_highlight == true) {
      me.hideRectangles();      
      me.visible_highlight = false; 
    }  
    else {
      me.showRectangles(); 
      me.visible_highlight = true; 
    }
  };
 
  me.hideRectangles = function () {
    for (var i=0; i<me.overlays.length; i++) {
      me.overlays[i].setVisible(false);
    }
  };

  me.showRectangles = function () {
    for (var i=0; i<me.overlays.length; i++) {
      me.overlays[i].setVisible(true);
    }
  };

  me.addRectangle = function (rectangle) {
    me.rectangles[me.rectangles.length] = rectangle;
  };

  me.initialize();
}

function BoundingBox(coordinates) {
  var me = this;

  me.initialize = function() {
    me.width  = coordinates[0];
    me.height = coordinates[1];
    me.hpos   = coordinates[2];
    me.vpos   = coordinates[3];
  };

  me.initialize();
}

function GMapViewer(container) {
  var me = this;

  me.initialize = function () {
    me.container = container;
    me.map = null;

    me.tile_set = new TileSet();
    me.tile_set_parser = new TileSetParser(me.tile_set, me.showImage);
    me.bounding_box_set = new BoundingBoxSet();
  };

  me.setCopyright = function (type, copyright) { };

  me.loadImage = function (url) {
    return me.tile_set_parser.parse(url);
  };

  me.setDefaultZoom = function () {
    var container = document.getElementById(me.container);
    var tile_size = me.tile_set.tile_size;

   
    var ratio = container.offsetWidth / tile_size;
    ratio *= 0.8;

    me.default_zoom = Math.min(
      Math.ceil(Math.log(ratio) / Math.log(2)),
      me.tile_set.max_zoom);
  };

  me.showImage = function () {
    var container = document.getElementById(me.container);
    var tile_size = me.tile_set.tile_size;

    var ratio = container.offsetWidth / tile_size;
    ratio *= 0.8;

    me.default_zoom = Math.min(
      Math.ceil(Math.log(ratio) / Math.log(2)),
      me.tile_set.max_zoom);

    var imageTypeOptions = {
      getTileUrl: me.tile_set.getTileUrl,
      tileSize: new google.maps.Size(tile_size, tile_size),
      maxZoom: me.tile_set.max_zoom,
      minZoom: me.default_zoom,
      name: "Image"
    };

    var imageType = new google.maps.ImageMapType(imageTypeOptions);

    me.projection = new MercatorProjection();
    var zoom_scale = 1 << me.tile_set.max_zoom;
    var center = new google.maps.Point(
      (me.tile_set.width / 2) / zoom_scale,
      (me.tile_set.height / 2) / zoom_scale);
    var myLatLng = me.projection.fromPointToLatLng(center);
    var centerLat = myLatLng.lat();
    var centerLon = myLatLng.lng();

    var tolerance = -Math.min(me.tile_set.width / 8, me.tile_set.height / 8);
    var sw_corner = new google.maps.Point(
      -tolerance / zoom_scale,
      (me.tile_set.height + tolerance) / zoom_scale);

    var ne_corner = new google.maps.Point(
      (me.tile_set.width + tolerance) / zoom_scale,
      -tolerance / zoom_scale);

    var sw_latlng = me.projection.fromPointToLatLng(sw_corner);
    var ne_latlng = me.projection.fromPointToLatLng(ne_corner);

    var mapOptions = {
      center: myLatLng,
      zoom: me.default_zoom,
      mapTypeControlOptions: {
        mapTypeIds: ["image"]
      },
      disableDefaultUI: true,
      panControl: true,
      zoomControl: true
    };
    me.map = new google.maps.Map(container, mapOptions);
    me.map.mapTypes.set('image', imageType);
    me.map.setMapTypeId('image');

    var allowedBounds = new google.maps.LatLngBounds(sw_latlng, ne_latlng);
    var lastValidCenter = me.map.getCenter();

    google.maps.event.addListener(me.map, 'resize', function () {
      me.setDefaultZoom();
      me.map.mapTypes[me.map.getMapTypeId()].minZoom = me.default_zoom;
      me.map.set('minZoom', me.default_zoom);
      me.map.setZoom(Math.max(me.map.getZoom(), me.default_zoom));
    });

    google.maps.event.addListener(me.map, 'bounds_changed', function () {
      if (allowedBounds.contains(me.map.getCenter())) {
        lastValidCenter = me.map.getCenter();
        return;
      }

      me.map.panTo(lastValidCenter);
    });

    me.fullscreen_control_div = document.createElement('div');
    me.fullscreen_control = new FullScreenControl(me.fullscreen_control_div);
    me.fullscreen_control_div.index = 1;
    me.map.controls[google.maps.ControlPosition.TOP_RIGHT].push(me.fullscreen_control_div);
    google.maps.event.addDomListener(me.fullscreen_control_div, "click", function () {
      toggleFSControl(me.fullscreen_control, me.map);
    });
    Mousetrap.bind("esc", function () {
      if (fs) {
        toggleFSControl(me.fullscreen_control, me.map);
      }
      return false;
    });

    if (me.wants_alto) {
      me.highlighter_control_div = document.createElement('div');
      me.highlighter_control = new HighlighterControl(me.highlighter_control_div);
      me.highlighter_control_div.index = 1;
      me.map.controls[google.maps.ControlPosition.RIGHT_TOP].push(me.highlighter_control_div);
      google.maps.event.addDomListener(me.highlighter_control_div, "click", function() {
        me.bounding_box_set.toggle();
      });

      me.drawRectangles();
    }
  };

  me.drawRectangles = function () {
    if (me.bounding_box_set.rectangles && me.bounding_box_set.rectangles.length > 0) {
      var i;
      for (i=0; i<me.bounding_box_set.rectangles.length; i++) {
        var coordinates  = me.bounding_box_set.rectangles[i];
        var bounding_box = new BoundingBox(coordinates);

        var zoom = me.map.getZoom();
        var scale = 1 << me.tile_set.max_zoom;

        var sw_point = new google.maps.Point(bounding_box.hpos / scale, bounding_box.vpos / scale);
        var ne_point = new google.maps.Point(
          (bounding_box.hpos + bounding_box.width) / scale,
          (bounding_box.vpos + bounding_box.height) / scale);

        var sw_latlng = me.projection.fromPointToLatLng(sw_point);
        var ne_latlng = me.projection.fromPointToLatLng(ne_point);

        var overlay = new google.maps.Rectangle({
          strokeColor: "#f3f781",
          strokeOpacity: 0.8,
          strokeWeight: 2,
          fillColor: "#f3f781",
          fillOpacity: 0.35,
          map: me.map,
          bounds: new google.maps.LatLngBounds(sw_latlng, ne_latlng)
        });
        me.bounding_box_set.overlays[me.bounding_box_set.overlays.length] = overlay;
      }
    }
  };

  // public
  me.addRectangle = function (rectangle) {
    me.bounding_box_set.addRectangle(rectangle);
  };

  me.initialize();
}

/*----------------------------*/

function HighlighterControl(container) {
  var me = this;

  me.initialize = function () {
    me.config = new GMapConfig();
    me.div = container; //document.createElement('div');
    me.div.style.padding = '20px';
    me.controlUI = document.createElement('img');
    // highlighter_yellow_32.png is a modified version of http://upload.wikimedia.org/wikipedia/commons/0/06/Crystal_Project_highlight.png,
    // licensed under LGPL.
    me.controlUI.src = me.config.resources_url_prefix + "highlighter_yellow_32.png";
    me.controlUI.alt = "Toggle highlighting";
    me.controlUI.title = "Toggle highlighting";
    me.div.appendChild(me.controlUI);
  };

  me.initialize();
}

var fs = false;
function FullScreenControl(container) {
  var me = this;

  me.initialize = function () {
    me.config = new GMapConfig();
    me.fullscreen = 0;
    me.images = [ "expand.png", "contract.png" ];
    me.div = container; //document.createElement('div');
    me.div.style.padding = '20px';
    me.controlUI = document.createElement('img');
    // highlighter_yellow_32.png is a modified version of http://upload.wikimedia.org/wikipedia/commons/0/06/Crystal_Project_highlight.png,
    // licensed under LGPL.
    me.controlUI.src = me.config.resources_url_prefix + me.images[me.fullscreen];
    me.controlUI.alt = "Toggle highlighting";
    me.controlUI.title = "Toggle highlighting";
    me.div.appendChild(me.controlUI);
  };

  me.toggleIcon = function () {
    me.fullscreen = 1 - me.fullscreen;
    me.controlUI.src = me.config.resources_url_prefix + me.images[me.fullscreen];
  };

  me.initialize();
}

function toggleFSControl (me, map) {
  var previousPosition = map.getCenter();
  me.toggleIcon();
  toggleFullScreen();
  map.setCenter(previousPosition);
}

function toggleFullScreen(obj) {
  if (fs) {
    elt = $('#fs_viewer').detach();
    elt.appendTo('#image_viewer');
    $('#fs_viewer').removeClass('overlay').addClass('onpage').css({'position': 'relative'});
    $('#fs_viewer .fs_pagination').toggle();
    if (viewer && viewer.map) {
      google.maps.event.trigger(viewer.map, "resize");
    }
    fsOFF();
    fs = false;
  }
  else {
    elt = $('#fs_viewer').detach();
    elt.appendTo('body');
    $('#fs_viewer').removeClass('onpage').addClass('overlay').css({'position': 'absolute'});
    $('#fs_viewer .fs_pagination').toggle();
    if (viewer && viewer.map) {
      google.maps.event.trigger(viewer.map, "resize");
    }
    fsON();
    fs = true;
  }
}

/*----------------------------*/

// A little helper function to trim strings (Javascript doesn't have a built-in trim method):
function trim(str) {
  var str = str.replace(/^\s\s*/, ''),
      ws = /\s/,
      i = str.length;
  while(ws.test(str.charAt(--i)));
  return str.slice(0, i + 1);
}
