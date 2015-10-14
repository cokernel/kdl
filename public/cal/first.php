<?php
# first.php
#
# Optional parameter:
#  * title             string
#
# Returns the first full date with issues of the
# given newspaper title.  If title is not specified,
# gives the first full date of any dated item.
#
# This code doesn't specifically isolate to newspaper
# issues; that is a property of which items we give
# the full_date_s field.

function bad_request() {
  header('HTTP/1.0 400 Bad Request');
  exit;
}

function valid_options($input) {
  $options = array();
  if (isset($input['title'])) {
    $options['title'] = $input['title'];
  }
  return $options;
}

function config($extra_options = array()) {
  $options = array(
    'date_field' => 'full_date_s',
    'title_field' => 'source_s',
    'host' => 'localhost:8983',
  );
  return array_merge($options, $extra_options);
}

function get_solr_url($params) {
  $config = config();
  foreach ($params as $key => $value) {
    $params[$key] = $key . '=' .  urlencode($value);
  }
  $url = 'http://' . $config['host'] . '/solr/select?' . implode('&', $params);
  return $url;
}

function get_params($us_options) {
  $config = config();
  $options = valid_options($us_options);

  $params = array(
    'wt' => 'json',
    'facet.field' => $config['date_field'],
    'facet.limit' => 31,
    'facet.sort' => 'index',
    'rows' => '0',
  );
  
  if (isset($options['title'])) {
    $params['fq'] = '{!raw f=' . $config['title_field'] . '}' . $options['title'];
  }

  return $params;
}

function get_solr_result($us_options) {
  $ch = curl_init(get_solr_url(get_params($us_options)));
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  return json_decode(curl_exec($ch), true);
}

function get_first_day($hash) {
  $date = $hash['facet_counts']['facet_fields']['full_date_s'][0];
  $year = substr($date, 0, 4);
  return json_encode(array('date' => $date, 'year' => $year));
}

print get_first_day(get_solr_result($_REQUEST));
