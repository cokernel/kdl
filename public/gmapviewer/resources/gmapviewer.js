// GMapViewer:
// Represents and instance of the viewer, based on Google Maps API, with a custom projection and custom tile layers corresponding to the image.


function GMapViewer(container)
{
  // "me" refers to the actual instance of this object for use in callback functions
  // (in callbacks, "this." notation will not work)
  // (note: "me" must be declared as "var me", not as "this.me")
  var me = this;

  me.container = container;  // Points to the HTML element (e.g., <div>) that will hold the viewer.
  me.map = null; //the GMap2 object itself.
  me.config    = new GMapConfig();
  me.rectangles = [];
  
  me.objectType = "Image";  // Will show up on copyright text along bottom of viewer.
  var today = new Date()
  me.copyrightText = "&copy; " + today.getFullYear();  // Will show up on copyright text along bottom of viewer.

  me.projection = null;  // Will hold a custom projection that maps image pixels and tiles to latitude longitude
  me.zoomShift = 6;  // Used to shift the initial view of the image to a higher zoom level, creating a buffer of empty tiles around the image.

  me.centerLat = -90 / me.zoomShift / 3;  // Position of the center of the image, in degrees latitude.
  me.centerLon = 180 / me.zoomShift / 3;  // Position of the center of the image, in degrees longitude.
  me.initialZoom = me.zoomShift + 2;  // Initial zoom level at which to display the image (+2 provides a good initial image size)
  me.imageWraps = false;  // Set to false to prevent the image from wrapping if the user scrolls too far to the left or right.
  
  // Parameters holding image metadata:
  me.validImage = false;
  me.noImageURL = me.config.resources_url_prefix + "noimage256.jpg";
  me.imageURL = "";
  me.imagePath = "";
  me.imageName = "";
  me.imageWidth = 256;  // Width and height are in pixels
  me.imageHeight = 256;
  me.imageMaxZoom = me.zoomShift;
  me.imageTileSize = 256;  // In pixels
  me.imageScale = 270;  // pixels per imageScaleUnit
  me.imageScaleUnit = "in";
  me.imageFormat = "jpg";
  me.tileListPresent = false;
  me.imageTiles = Array();
  
  // Will hold an instance of the measuring ruler.
  me.ruler = null;
  
  // Holds an instance of the drag zoom control:
  me.dragZoom = null;
  
  // Holds request for image metadata file (must be declared as "var imageXMLHttp", not "me.imageXMLHttp")
  var imageXMLHttp = null;

  me.overlays = Array();
  me.visible_highlight = true;
   
  me.setCopyright = function(type, copyright)
  {
    me.objectType = type;
    me.copyrightText = copyright;
  };

  // Initiate an HTTP XML request for the image metadata file:
  me.loadImage = function(url)
  {
    me.imageURL = url;
  
    if (window.ActiveXObject) imageXMLHttp = new ActiveXObject("Microsoft.XMLHTTP");
    else if (window.XMLHttpRequest) imageXMLHttp = new XMLHttpRequest();
    else return false;
  
    imageXMLHttp.open("GET", '/nyx.php?href=' + me.imageURL, true);
    imageXMLHttp.onreadystatechange = me.readImage;
    imageXMLHttp.send(null);

    return true;
  };

  // This is called once the HTTP XML request has finished loading the image metadata file:
  // Reads data from the metadata file and parses it into the image metadata fields.
  me.readImage = function()
  {
    if(imageXMLHttp == undefined || imageXMLHttp == null) return false;
    if(imageXMLHttp.readyState != 4) return false;
    if(imageXMLHttp.responseText == "") return false;
  
    var s = Array();
    var p = Array();
  
    s = imageXMLHttp.responseText.split(me.config.lineEnding);
    for(i = 0; i < s.length; i++)
    {
      p = s[i].split("\t");
    
      // Tile positions:
      if(p[0].indexOf(".") > 0)
      {
        me.tileListPresent = true;
        me.imageTiles[p[0]] = new Array(parseInt(p[1]), parseInt(p[2]));
      }
      // General image metadata:
      else
      {
        switch(trim(p[0]))
        {
          case "name": me.imageName = trim(p[1]); break;
          case "width": me.imageWidth = parseInt(p[1]); break;
          case "height": me.imageHeight = parseInt(p[1]); break;
          case "maxzoom": me.imageMaxZoom = parseInt(p[1]); break;
          case "tilesize": me.imageTileSize = parseInt(p[1]); break;
          case "scale": me.imageScale = parseInt(p[1]); break;
          case "scaleunit": me.imageScaleUnit = trim(p[1]); break;
          case "format": me.imageFormat = trim(p[1]); break;
        }
      }
    }
  
    // Make sure we have a valid width and height:
    if(me.imageWidth > 0 && me.imageHeight > 0) me.validImage = true;
  
    me.imagePath = me.imageURL.replace(me.imageName + ".txt", "")
    
    imageXMLHttp = null;
    
    // Now that the image medatada is loaded, display the image:
    me.showImage();
  };

  // Create an instance of the Google Map (GMap2), assign it a custom projection and map type, add custom controls, and show the image:
  me.showImage = function()
  {
    var copyright = new GCopyright(1, new GLatLngBounds(new GLatLng(-90, -180), new GLatLng(90, 180)), 0, me.copyrightText);
    var copyrightCollection = new GCopyrightCollection(me.objectType);
    copyrightCollection.addCopyright(copyright);
    
    //create a custom picture layer
    var pic_tileLayers = [ new GTileLayer(copyrightCollection, 0, 18)];
    pic_tileLayers[0].getTileUrl = me.getTileURL;
    pic_tileLayers[0].isPng = function() { return false; };
    pic_tileLayers[0].getOpacity = function() { return 1.0; };
    
    me.projection = new CustomProjection(18, me.imageWraps, me.imageTileSize);  // Max zoom must be set to 18 or polylines and polygons won't display
    
    var pic_customMap = new GMapType(pic_tileLayers, me.projection, "Pic", {minResolution:me.zoomShift, maxResolution:(me.zoomShift+me.imageMaxZoom), errorMessage:"Data not available"});
   
    pic_customMap.getMinimumResolution = function() { return me.zoomShift; }
    pic_customMap.getMaximumResolution = function() { return me.zoomShift+me.imageMaxZoom; } 

    //Now create the custom map. Would normally be G_NORMAL_MAP,G_SATELLITE_MAP,G_HYBRID_MAP
    me.map = new GMap2(document.getElementById(me.container), {backgroundColor: "#000000", mapTypes:[pic_customMap]});
    
    var topRight = new GControlPosition(G_ANCHOR_TOP_RIGHT, new GSize(10,10));
    // me.map.addControl(new ViewerControl(me));
    me.map.addControl(new GLargeMapControl3D());
    me.map.addControl(new ViewerControl(me));
    me.map.addControl(new FullScreenControl(me));
 
    me.map.enableDoubleClickZoom();
    me.map.enableContinuousZoom();
    me.map.enableScrollWheelZoom();
    me.map.enableRotation(); 
       
 
    me.centerLat = ((me.imageHeight / Math.pow(2,me.imageMaxZoom)) / 2 / 256) * (-90 / Math.ceil(Math.pow(2,me.zoomShift-1)));
    me.centerLon = ((me.imageWidth / Math.pow(2,me.imageMaxZoom)) / 2 / 256) * (180 / Math.ceil(Math.pow(2,me.zoomShift-1)));
    me.map.setCenter(new GLatLng(me.centerLat, me.centerLon), me.initialZoom, pic_customMap);

 
    me.ruler = new Ruler(me);
    me.ruler.setInCenter();
    me.ruler.setIcon(me.config.resources_url_prefix + "Crosshairs25_transparent.png", me.config.resources_url_prefix + "Crosshairs25_transparent.png", 25, 25);
    me.ruler.setLine("#FFFF00", 2, 1);
    me.drawRectangles();
 
  };



   me.toggle = function()
  {
    if(me.visible_highlight == true)
    {
       me.hideRectangles();      
       me.visible_highlight = false; 
    }  
    else 
    {
       me.showRectangles(); 
       me.visible_highlight = true; 
    }
  };
 
  
  me.hideRectangles = function()
  {
    for (var i=0; i<me.overlays.length; i++) {
      me.overlays[i].hide();
    }
  };

  me.showRectangles = function()
  {
    for (var i=0; i<me.overlays.length; i++) {
      me.overlays[i].show();
    }
  };

  me.drawRectangles = function()
  {
    if (me.rectangles && me.rectangles.length > 0) {
      var i;
      for (i=0; i<me.rectangles.length; i++) {
        var coordinates  = me.rectangles[i];
        var ocrBoxWidth  = coordinates[0];
        var ocrBoxHeight = coordinates[1];
        var ocrBoxHpos   = coordinates[2];
        var ocrBoxVpos   = coordinates[3];

        /* Find corners of image */
        var zoom   = me.map.getZoom() - 2; 
        if (me.imageMaxZoom === 6) {
          zoom   = me.map.getZoom() - 1; 
        }
        var center = me.map.getCenter();
        var dlat   = ((me.imageHeight / 2) / (256 * Math.pow(2, zoom))) * (180 / Math.ceil(Math.pow(2, me.zoomShift - 1)));
        var dlng   = ((me.imageWidth / 2) / (256 * Math.pow(2, zoom))) * (360 / Math.ceil(Math.pow(2, me.zoomShift - 1)));

        var sw_image_latlng = new GLatLng( center.lat() - dlat, center.lng() - dlng );
        var ne_image_latlng = new GLatLng( center.lat() + dlat, center.lng() + dlng );

        var sw_image_point  = me.projection.fromLatLngToPixel(sw_image_latlng, zoom);
        var ne_image_point  = me.projection.fromLatLngToPixel(ne_image_latlng, zoom);

        var pixelWidth      = Math.abs(ne_image_point.x - sw_image_point.x);
        var pixelHeight     = Math.abs(ne_image_point.y - sw_image_point.y);

        /* Set corners of OCR/highlight box */
        var sw_ocrBox_point = new GPoint(
          ocrBoxHpos                  * pixelWidth / me.imageWidth   + sw_image_point.x,
          (ocrBoxVpos + ocrBoxHeight) * pixelHeight / me.imageHeight + ne_image_point.y
        );

        var ne_ocrBox_point = new GPoint(
          (ocrBoxHpos + ocrBoxWidth) * pixelWidth / me.imageWidth    + sw_image_point.x,
          ocrBoxVpos                 * pixelHeight / me.imageHeight  + ne_image_point.y
        );

        var sw_ocrBox_latlng = me.projection.fromPixelToLatLng(sw_ocrBox_point, zoom);
        var ne_ocrBox_latlng = me.projection.fromPixelToLatLng(ne_ocrBox_point, zoom);
        var ocrBoxBounds = new GLatLngBounds(sw_ocrBox_latlng, ne_ocrBox_latlng);
        var overlay = new Rectangle(ocrBoxBounds);
        me.overlays[me.overlays.length] = overlay;
        me.map.addOverlay(overlay);
      }
    }
  };

  me.addRectangle = function(rectangle)
  {
    me.rectangles[me.rectangles.length] = rectangle;
  };

  // Custom function to convert the Google Map tile parameters into a URL request to tile.php:
  me.getTileURL = function(a, b)
  {
    // b: zoom level, starting at GMapVeiwer.zoomShift
    // a: tile position (a.x, a.y)

    if(!me.tileListPresent)
    {
      var w = Math.ceil(me.imageWidth / Math.pow(2,me.imageMaxZoom-b) / me.imageTileSize);
      var h = Math.ceil(me.imageHeight / Math.pow(2,me.imageMaxZoom-b) / me.imageTileSize);
      if(a.x > w || a.y > h) return me.noImageURL;
    }
    
    a.x = a.x - Math.floor(Math.pow(2,b-1));  // Shift the tile from (-180,90) to (0,0) degrees lat/lon
    a.y = a.y - Math.floor(Math.pow(2,b-1));  // ditto
    b = b - me.zoomShift;  // Shift the zoom to account for zoomShift.
        
    if(b < 0 || b > me.imageMaxZoom) return me.noImageURL;
    if(a.x < 0 || a.y < 0) return me.noImageURL;
    
    var tile = b + "_" + a.x + "_" + a.y + "." + me.imageFormat;
    
    if(me.tileListPresent)
    {
      // Request tile btyes from within .tls file:
      if(me.imageTiles[tile])
      {
        var start = me.imageTiles[tile][0];
        var length = me.imageTiles[tile][1];
        var retval = me.noImageURL;
        if(length > 0) { 
          retval = me.config.tile_url_prefix + "tile.php?Path=" + me.imagePath + ".AND.Image=" + me.imageName + ".AND.Start=" + start + ".AND.Length=" + length + ".AND.Format=" + me.imageFormat;
        }
        return retval;
      }
      else return me.noImageURL;
    }
    else
    {
      // Request a precreated, static tile file:
      return me.imagePath + tile;
    }
  };
}

