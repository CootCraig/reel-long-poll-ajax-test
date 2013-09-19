# http://localhost:8091/test.html
require 'rubygems'
require 'bundler/setup'
require 'celluloid/autostart'
require 'reel'
require 'trollop'
require 'cgi'
require 'date'
require 'json'
require 'pathname'

module ReelLongPollAjaxTest
  VERSION = '0.0.1'
  APP_LOGGER = Logger.new('log.txt');

  Celluloid.logger = APP_LOGGER

  EVENT_TOPIC = 'events'
  CHANNELS = (100..130).collect{|n| n.to_s}

  class WebServer < Reel::Server
    def initialize(the_opts)
      @host = the_opts[:host]
      @port = the_opts[:port]
      super(@host, @port, &method(:on_connection))
      APP_LOGGER.info "WebServer starting on #{@host}:#{@port}"
    end

    def on_connection(connection)
      while request = connection.request
        if !request.websocket?
          APP_LOGGER.debug "WebServer.on_connection #{request.url}"
          route(connection,request)
          if !connection.attached?
            break
          end
        end
      end
    rescue => ex
      APP_LOGGER.error "on_connection\n#{ex.message}\n#{ex.backtrace}"
    end
    def route(connection,request)
      if request.path == '/poll.js'
        request.respond :ok, File.read('poll.js')
      elsif request.path == '/favicon.ico'
        request.respond :ok, File.read('favicon.ico')
      elsif request.path == '/test.html'
        request.respond :ok, File.read('test.html')
      elsif request.path == '/active'
        request.respond :ok, {channels: CHANNELS}.to_json
      elsif request.path == '/event'
        event_request(connection,request)
      else
        request.respond :not_found, "Not Found"
      end
    end
    def event_request(connection,request)
      query_string = request.query_string || ''
      params = CGI::parse(query_string)
      if params['channel'] && (params['channel'].length == 1) && (params['channel'][0].length > 0)
        request.body.to_s
        connection.detach
        Celluloid::Actor[:ajax_notifier].async.register_connection(connection,params['channel'][0])
      else
        error_event = { 'error' => "No extension" }
        connection.respond :bad_request, error_event.to_json
      end
    end
  end
  class ChannelEventSource
    include Celluloid
    include Celluloid::Notifications
    @@event_counter = 0
    def initialize(channel)
      @channel = channel
      @random = Random.new
      APP_LOGGER.info "ChannelEventSource starting channel #{@channel}"
      after(random_delay) {async.event}
    end
    def random_delay
      @random.rand 4..8
    end
    def event
      publish EVENT_TOPIC, {channel: @channel, counter: ChannelEventSource.next_event_count.to_s, at: DateTime.now.to_s}
      after(random_delay) {async.event}
    end
    def self.start_channels channels
      channels.each do |channel|
        ChannelEventSource.supervise_as :"channel_#{channel}", channel
      end
    end
    def self.next_event_count
      @@event_counter += 1
      @@event_counter
    end
  end
  class AjaxNotifier
    include Celluloid
    include Celluloid::Notifications

    def initialize
      @subscribers = {}
      subscribe(EVENT_TOPIC,:event)
    end
    def event(topic,event)
      channel = event[:channel]
      if channel
        channel_sym = channel.to_sym
        payload = event.to_json
        if @subscribers[channel_sym]
          @subscribers[channel_sym].each do |connection|
            begin
              APP_LOGGER.debug "AjaxNotifier.event: respond channel #{channel} #{payload}"
              connection.respond :ok, payload
              connection.close
            rescue Reel::SocketError
            rescue => ex
              APP_LOGGER "AjaxNotifier.event\n#{ex.message}\n#{ex.backtrace}"
            end
          end
          @subscribers[channel_sym].clear
        end
      end
    end
    def register_connection(connection,channel)
      channel_sym = channel.to_sym
      @subscribers[channel_sym] = [] unless @subscribers[channel_sym]
      @subscribers[channel_sym] << connection
      APP_LOGGER.debug "register_connection: channel #{channel} connection count #{@subscribers[channel_sym].length}"
    end
  end

  opts = Trollop::options do
    version "reel-long-poll-ajax-test #{ReelLongPollAjaxTest::VERSION} (c) 2013 Craig Anderson"
    opt :host, "Host for Reel HTTP", :default => '0.0.0.0'
    opt :port, "Port for Reel HTTP", :default => 8091
  end

  test_opts = {host: opts[:host], port: opts[:port]}

  APP_LOGGER.info "\n===\n=== reel-long-poll-ajax-test run at #{test_opts[:host]}:#{test_opts[:port]}\n==="

  AjaxNotifier.supervise_as :ajax_notifier
  ChannelEventSource.start_channels CHANNELS
  WebServer.supervise_as :web_server, test_opts
  sleep
end

