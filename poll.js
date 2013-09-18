// execute callback when the page is ready:
jQuery(function($) {
  var add_channel = null;
  var channel_events = {};
  var get_active = null;
  var get_active_error = null;
  var get_active_success = null;
  var poll_channel = null;
  var poll_error = null;
  var poll_success = null;
  var start_polling = null;

  add_channel = function(channel) {
    var channel_class = '';
    var new_div = '';
    try {
      channel_class = 'chan_' + channel;
      channel_events[channel] = 0;
      new_div = '<div class="' + channel_class + '">';
      new_div += '<span class="channel">';
      new_div += channel;
      new_div += '</span>';
      new_div += ' - Number of events seen <span class="events_seen">0</span>';
      new_div += ' - Last event counter <span class=event_counter>0</span>';
      new_div += ' - Event origin time <span class=event_at>0</span>';
      new_div += ' - Last request sent at <span class=request_time>Never</span>';
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
      timeout: (5*1000)
    });
  };
  get_active_error = function(jqXHR,textStatus,errorThrown) {
    $('.log').append('<p>get_active_error</p>');
    setTimeout(get_active,(3*1000));
  };
  get_active_success = function(data,status,jqXHR) {
    var channel = '';
    var channel_count = 0;
    var channel_list = null;
    var ii = 0;

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
    setTimeout(get_active,(3*1000));
  };
  poll_channel = function(channel) {
    var time_span = 'div.chan_' + channel + ' span.request_time';
    var ct = new Date();
    $(time_span).text(ct.toTimeString());
    $.ajax({
      url: '/event',
      data: {'channel': channel},
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
      setTimeout(poll_channel,(3*1000),channel);
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
      var events_seen_span = channel_div + ' span.events_seen';
      var excp_seen = false;

      try {
        event_channel = data['channel'];
        event_counter = data['counter'];
        event_at = data['at'];
        channel_events[channel] += 1;
        $(events_seen_span).text(channel_events[channel].toString());
        $(event_counter_span).text(event_counter);
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

  get_active();
});