/*----------------------------*/

// Custom viewer control with zoom buttons, home button, and ruler button:
function ViewerControl(parent)
{
  var me = this;
  
  var parentObj = parent;
  me.config     = new GMapConfig();

  me.initialize = function(map)
  {
    var container = document.createElement("div");

    if (parentObj.wants_alto) {
      var rulerBtn = document.createElement("img");
      // highlighter_yellow_32.png is a modified version of http://upload.wikimedia.org/wikipedia/commons/0/06/Crystal_Project_highlight.png,
      // licensed under LGPL.
      rulerBtn.src = me.config.resources_url_prefix + "highlighter_yellow_32.png";
      rulerBtn.alt = "Toggle highlighting";
      me.setButtonStyle(rulerBtn);
      container.appendChild(rulerBtn);
      GEvent.addDomListener(rulerBtn, "click", function() {
      parentObj.toggle();
      });
    }
  
    // Drag zoom button options:
    // First set of options is for the visual overlay
    var boxStyleOpts = {
      opacity: .2,
      border: "2px solid red"
    }
    // Second set of options is for everything else
    var otherOpts = {
      buttonHTML: "<img src='" + me.config.resources_url_prefix + "spacer.gif' />",
      buttonZoomingHTML: "<img src='images/spacer.gif' />",
      buttonStartingStyle: {width: '1px', height: '1px', border: '0px solid #000000', background: 'none'},
      buttonStyle: {width: '1px', height: '1px'},
      buttonZoomingStyle: {width: '1px', height: '1px'},
      overlayRemoveTime: 1000
    };
    // Third set of options specifies callbacks (no callbacks in this case)
    var callbacks = {
    };
    
    parentObj.dragZoom = new DragZoomControl(boxStyleOpts, otherOpts, callbacks);
    parentObj.map.addControl(parentObj.dragZoom);
  
    parentObj.map.getContainer().appendChild(container);
   return container;
  };

  me.getDefaultPosition = function()
  {
    return new GControlPosition(G_ANCHOR_TOP_RIGHT, new GSize(4, 48));
  };

  me.setButtonStyle = function(button)
  {
    button.style.width = "32px";
    button.style.height = "32px";
    button.style.margin = "2px";
    button.style.cursor = "pointer";
  };
}

