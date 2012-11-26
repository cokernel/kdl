<?php
# days.php
#
# Required parameters:
#  * date              /^\d{4}-\d{2}-\d{2}$/
#  * title             string
#
# Returns the (erisian) URL of the given issue of
# the given newspaper.

function bad_request() {
  header('HTTP/1.0 400 Bad Request');
  exit;
}

function valid_options($input) {
  $options = array();
  if (!isset($input['date']) or !isset($input['title'])) {
    bad_request();
  }

  if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $input['date'])) {
    bad_request();
  }
  $options['date'] = $input['date'];
  $options['title'] = $input['title'];
  return $options;
}

function config($extra_options = array()) {
  $options = array(
    'date_field' => 'full_date_s',
    'title_field' => 'source_s',
    'id_field' => 'id',
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
  $url = str_replace('__FQ2__', 'fq', $url);
  return $url;
}

function get_params($us_options) {
  $config = config();
  $options = valid_options($us_options);

  $params = array(
    'wt' => 'json',
    'facet.field' => $config['id_field'],
    'facet.sort' => 'index',
    'rows' => '0',
  );
  
  $params['fq'] = '{!raw f=' . $config['title_field'] . '}' . $options['title'];
  $params['__FQ2__'] = '{!raw f=' . $config['date_field'] . '}' . $options['date'];

  return $params;
}

function get_solr_result($us_options) {
  $ch = curl_init(get_solr_url(get_params($us_options)));
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  return json_decode(curl_exec($ch), true);
}

function get_url($hash) {
  $config = config();
  $id = $hash['facet_counts']['facet_fields'][$config['id_field']][0];
  $url = 'http://eris.uky.edu/catalog/' . $id;
  return $url;
}

header('Location: ' . get_url(get_solr_result($_REQUEST)));
