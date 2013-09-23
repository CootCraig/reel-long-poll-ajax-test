reel-long-poll-ajax-test
========================

Test case for using Reel as a Ajax long poll server

The reel test server defaults to start on localhost:8091.
Run the test by navigating a browser to http://localhost:8091/test.html.

The number of event channels can be set with this range.
The test.html page will track the events on each of these channels.

CHANNELS = (101..102).collect{|n| n.to_s}

Thu Sep 19 14:04:31 MDT 2013 - At this on MRI ruby 2.0.0p247.  With 2
browsers, it looks like the browsers alternate registering and receiving
events.

Mon Sep 23 15:33:23 MDT 2013
Added start_time parameter to /event ajax call to mark what browser page
the requests are coming from.  Tests with only 2 event channels have
been seen to work. Tests with 16 event channels have response problems.