ViewerControl.prototype = new GControl();

function toggleFSControl(me, map) {
  map.savePosition();
  me.toggleIcon();
  toggleFullScreen();
  map.returnToSavedPosition();
}

var fs = false;
function FullScreenControl(parent)
{
  var me = this;
  
  var parentObj = parent;
  var position  = 0;
  var urls = ['expand.png', 'contract.png'];
  var icon;
  me.config     = new GMapConfig();

  me.initialize = function(map)
  {
    var container = document.createElement("div");

    var fullScreenDiv = document.createElement("div");

    icon = document.createElement("img");
    icon.setAttribute('src', me.config.resources_url_prefix + 'expand.png');

    me.setButtonStyle(fullScreenDiv);

    fullScreenDiv.appendChild(icon);
    GEvent.addDomListener(fullScreenDiv, "click", function () {
      toggleFSControl(me, map);
    });

    Mousetrap.bind("esc", function () {
      if (fs) {
        toggleFSControl(me, map);
      }
      return false;
    });

    map.toggleFSControl = function () {
      toggleFSControl(me, map);
    }

    parentObj.map.getContainer().appendChild(fullScreenDiv);
    return fullScreenDiv;
  };

  me.getDefaultPosition = function()
  {
    return new GControlPosition(G_ANCHOR_TOP_RIGHT, new GSize(4, 4));
  };

  me.setButtonStyle = function(button)
  {
    button.style.width = "32px";
    button.style.height = "32px";
    button.style.margin = "2px";
    button.style.cursor = "pointer";
  };

  me.toggleIcon = function () {
    position = 1 - position;
    var url = me.config.resources_url_prefix + urls[position];
    icon.setAttribute('src', url);
  }
}

