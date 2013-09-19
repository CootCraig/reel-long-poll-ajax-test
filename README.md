reel-long-poll-ajax-test
========================

Test case for using Reel as a Ajax long poll server

The reel test server defaults to start on localhost:8091.
Run the test by navigating a browser to http://localhost:8091/test.html.

The list of channels to poll is received by an ajax call to /active.
The ajax call to /active is repeated and times out on subsequent calls.
Navigating again /test.html will also get the timeout.

The number of event channels can be set with this range.
The test.html page will track the events on each of these channels.

CHANNELS = (101..102).collect{|n| n.to_s}

With MRI ruby 2.0.0p247 2 channels runs fine.

Thu Sep 19 14:04:31 MDT 2013 - At this on MRI ruby 2.0.0p247.  With 2
browsers, I can only register one at a time for the next event.

