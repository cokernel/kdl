// GMapConfig:
// Nonce class for storing path configuration.
function GMapConfig()
{
  var me = this;

  // URL prefixes must be empty or end in a forward slash
  me.resources_url_prefix = "/gmapviewer/resources/";
  me.tile_url_prefix      = "/nyx.php?href=http://nyx.uky.edu/tiles/";

  me.lineEnding           = '\n';
}