FullScreenControl.prototype = new GControl();

function toggleFullScreen(obj) {
  if (fs) {
    elt = $('#fs_viewer').detach();
    elt.appendTo('#image_viewer');
    $('#fs_viewer').removeClass('overlay').addClass('onpage').css({'position': 'relative'});
    $('#fs_viewer .fs_pagination').toggle();
    if (viewer && viewer.map) {
      viewer.map.checkResize();
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
      viewer.map.checkResize();
    }
    fsON();
    fs = true;
  }
}

/*----------------------------*/

// Custom projection:
//
// At zoom level 0:
//   1 tile width = 256 pixels = -180 to 180 degrees longitude.
//   1 tile height = 256 pixels = 90 to -90 degrees latitude.
// At higher zoom levels, divide lat/lon size by 2 for each unit increase in zoom level.
//
function CustomProjection(maxZoom, wrap, tileSize)
{
  this.imageDimension = 65536;
  this.pixelsPerLonDegree = [];
  this.pixelOrigin = [];
  this.tileBounds = [];
  if(tileSize > 1) this.tileSize = tileSize;
  else this.tileSize = 256;
  this.isWrapped = wrap;
  var c = 1;
  for(var z = 0; z < maxZoom; z++)
  {
    var e = this.tileSize/2;
    this.pixelsPerLonDegree.push(this.tileSize/360);
    this.pixelOrigin.push(new GPoint(e,e));
    this.tileBounds.push(c);
    this.tileSize *= 2;
    c *= 2;
  }
}

