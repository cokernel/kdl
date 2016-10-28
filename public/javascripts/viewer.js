function MpsViewer() {
  var url;
  var path = '';
  var no_url = 'https://nyx.uky.edu/tiles/resources/noimage256.jpg';
  var ajax = null;
  var callback = null;
  var has_tiles = false;
  var width = 0;
  var height = 0;
  var min_zoom = 0;
  var max_zoom = 0;
  var tile_set = {
    tile: {}
  };
  var tile_url_prefix = '/nyx.php?href=http://nyx.uky.edu/tiles/';
  var image_url_prefix = '/nyx.php?href='; 

  function init(options) {
    url = options.url;
    path = url.replace(/\/[^\/]+$/, '/');
    tile_set.url = url;
    callback = options.callback;
    parse();
  }

  function getWidth() {
    return width;
  }

  function getHeight() {
    return height;
  }

  function getMinLevel() {
    return min_zoom;
  }

  function getMaxLevel() {
    return max_zoom;
  }

  function parse() {
    ajax = new XMLHttpRequest();
    ajax.open("GET", image_url_prefix + url, true);
    ajax.onreadystatechange = add_tiles;
    ajax.send(null);
  }

  function add_tiles() {
    var i;
    var lines = [];
    var fields = [];

    if (ajax.readyState == 4 && ajax.status == 200) {
      lines = ajax.responseText.split("\n");
      for (i = 0; i < lines.length; i++) {
        fields = lines[i].split("\t");

        // Tile positions:
        if (fields[0].indexOf(".") > 0) {
          var tile = fields[0];
          var start = parseInt(fields[1], 10);
          var length = parseInt(fields[2], 10);
          var zoom = parseInt(tile.substr(0, tile.indexOf('_')), 10);
          if (zoom > max_zoom) {
            max_zoom = zoom;
          }
          tile_set.tile[tile] = [start, length];
          has_tiles = true;
        }
        // General image metadata:
        else {
          switch (trim(fields[0])) {
          case "name":
            tile_set.name = trim(fields[1]);
            break;

          case "width":
            width = parseInt(fields[1], 10);
            break;

          case "height":
            height = parseInt(fields[1], 10);
            break;

          case "maxzoom":
            tile_set.max_zoom = parseInt(fields[1], 10);
            break;

          case "tilesize":
            tile_set.tile_size = parseInt(fields[1], 10);
            break;

          case "format":
            tile_set.format = trim(fields[1]);
            break;
          }
        }
      }

      tile_set.path = tile_set.url.replace(tile_set.name + '.txt', '');
      ajax = null;
      callback();
    }
  }

  function getTileUrl(level, x, y) {
    var tile = level + '_' + x + '_' + y + '.' + tile_set.format;

    var retval = no_url;
    if (has_tiles) {
      if (tile_set.tile[tile]) {
        var start = tile_set.tile[tile][0];
        var length = tile_set.tile[tile][1];
        var retval = no_url;
        if (length > 0) {
          retval = tile_url_prefix + 'tile.php?Path=' + path + '.AND.Image=' + tile_set.name + '.AND.Start=' + start + '.AND.Length=' + length + '.AND.Format=' + tile_set.format;
        }
      }
    }
    return retval;
  }

  // A little helper function to trim strings (JavaScript doesn't have a built-in trim method):
  function trim(str) {
    var str = str.replace(/^\s+/, ''),
        ws = /\s/,
        i = str.length;
    while (ws.test(str.charAt(--i)));
    return str.slice(0, i + 1);
  }

  return {
    init: init,
    getTileUrl: getTileUrl,
    width: getWidth,
    height: getHeight,
    minLevel: getMinLevel,
    maxLevel: getMaxLevel
  }
}

var mps_viewer = MpsViewer();
