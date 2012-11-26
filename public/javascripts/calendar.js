if (!Array.prototype.indexOf) {
  Array.prototype.indexOf = function(needle) {
    for (var i=0; i < this.length; i += 1) {
      if (this[i] === needle) {
        return i;
      }
    }
    return -1;
  };
}

Date.prototype.getMonthName = function(lang) {
  lang = lang && (lang in Date.locale) ? lang : 'en';
  return Date.locale[lang].month_names[this.getMonth()];
};

Date.prototype.getMonthNameShort = function(lang) {
  lang = lang && (lang in Date.locale) ? lang : 'en';
  return Date.locale[lang].month_names_short[this.getMonth()];
};

Date.locale = {
  en: {
    month_names: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    month_names_short: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  }
};

var _c_this;
var Calendar = {
  init: function(options) {
    _c_this = this;
    this.url_base = '/cal/days.php';
    this.id = options.id;
    this.year = parseInt(options.year, 10);
    this.month = parseInt(options.month, 10);
    this.yearRange = options.yearRange;
    this.minDate = options.minDate;
    if (options.hasOwnProperty("title")) {
      this.title = options.title;
    }
    if (options.hasOwnProperty("days")) {
      this.days = options.days;
    }
    else {
      this.updateDays();
    }
    // set up Datepicker
    jQuery('#' + this.id).datepicker({
      showOn: 'button',
      buttonImage: '/images/calendar.gif',
      buttonImageOnly: true,
      changeMonth: true,
      changeYear: true,
      dateFormat: 'yy-mm-dd',
      defaultDate: sprintf('%04d-%02d-01', this.year, this.month),
      yearRange: this.yearRange,
      minDate: this.minDate,
      constrainInput: true,
      onChangeMonthYear: this.onOnChangeMonthYear,
      beforeShowDay: this.onBeforeShowDay,
      onSelect: this.onDaySelect
    });
  },
  updateDays: function() {
    var url = this.url_base + '?year=' + sprintf('%04d', this.year) + '&month=' + sprintf('%02d', this.month);
    if (this.hasOwnProperty("title")) {
      url += '&title=' + encodeURIComponent(this.title);
    }
    jQuery.ajax({
      async:    false,
      url:      url,
      dataType: 'json',
      success:  function(json) {
        _c_this.days = json.days;
        $('#' + _c_this.id).datepicker('refresh');
      }
    });
  },
  onOnChangeMonthYear: function(year, month, inst) {
    _c_this.year = parseInt(year, 10);
    _c_this.month = parseInt(month, 10);
    _c_this.updateDays();
  },
  onBeforeShowDay: function(date) {
    var thedate = date.getDate();
    if (_c_this.days.indexOf(thedate) > -1) {
      return [true, ''];
    }
    else {
      return [false];
    }
  },
  onDaySelect: function(dateText, inst) {
    if (_c_this.hasOwnProperty("title")) {
      var url_bits = [
        '/cal/news_url.php?',
        'date=' + dateText
      ];
      if (_c_this.hasOwnProperty("title")) {
        url_bits.push('title=' + encodeURIComponent(_c_this.title));
        //url_bits.push('f%5Bsource_s%5D%5B%5D=' + encodeURIComponent(_c_this.title));
      }
    }
    else {
      var year = parseInt(dateText.substr(0, 4), 10);
      var month = parseInt(dateText.substr(5, 2), 10);
      var day = parseInt(dateText.substr(8, 2), 10);
      var d = new Date(dateText);
      var url_bits = [
        '/?commit=search',
        'f%5Bformat%5D%5B%5D=newspapers',
        'q=' + d.getMonthName('en') + '+' + day + '+AND+' + year + '+%28Image%2B1%29',
        'search_field=title'
      ];
    }
    var url = url_bits.join('&');
    window.location.replace(url);
  }
};