CustomProjection.prototype = new GProjection();

CustomProjection.prototype.fromLatLngToPixel = function(latlng, zoom)
{
  var x = Math.round(this.pixelOrigin[zoom].x + latlng.lng() * this.pixelsPerLonDegree[zoom]);
  var y = Math.round(this.pixelOrigin[zoom].y + (-2 * latlng.lat()) * this.pixelsPerLonDegree[zoom]);
  return new GPoint(x, y);
};

CustomProjection.prototype.fromPixelToLatLng = function(pixel, zoom, unbounded)
{
  var lon = (pixel.x - this.pixelOrigin[zoom].x) / this.pixelsPerLonDegree[zoom];
  var lat = -0.5 * (pixel.y - this.pixelOrigin[zoom].y) / this.pixelsPerLonDegree[zoom];
  return new GLatLng(lat, lon, unbounded);
};

CustomProjection.prototype.tileCheckRange = function(tile, zoom, tilesize)
{
  var tileBounds = this.tileBounds[zoom];
  if(tile.y < 0 || tile.y >=  tileBounds) return false;
  if(this.isWrapped)
  {
    if(tile.x < 0 || tile.x >= tileBounds)
    { 
      tile.x = tile.x % tileBounds; 
      if(tile.x < 0) tile.x += tileBounds;
    }
  }
  else
  { 
    if(tile.x < 0 || tile.x >= tileBounds) return false;
  }  
  return true;
}

CustomProjection.prototype.getWrapWidth = function(zoom)
{
  return this.tileBounds[zoom] * this.tileSize;
}

/*----------------------------*/

