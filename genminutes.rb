# -*- coding: utf-8 -*-
require 'time'
require 'date'
require 'json'
require 'yaml'
require File.dirname(__FILE__) + '/GCal'
require 'google/api_client'

##########################################
### RedmineApapte
### Redmineからチケットの情報を取ってきたり
### 生成した議事録をRedmineに登録する
##########################################
class RedmineAdapter

  def initialize
    settings = YAML.load_file(File.dirname(__FILE__) + '/settings.yml')
    @api_key = settings["api_key"]
    @usr = settings["usr"]
    @pass = settings["pass"]
    @issues = []
  end

  def get_issues_between_from_start_to_end(start_date, end_date)
    get_issues

    @issues.each do |issue|
      if start_date < Date.parse(issue["updated_on"]) && Date.parse(issue["updated_on"])  < end_date
        puts issue["id"].to_s + " : " + issue["subject"]
      end
    end
  end

  def get_issues
    timenow = Time.now.strftime("%Y%m%d%H%M%S")
    page = 1
    begin
      option = "?page=#{page}&limit=100&status_id=*&project_id=lastnote"
      res =  `curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: #{@api_key}" -u #{@usr}:#{@pass} "http://redmine.swlab.cs.okayama-u.ac.jp/issues.json#{option}"`
      File.write("data/"+ timenow + "-" + page.to_s + ".json", res)
      page = page + 1
    end while JSON::parse(res)["issues"] != []

    filenames =  get_latest_filename("data")

    filenames.each do |filename|
      data = JSON::parse(File.read("data/" + filename))
      @issues += data["issues"]
    end
    return @issues
  end

  def get_latest_filename(dir)

    filenames = `ls #{dir}/`.split("\n")
    filenames2 = Hash.new{ |h,k| h[k] = [] }
    latest = nil

    filenames.each do |filename|
      filenames2["#{filename.sub(/-.*/,"")}"] << filename
    end

    filenames2.keys.each do |date|
      latest ||= date
      latest = latest_date(latest, date)
    end

    return filenames2["#{latest}"]

  end

  def latest_date(date1, date2)
    Time.parse(date1) > Time.parse(date2) ? date1 : date2
  end
end

class MinutesGenerator
  def initialize
    @gcal = GCal.new('GenMinutes')
    @google_calendar_id = YAML.load_file(File.dirname(__FILE__) + '/settings.yml')["google_calendar_id"]
  end

  def get_issues
    redmine_adapter = RedmineAdapter.new

    start_date, end_date = get_start_date_and_end_date
    redmine_adapter.get_issues_between_from_start_to_end(start_date, end_date)
  end

  def get_start_date_and_end_date
    event_list = @gcal.event_list_find_by_name(@google_calendar_id, ".*談話会$")
    date_list = []
    event_list.each do |ev|
      if ev.start.date_time == nil
        date_list << ev.start.date
      else
        date_list << ev.start.date_time.to_date
      end
    end
    date_list.sort.reverse.take(2).reverse
  end
end
##########################################

#date_list.sort.take(2)
# puts "ticket count: " + issues.size.to_s

minutes_generator = MinutesGenerator.new
minutes_generator.get_issues
