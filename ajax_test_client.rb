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

  CONNECTION = 'jdbc:sqlite:data/testlog.db' if false
  CONNECTION = 'jdbc:sqlserver://localhost;database=reeltest;user=sa;password=banana;' if true
  DB = Sequel.connect(CONNECTION)
  TESTLOG = DB[:testlog]

  @@app_logger = Logger.new('client_log.txt')
  @@app_logger.level = Logger::INFO
  Celluloid.logger = @@app_logger

  def self.logger
    @@app_logger
  end

  def self.get_channel_list
    begin
      Celluloid::Actor[:log_actor].async.info "get_channel_list: url #{CHANNEL_LIST_URL}"
      response = HTTParty.get(CHANNEL_LIST_URL)
      json_object = JSON.parse(response.body)
      channel_array = json_object['channels']
      Celluloid::Actor[:log_actor].async.info "get_channel_list: channels #{channel_array}"
      channel_array
    rescue => ex
      Celluloid::Actor[:log_actor].async.error "get_channel_list: #{ex.message}"
      puts "get_channel_list: fail #{ex.message}"
      exit 1
    end
  end
  def self.run
    puts "Starting"
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
      Celluloid::Actor[:log_actor].async.info "ChannelClient: starting #{@id} channel url is #{@channel_ajax_url}"
      async.run
    end
    def run
      loop do
        response = HTTParty.get(@channel_ajax_url)
        json_object = JSON.parse(response.body)
        Celluloid::Actor[:db_log].async.db_log(@id.to_s,json_object)
        Celluloid::Actor[:log_actor].async.debug "ChannelClient: id #{@id} [#{json_object}]"
      end
    end

  end
  class DbLog
    include Celluloid

    def db_log(id,evt)
      TESTLOG.insert(:source => "client_#{id}", :channel => evt['channel'].to_i, :counter => evt['counter'].to_i)
    end
  end
  class LogActor
    include Celluloid

    def debug(msg)
      ReelLongPollAjaxTestClient.logger.debug msg
    end
    def error(msg)
      puts msg
      ReelLongPollAjaxTestClient.logger.error msg
    end
    def info(msg)
      puts msg
      ReelLongPollAjaxTestClient.logger.info msg
    end
  end
end

ReelLongPollAjaxTestClient.run