// The measuring ruler:
//
function Ruler(parent)
{
  var me = this;
  
  var parentObj = parent;
  me.config     = new GMapConfig();
  
  me.created = false;
  me.visible = false;
  
  me.end1 = null;
  me.end2 = null;
  me.end1Pos = null;
  me.end2Pos = null;
  me.endMove = null;
  me.endIcon = me.config.resources_url_prefix + "Crosshairs25_blue.png";
  me.endIconTransparent = me.config.resources_url_prefix + "Crosshairs25_transparent.png";
  me.endIconWidth = 25;
  me.endIconHeight = 25;
  me.polyline = null;
  me.label = null;
  me.lineColor = "#FFFF00";
  me.lineWidth = 2;
  me.lineOpacity = 1;
  me.scale = parentObj.imageScale;
  me.scaleUnit = parentObj.imageScaleUnit;
  
  me.labelStyles = "position: absolute; padding: 0px 1px 0px 1px; border: 1px solid #0F5499; background-color: #EEEEEE; font: 8pt Arial, Helvetica, sans-serif; white-space: nowrap;";

  me.setIcon = function(icon, iconTransparent, width, height)
  {
    me.endIcon = icon;
    me.endIconTransparent = iconTransparent;
    me.endIconWidth = width;
    me.endIconHeight = height;
  };

  me.setLine = function(color, width, opacity)
  {
    me.lineColor = color;
    me.lineWidth = width;
    me.lineOpacity = opacity;
  };

  me.setScale = function(scale, unit)
  {
    me.scale = scale;
    me.scaleUnit = unit;
  };

  me.setPosition = function(e1, e2)
  {
    me.end1Pos = e1;
    me.end2Pos = e2;
  };

  me.setInCenter = function()
  {
    var center = parentObj.map.getCenter();
    var d = Math.pow(2,parentObj.map.getZoom());
    var end1Lat = center.lat() + (90 / d);
    var end2Lat = center.lat() - (90 / d);
    var end1Lng = center.lng() - (180 / d);
    var end2Lng = center.lng() + (180 / d);
  
    me.end1Pos = new GLatLng(end1Lat, end1Lng);
    me.end2Pos = new GLatLng(end2Lat, end2Lng);
  
    if(me.created)
    {
      me.end1.setLatLng(me.end1Pos);
      me.end2.setLatLng(me.end2Pos);
      parentObj.map.removeOverlay(me.polyline);
      me.polyline = new GPolyline([me.end1Pos, me.end2Pos], me.lineColor, me.lineWidth, me.lineOpacity);
      parentObj.map.addOverlay(me.polyline);
      if(me.visible = false) me.polyline.hide();
      me.label.setContents(me.getMeasure() + " " + me.scaleUnit);
      me.label.div_.firstChild.setAttribute("style",me.labelStyles);
      var labelPos = new GLatLng((me.end1Pos.lat() + me.end2Pos.lat())/2, (me.end1Pos.lng() + me.end2Pos.lng())/2);
      me.label.setPoint(labelPos);
    }
  };

  me.show = function()
  {
    if(me.created)
    {
      me.end1.show();
      me.end2.show();
      me.polyline.show();
      me.label.show();
    }
    else
    {
      if(me.end1Pos == null || me.end2Pos == null) me.setInCenter();
    
      // Ruler end icon:
      rulerIcon = new GIcon();
      rulerIcon.iconSize = new GSize(me.endIconWidth, me.endIconHeight);
      rulerIcon.iconAnchor = new GPoint(Math.floor(me.endIconWidth/2-1), Math.ceil(me.endIconHeight/2+1));
      rulerIcon.infoWindowAnchor = new GPoint(Math.ceil(me.endIconWidth/2), 2);
      rulerIcon.image = me.endIcon;
    
      me.endMove = new GMarker(me.end1Pos, {icon: rulerIcon});
      parentObj.map.addOverlay(me.endMove);
      me.endMove.hide();
    
      me.end1 = new GMarker(me.end1Pos, {icon: rulerIcon, draggable: true, bouncy: false});  // , dragCrossMove: true
      GEvent.bind(me.end1, "dragstart", this, me.end1dragStart); 
      GEvent.bind(me.end1, "drag", this, me.end1drag);
      GEvent.bind(me.end1, "dragend", this, me.end1dragStop);
      parentObj.map.addOverlay(me.end1);
    
      me.end2 = new GMarker(me.end2Pos, {icon: rulerIcon, draggable: true, bouncy: false});  // , dragCrossMove: true
      GEvent.bind(me.end2, "dragstart", this, me.end2dragStart);
      GEvent.bind(me.end2, "drag", this, me.end2drag);
      GEvent.bind(me.end2, "dragend", this, me.end2dragStop);
      parentObj.map.addOverlay(me.end2);
    
      me.polyline = new GPolyline([me.end1Pos, me.end2Pos], me.lineColor, me.lineWidth, me.lineOpacity);
      parentObj.map.addOverlay(me.polyline);
  
      var labelPos = new GLatLng((me.end1Pos.lat() + me.end2Pos.lat())/2, (me.end1Pos.lng() + me.end2Pos.lng())/2);
      me.label = new ELabel(labelPos, me.getMeasure() + " " + me.scaleUnit, null, new GSize(-20,-8));
      parentObj.map.addOverlay(me.label);
      // Dynamically set styles so we don't have to statically link an external style sheet just for the viewer:
      me.label.div_.firstChild.setAttribute("style", me.labelStyles);
      me.label.redraw(true);
      
      me.created = true;
    }
  
    me.visible = true;
  };

  me.hide = function()
  {
    if(me.created == true)
    {
      me.end1.hide();
      me.end2.hide();
      me.endMove.hide();
      me.polyline.hide();
      me.label.hide();
    }
  
    me.visible = false;
  };

  me.toggle = function()
  {
    var bounds = parentObj.map.getBounds();
    if(me.visible && (bounds.containsLatLng(me.end1Pos) || bounds.containsLatLng(me.end2Pos)))
    {
      me.hide();
    }
    else
    {
      me.setInCenter();
      me.show();
    }
  };

  me.getMeasure = function()
  {
    // Adjust the measurement to account for zoomShift:
    e1 = parentObj.projection.fromLatLngToPixel(me.end1Pos, parentObj.imageMaxZoom + parentObj.zoomShift);
    e2 = parentObj.projection.fromLatLngToPixel(me.end2Pos, parentObj.imageMaxZoom + parentObj.zoomShift);
    return Math.round(Math.sqrt((e2.x - e1.x)*(e2.x - e1.x) + (e2.y - e1.y)*(e2.y - e1.y)) / me.scale * 100) / 100;
  };

  me.end1dragStart = function(latLng)
  {
    me.end1.setImage(me.endIconTransparent);
    me.endMove.setLatLng(latLng);
    me.endMove.show();
    me.label.hide();
  };

  me.end1drag = function(latLng)
  {
    me.end1Pos = latLng;
    me.endMove.setLatLng(latLng);
    parentObj.map.removeOverlay(me.polyline);
    me.polyline = new GPolyline([me.end1Pos, me.end2Pos], me.lineColor, me.lineWidth, me.lineOpacity);
    parentObj.map.addOverlay(me.polyline);
  };

  me.end1dragStop = function(latLng)
  {
    me.endMove.hide();
    parentObj.map.removeOverlay(me.polyline);
    me.polyline = new GPolyline([me.end1Pos, me.end2Pos], me.lineColor, me.lineWidth, me.lineOpacity);
    parentObj.map.addOverlay(me.polyline);
    me.label.setContents(me.getMeasure() + " " + me.scaleUnit);
    me.label.div_.firstChild.setAttribute("style",me.labelStyles);
    var labelPos = new GLatLng((me.end1Pos.lat() + me.end2Pos.lat())/2, (me.end1Pos.lng() + me.end2Pos.lng())/2);
    me.label.setPoint(labelPos);
    me.label.show();
    me.end1.setImage(me.endIcon);
  };

  me.end2dragStart = function(latLng)
  {
    me.end2.setImage(me.endIconTransparent);
    me.endMove.setLatLng(latLng);
    me.endMove.show();
    me.label.hide();
  };

  me.end2drag = function(latLng)
  {
    me.end2Pos = latLng;
    me.endMove.setLatLng(latLng);
    parentObj.map.removeOverlay(me.polyline);
    me.polyline = new GPolyline([me.end1Pos, me.end2Pos], me.lineColor, me.lineWidth, me.lineOpacity);
    parentObj.map.addOverlay(me.polyline);
  };

  me.end2dragStop = function(latLng)
  {
    me.endMove.hide();
    parentObj.map.removeOverlay(me.polyline);
    me.polyline = new GPolyline([me.end1Pos, me.end2Pos], me.lineColor, me.lineWidth, me.lineOpacity);
    parentObj.map.addOverlay(me.polyline);
    me.label.setContents(me.getMeasure() + " " + me.scaleUnit);
    me.label.div_.firstChild.setAttribute("style",me.labelStyles);
    var labelPos = new GLatLng((me.end1Pos.lat() + me.end2Pos.lat())/2, (me.end1Pos.lng() + me.end2Pos.lng())/2);
    me.label.setPoint(labelPos);
    me.label.show();
    me.end2.setImage(me.endIcon);
  };
}

