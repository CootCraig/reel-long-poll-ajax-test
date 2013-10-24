require 'rubygems'
require 'bundler/setup'
require 'celluloid/autostart'
require 'httparty'
require 'json'
require 'sequel'

module ReelLongPollAjaxTestClient
  SERVER_URL = "http://localhost:8091/"
  CHANNEL_LIST_URL = "#{SERVER_URL}active"
  EVENT_URL = "#{SERVER_URL}event?channel="

  DB = Sequel.connect('jdbc:sqlite:data/testlog.db')
  TESTLOG = DB[:testlog]

  @@app_logger = Logger.new('client_log.txt')
  Celluloid.logger = @@app_logger

  def self.logger
    @@app_logger
  end

  def self.get_channel_list
    begin
      ReelLongPollAjaxTestClient.logger.info "get_channel_list: url #{CHANNEL_LIST_URL}"
      response = HTTParty.get(CHANNEL_LIST_URL)
      json_object = JSON.parse(response.body)
      channel_array = json_object['channels']
      ReelLongPollAjaxTestClient.logger.info "get_channel_list: channels #{channel_array}"
      channel_array
    rescue => ex
      ReelLongPollAjaxTestClient.logger.error "get_channel_list: #{ex.message}"
      puts "get_channel_list: fail #{ex.message}"
      exit 1
    end
  end
  def self.run
    ReelLongPollAjaxTestClient.logger.info "\n====\nStarting\n===="
    DbLog.supervise_as :db_log
    LogActor.supervise_as :log_actor
    channel_list = ReelLongPollAjaxTestClient.get_channel_list
    channel_list.each do |channel|
      3.times do |counter|
        sym = "chan_#{channel}_copy_#{counter}".to_sym
        ChannelClient.supervise_as sym,channel,sym
      end
    end
    sleep
  end

  class ChannelClient
    include Celluloid

    def initialize(channel,id)
      @channel = channel
      @id = id
      @channel_ajax_url = "#{EVENT_URL}#{@channel}"
      Celluloid::Actor[:log_actor].async.log "ChannelClient: starting #{@id} channel url is #{@channel_ajax_url}"
      async.run
    end
    def run
      loop do
        response = HTTParty.get(@channel_ajax_url)
        json_object = JSON.parse(response.body)
        Celluloid::Actor[:db_log].async.log(@id.to_s,json_object)
        Celluloid::Actor[:log_actor].async.log "ChannelClient: id #{@id} [#{json_object}]"
      end
    end

  end
  class DbLog
    include Celluloid

    def log(id,evt)
      TESTLOG.insert(:source => "client_#{id}", :channel => evt['channel'].to_i, :counter => evt['counter'].to_i)
    end
  end
  class LogActor
    include Celluloid

    def log(msg)
      ReelLongPollAjaxTestClient.logger.info msg if false
    end
  end
end

ReelLongPollAjaxTestClient.run

