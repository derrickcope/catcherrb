#!/usr/bin/env ruby
#
# catchernew.rb
# 2018-04-18
#

require 'yaml'
require 'fileutils'
require 'feedjira'
require 'down'

class Log
  include YAML
  include FileUtils
  
  attr_accessor :log_ary
  attr_reader :logyaml

  def initialize(logyaml)
    @logyaml = logyaml
  end

  def checklog
    samplelog_ary = ["first.mp3", "another.mp3", "random.mp3"]
    unless File.exist?(logyaml)
      puts "creating log file"
      File.open(logyaml, "w+").write(samplelog_ary.to_yaml)
      abort("you will need to run the application again")
    else
      puts "log exists"
    end
  end

  def getlog
   puts "opening log"
   @log_ary = YAML.load_file(logyaml)
  end

  def writelog
    puts "writing log"
    p log_ary
    File.open(logyaml, "r+").write(log_ary.to_yaml)
  end
end

class Feed
  include Down
  include Feedjira
  include YAML
  include FileUtils

  attr_accessor :log_ary
  attr_reader :feedyaml, :feed, :link, :title, :feedtitle, :feed_hsh, :feed_ary

  def initialize(feedyaml)
    @feedyaml = feedyaml
  end

  def checkfeed
    samplefeed_hsh = {"global"=>"some global setting", "save folder"=>"some preference", 
          "feeds" => {"feed01"=>{"title"=>"title of feed", "rss"=>"http://www.somefeed.com/rss", 
          "many"=>5, "remark"=>"so so"}, "feed02"=>{"feed02"=>"title of feed2", "rss"=>"https://www.anotherfeed.com/feed.xml", 
          "many"=> 3, "remark"=>"bad"}}}
    unless File.exist?(feedyaml)
      puts "creating feed file"
      File.open(feedyaml, "w+").write(samplefeed_hsh.to_yaml)
      abort("please configure news feeds in feed.yml and then run app")
    else
      puts "feed exists"
    end
  end

  def getfeed
    @feed_ary = []
    puts "getting feeds"
    @feed_hsh = YAML.load_file(feedyaml)
    feed_hsh["feeds"].each do |key,value|
      feed_ary.push(value["rss"])
    end
    feed_ary
  end

  def parse(uri)
    puts "parsing #{uri}"  
    feedparse = Feedjira::Feed.fetch_and_parse(uri)
    @feedtitle = feedparse.title
    @feed = feedparse.entries.first
    @title = feedparse.entries.first.title 
    case 
    when (feedparse.entries.first).respond_to?(:guid)
      @link = feedparse.entries.first.guid
    when (feedparse.entries.first).respond_to?(:enclosure_url)
      @link = feedparse.entries.first.enclosure_url
    when (feedparse.entries.first).respond_to?(:image)
      @link = feedparse.entries.first.image
    else
      puts "no link"
    end
  end

  def getdown
    feed_ary.each do |feed|
      parse(feed)
      puts "trying #{feedtitle}"
      puts "save folder #{feed_hsh["save folder"]}"
      unless Dir.exist?("#{feed_hsh["save folder"]}/#{feedtitle.downcase.delete(" ")}")
        puts "making #{feedtitle.downcase.delete(" ")} folder"
        FileUtils.mkdir("#{feed_hsh["save folder"]}/#{feedtitle.downcase.delete(" ")}")
      else puts "folder exists"
      end
      unless log_ary.include?("#{title.downcase.delete(" ")}.mp3")
        puts "downloading #{title.downcase.delete(" ")}.mp3"
        tempfile = Down.open(link, rewindable: false)
        IO.copy_stream(tempfile, "#{feed_hsh["save folder"]}/#{feedtitle.downcase.delete(" ")}/#{title.downcase.delete(" ")}.mp3")
        tempfile.close
        log_ary.push("#{title.downcase.delete(" ")}.mp3")
      else puts "file exists in log"
      end
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, 
          Down::TimeoutError, Down::TooManyRedirects, Down::ConnectionError
      next
    end
  end
end



log = Log.new("/home/derrick/code/ruby/Catcherrb/log.yml")
feed = Feed.new("/home/derrick/code/ruby/Catcherrb/feeds.yml")

log.checklog

feed.checkfeed

feed.getfeed

feed.log_ary = log.getlog

feed.getdown

log.log_ary = feed.log_ary

log.writelog



