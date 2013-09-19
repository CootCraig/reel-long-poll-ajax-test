reel-long-poll-ajax-test
========================

Test case for using Reel as a Ajax long poll server

The reel test server defaults to start on localhost:8091.
Run the test by navigating a browser to http://localhost:8091/test.html.

The list of channels to poll is received by an ajax call to /active.
The ajax call to /active is repeated and times out on subsequent calls.
Navigating again /test.html will also get the timeout.

