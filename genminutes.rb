# -*- coding: utf-8 -*-
require 'time'
require 'date'
require 'json'
require 'yaml'
require File.dirname(__FILE__) + '/GCal'
require 'google/api_client'

##########################################
### MinutesGenerator
### Issueの情報を元に，議事録を作成する．
##########################################
class MinutesGenerator
  def initialize
    @gcal = GCal.new('GenMinutes')
    @google_calendar_id = YAML.load_file(File.dirname(__FILE__) + '/settings.yml')["google_calendar_id"]
    @project = YAML.load_file(File.dirname(__FILE__) + '/settings.yml')["project"]
    @versions = YAML.load_file(File.dirname(__FILE__) + '/settings.yml')["versions"]
    @title = File.read(File.dirname(__FILE__) + '/latest_iteration.txt').chomp
    @redmine_adapter = RedmineAdapter.new
    @issues_for_review = nil
    @issues_for_non_target_review = nil
    @wiki_page = nil
  end

  ### 議事録を送る ###
  def send_minutes
    title = @wiki_page["wiki_page"]["title"]
    @redmine_adapter.send_wiki_page(@project, title)
  end

  ### 議事録をファイルに保存する ###
  def save_minutes
    title = @wiki_page["wiki_page"]["title"]
    File.write("wiki_pages/"+ "#{title}" + ".json", @wiki_page.to_json) if @wiki_page != nil
  end

  ### 議事録を新規作成する ###
  def create_minutes
    load_template_minutes
    @title = increase_number(@title)
    create_title
    create_text
    create_version
    save_title
    if save_minutes
      print "-------created\n"
      send_minutes
    end
  end

  ### 議事録をアップデートする ###
  def update_minutes
    get_wiki_page
    update_text
    if save_minutes
      print "-------updated\n"
      send_minutes
    end
  end

  private

  ### タイトルをファイルに書き出す ###
  def save_title
    File.write(File.dirname(__FILE__) + '/latest_iteration.txt', @title)
  end

  def load_template_minutes
    @wiki_page = JSON::parse(File.read("wiki_pages/template.json"))
  end

  def create_title
    @wiki_page["wiki_page"]["title"] = @title
  end

  def create_text
    second_latest_date, latest_date = get_event_date_last_two
    text = ""
    text << "h1. #{@title}\n\n"
    text << "マネージャ: AAAA\n"
    text << "書記: ????\n"
    text << "期間: #{second_latest_date.to_s}～#{latest_date.to_s}\n"
    text << "[[#{decrease_number(@title)}|前回(#{decrease_number(@title)})へ]]\n"
    text << "[[Ms?.?.?|直近のバージョンアップ]]\n\n"
    text << "h1. #{latest_date.to_s}\n\n"
    text << "参加者:\n\n"
    text << "h3. 1. 本イテレーションの方針について\n\n"
    text << "h3. 2. 新規チケットの作成について\n\n"
    text << "h3. 3. GN開発合宿について\n\n"
    text << "h3. 4. その他\n\n"
    @wiki_page["wiki_page"]["text"] = text
  end

  def create_version
    @wiki_page["wiki_page"]["version"] = 1
  end

  def update_text
    text = @wiki_page["wiki_page"]["text"]
    second_latest_date, latest_date = get_event_date_last_two
    get_issues(second_latest_date,latest_date)
    text << "h1. #{latest_date}\n\n"
    text << "参加者: 乃村，木村，吉井，檀上，村田，岡田，北垣，河野\n\n"

    text << "h3. 1. チケットのレビュー\n\n"
    text << "(更新あり)\n"
    @issues_for_review.each do |issue|
      issue_id = issue["id"]
      issue_status = issue["status"] ? issue["status"]["name"] : ""
      issue_subject = issue["subject"]
      issue_assigned_to = issue["assigned"] ? issue["assigned"]["name"] : ""
      issue_version = issue["fixed_version"] ? issue["fixed_version"]["name"] : ""
      text << "##{issue_id} #{issue_status} #{issue_subject} #{issue_assigned_to} #{issue_version}\n"
    end

    text << "\n"
    text << "(更新なし)\n"
    @issues_for_non_target_review.each do |issue|
      issue_id = issue["id"]
      issue_status = issue["status"] ? issue["status"]["name"] : ""
      issue_subject = issue["subject"]
      issue_assigned_to = issue["assigned"] ? issue["assigned"]["name"] : ""
      issue_version = issue["fixed_version"] ? issue["fixed_version"]["name"] : ""
      text << "##{issue_id} #{issue_status} #{issue_subject} #{issue_assigned_to} #{issue_version}\n"
    end
    @wiki_page["wiki_page"]["text"] = text
  end

  def get_wiki_page
    @wiki_page = JSON::parse(@redmine_adapter.get_wiki_page(@project, @title))
  end

  def get_issues(second_latest_date, latest_date)
    project = "LastNote"
    @issues_for_review = @redmine_adapter.get_updated_issues(second_latest_date, project, @versions)
    @issues_for_non_target_review = @redmine_adapter.get_non_updated_issues(second_latest_date, project, @versions)
  end

  def increase_number(title)
    title =~ /([A-z]*)(\d*)/
    $1 + "%04d" % ($2.to_i + 1)
  end

  def decrease_number(title)
    title =~ /([A-z]*)(\d*)/
    $1 + "%04d" % ($2.to_i - 1)
  end

  def get_latest_event_date
    event_list = @gcal.event_list_find_by_name(@google_calendar_id, ".*談話会$")
    date_list = []
    event_list.each do |ev|
      if ev.start.date_time == nil
        date_list << ev.start.date
      else
        date_list << ev.start.date_time.to_date
      end
    end
    date_list.sort.reverse.first
  end

  def get_event_date_last_two
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

class Issue
end

class RedmineIssue
  attr_accessor :project_id, :tracker_id, :status_id, :priority_id, :subject, :description,
                :category_id, :fixed_version_id, :assigned_to_id, :parent_issue_id, :custom_fields, :watcher_user_ids
  def initialize()
  end

  def 
end

minutes_generator = MinutesGenerator.new
#minutes_generator.get_wiki_page
#minutes = minutes_generator.update_minutes
minutes = minutes_generator.create_minutes
#print minutes