/*----------------------------*/

// A little helper function to trim strings (Javascript doesn't have a built-in trim method):
function trim(str)
{
  var str = str.replace(/^\s\s*/, ''),
      ws = /\s/,
      i = str.length;
  while(ws.test(str.charAt(--i)));
  return str.slice(0, i + 1);
}

function autoRotate() {  
  // Determine if we're showing aerial imagery   
  if (map.isRotatable) {     
  // start auto-rotating at 3 second intervals     
    setTimeout('map.changeHeading(90)', 3000);     
    setTimeout('map.changeHeading(180)',6000);     
    setTimeout('map.changeHeading(270)',9000);     
    setTimeout('map.changeHeading(0)',12000);   
  } 
}

// A Rectangle is a simple overlay that outlines a lat/lng bounds on the
// map. It has a border of the given weight and color and can optionally
// have a semi-transparent background color.
function Rectangle(bounds, opt_weight, opt_color, opt_backgroundColor, opt_opacity) {
      this.bounds_ = bounds;
      this.weight_ = opt_weight || 0.5;
      this.color_ = opt_color || "#F3F781";
      this.backgroundColor_ = opt_backgroundColor || "#F3F781";
      this.opacity_ = opt_opacity || 0.5;
    }
    Rectangle.prototype = new GOverlay();

    // Creates the DIV representing this rectangle.
    Rectangle.prototype.initialize = function(map) {
      // Create the DIV representing our rectangle
      var div = document.createElement("div");
      div.style.border = this.weight_ + "px solid " + this.color_;
      div.style.position = "absolute";
      div.style.backgroundColor =  "#F3F781";
      div.style.opacity = 0.5;
      div.style.filter = "progid:DXImageTransform.Microsoft.Alpha(Opacity=50)"; // for IE8 
      div.style.filter = "alpha(opacity=50)"; // for older IE 

  

// Our rectangle is flat against the map, so we add our selves to the
  // MAP_PANE pane, which is at the same z-index as the map itself (i.e.,
  // below the marker shadows)
  map.getPane(G_MAP_MAP_PANE).appendChild(div);

  this.map_ = map;
  this.div_ = div;
}

