// execute callback when the page is ready:
jQuery(function($) {
  var add_channel = null;
  var channel_events = {};
  var get_active = null;
  var get_active_error = null;
  var get_active_error_count = 0;
  var get_active_success = null;
  var get_active_success_count = 0;
  var poll_channel = null;
  var poll_error = null;
  var poll_success = null;
  var start_polling = null;
  var start_time = '';

  add_channel = function(channel) {
    var channel_class = '';
    var new_div = '';
    try {
      channel_class = 'chan_' + channel;
      channel_events[channel] = {'poll_request_count' : 0, 'poll_success_count' : 0, 'poll_error_count' : 0};
      new_div = '<div class="' + channel_class + '">';
      new_div += '<span class="channel">';
      new_div += channel;
      new_div += '</span>';
      new_div += ' - Last event counter <span class="event_counter">0</span>';
      new_div += ' - poll attempts <span class="poll_request_count">0</span>';
      new_div += ' - poll errors <span class="poll_error_count">0</span>';
      new_div += ' - poll successes <span class="poll_success_count">0</span>';
      //new_div += ' - Event origin time <span class="event_at">0</span>';
      //new_div += ' - Last request sent at <span class="request_time">Never</span>';
      new_div += '</div>';
      $('div.channel_list').append(new_div);
      start_polling(channel);
    } catch(excp) {
      $('.log').append('<p>exception on add_channel</p>');
    }
  };
  get_active = function() {
    $.ajax({
      url: '/active',
      dataType: 'json',
      success: get_active_success,
      error: get_active_error,
      timeout: (8*1000)
    });
  };
  get_active_error = function(jqXHR,textStatus,errorThrown) {
    get_active_error_count += 1;
    $('span.active_error_count').text(get_active_error_count.toString());
    setTimeout(get_active,(5*1000));
  };
  get_active_success = function(data,status,jqXHR) {
    var channel = '';
    var channel_count = 0;
    var channel_list = null;
    var ii = 0;

    get_active_success_count += 1;
    $('span.active_success_count').text(get_active_success_count.toString());

    if (!channel_events.hasOwnProperty('started')) {
      try {
        channel_events['started'] = true;
        channel_list = data.channels;
        channel_count = channel_list.length;
        for (ii=0; ii<channel_count; ++ii) {
          channel = channel_list[ii];
          add_channel(channel);
        }
      } catch (excp) {
        $('.log').append('<p>exception on get_active_success</p>');
      }
    }
    setTimeout(get_active,(5*1000));
  };
  poll_channel = function(channel) {
    var time_span = 'div.chan_' + channel + ' span.request_time';
    var poll_request_count_span = 'div.chan_' + channel + ' span.poll_request_count';
    var ct = new Date();
    $(time_span).text(ct.toTimeString());
    channel_events[channel]['poll_request_count'] += 1;
    $(poll_request_count_span).text(channel_events[channel]['poll_request_count'].toString());
    $.ajax({
      url: '/event',
      data: {'channel': channel, 'start_time': start_time},
      dataType: 'json',
      success: poll_success(channel),
      error: poll_error(channel),
      timeout: (60*60*1000)
    });
  };
  poll_error = function(achannel) {
    var channel = achannel;
    var work_func = null;
    work_func = function(jqXHR,textStatus,errorThrown) {
      var poll_error_count_span = 'div.chan_' + channel + ' span.poll_error_count';
      channel_events[channel]['poll_error_count'] += 1;
      $(poll_error_count_span).text(channel_events[channel]['poll_error_count'].toString());
      setTimeout(poll_channel,(1*1000),channel);
    };
    return work_func;
  };
  poll_success = function(achannel) {
    var channel = achannel;
    var work_func = null;

    // publish @channel, {channel: @channel, counter: @event_count, at: DateTime.now.to_s}
    work_func = function(data,status,jqXHR) {
      var channel_div = "div.chan_" + channel;
      var event_channel = null;
      var event_counter = null;
      var event_counter_span = channel_div + ' span.event_counter';
      var event_at = null;
      var event_at_span = channel_div + ' span.event_at';
      var excp_seen = false;
      var poll_success_count_span = 'div.chan_' + channel + ' span.poll_success_count';

      try {
        event_channel = data['channel'];
        event_counter = data['counter'];
        event_at = data['at'];
        $(event_counter_span).text(event_counter);
        channel_events[channel]['poll_success_count'] += 1;
        $(poll_success_count_span).text(channel_events[channel]['poll_success_count'].toString());
        $(event_at_span).text(event_at);
      } catch(excp) {
        excp_seen = true;
      }
      setTimeout(poll_channel,(40),channel);
    };
    return work_func;
  };
  start_polling = function(channel) {
    setTimeout(poll_channel,(40),channel);
  };

  start_time = (new Date()).toTimeString().split(' ')[0]; // Used to id requests
  get_active();
});

