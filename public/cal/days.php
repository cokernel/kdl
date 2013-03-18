<?php
# days.php
#
# Required parameters:
#  * month             1 <= intval(..) <= 12
#  * year              /^\d+$/
#
# Optional parameter:
#  * title             string
#
# Returns the list of days in the given month and year
# with newspaper issues, optionally restricting to a 
# specific title.
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
  if (!isset($input['month']) or !isset($input['year'])) {
    bad_request();
  }
  
  $options['month'] = intval($input['month']);
  if ($options['month'] < 1 or $options['month'] > 12) {
    bad_request();
  }
  $options['year'] = intval($input['year']);
  $options['date'] = sprintf("%04d-%02d", $options['year'], $options['month']);
  
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
    if ($key === 'fq') {
      $values = array();
      foreach ($params[$key] as $item) {
        $values[] = $key . '=' . urlencode($item);
      }
      $params[$key] = $key . '=' . implode('&', $values);
    }
    else {
      $params[$key] = $key . '=' .  urlencode($value);
    }
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
    'facet.prefix' => $options['date'],
    'facet.limit' => 31,
    'facet.sort' => 'index',
    'rows' => '0',
  );
  
  if (isset($options['title'])) {
    $params['fq'] = array(
      '{!raw f=' . $config['title_field'] . '}' . $options['title'],
      "{!raw f=repository_facet}University of Kentucky",
      "(format:newspapers AND title_t:'Kentucky' AND title_t:'kernel') OR (format:newspapers AND title_t:'Blue-Tail' AND title_t:'Fly')",
    );
  }
  else {
    $params['fq'] = array(
      "{!raw f=repository_facet}University of Kentucky",
      "(format:newspapers AND title_t:'Kentucky' AND title_t:'kernel') OR (format:newspapers AND title_t:'Blue-Tail' AND title_t:'Fly')",
    );
  }

  return $params;
}

function get_solr_result($us_options) {
  $ch = curl_init(get_solr_url(get_params($us_options)));
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  return json_decode(curl_exec($ch), true);
}

function get_days($hash) {
  $dates = $hash['facet_counts']['facet_fields']['full_date_s'];
  $result = array();
  for ($index = 0; $index < count($dates); $index += 2) {
    $result[] = intval(substr($dates[$index], -2, 2));
  }
  return json_encode(array('days' => $result));
}

print get_days(get_solr_result($_REQUEST));