// Remove the main DIV from the map pane
Rectangle.prototype.remove = function() {
  this.div_.parentNode.removeChild(this.div_);
}

// Copy our data to a new Rectangle
Rectangle.prototype.copy = function() {
  return new Rectangle(this.bounds_, this.weight_, this.color_,
                       this.backgroundColor_, this.opacity_);
}

// Redraw the rectangle based on the current projection and zoom level
Rectangle.prototype.redraw = function(force) {
  // We only need to redraw if the coordinate system has changed
  if (!force) return;

  // Calculate the DIV coordinates of two opposite corners of our bounds to
  // get the size and position of our rectangle
  var c1 = this.map_.fromLatLngToDivPixel(this.bounds_.getSouthWest());
  var c2 = this.map_.fromLatLngToDivPixel(this.bounds_.getNorthEast());

  // Now position our DIV based on the DIV coordinates of our bounds
  this.div_.style.width = Math.abs(c2.x - c1.x) + "px";
  this.div_.style.height = Math.abs(c2.y - c1.y) + "px";
  this.div_.style.left = (Math.min(c2.x, c1.x) - this.weight_) + "px";
  this.div_.style.top = (Math.min(c2.y, c1.y) - this.weight_) + "px";
} 

Rectangle.prototype.hide = function() {
  this.div_.style.visibility = 'hidden';
}

Rectangle.prototype.show = function() {
  this.div_.style.visibility = 'visible';
}
