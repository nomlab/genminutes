# -*- coding: utf-8 -*-
require 'time'
require 'date'
require 'json'
require 'yaml'
require File.dirname(__FILE__) + '/GCal'
require 'google/api_client'
require File.dirname(__FILE__) + '/issue'
require File.dirname(__FILE__) + '/wiki_page'
require File.dirname(__FILE__) + '/redmine_adapter'

##########################################
### MinutesGenerator
### Issueの情報を元に，議事録を作成する．
##########################################
class MinutesGenerator
  def initialize(second_latest_event_date=nil, latest_event_date=nil, project=nil, redmine_adapter=nil,
                 issues_for_review=nil, issues_for_on_target_review=nil,wiki_page=nil)
    @second_latest_event_date = second_latest_event_date
    @latest_event_date = latest_event_date
    @project = YAML.load_file(File.dirname(__FILE__) + '/settings.yml')["project"]
    @redmine_adapter = RedmineAdapter.new
    @issues_for_review = nil
    @issues_for_non_target_review = nil
    @wiki_page = nil
  end

  ### 議事録を新規作成する ###
  def create_minutes
    load_template_minutes
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

  ### 議事録を送る ###
  def send_minutes
    @redmine_adapter.send_wiki_page(@project, @wiki_page.title)
  end

  ### 議事録をファイルに保存する ###
  def save_minutes
    File.write("wiki_pages/"+ "#{@wiki_page.title}" + ".json", @wiki_page.data.to_json) if @wiki_page != nil
  end

  ### タイトルをファイルに書き出す ###
  def save_title
    File.write(File.dirname(__FILE__) + '/latest_iteration.txt', @wiki_page.title)
  end

  ### 議事録のテンプレートファイルの読み込み ###
  def load_template_minutes
    @wiki_page = RedmineWikiPage.read("wiki_pages/template.json")
  end

  ### タイトルを作成 ###
  def create_title
    @wiki_page.title = File.read(File.dirname(__FILE__) + '/latest_iteration.txt')
    @wiki_page.title = @wiki_page.next_wiki_page_title
  end

  ### テキストを作成 ###
  def create_text
    members = File.readlines(File.dirname(__FILE__) + '/member.txt').map{|member| member.chomp}
    text = ""
    text << "h1. #{@wiki_page.title}\n\n"
    text << "マネージャ: AAAA\n"
    text << "書記: ????\n"
    text << "期間: #{@second_latest_event_date.to_s}～#{@latest_event_date.to_s}\n"
    text << "[[#{@wiki_page.previous_wiki_page_title}|前回(#{@wiki_page.previous_wiki_page_title})へ]]\n"
    text << "[[Ms?.?.?|直近のバージョンアップ]]\n\n"
    text << "h1. #{@latest_event_date.to_s}\n\n"
    text << "参加者:#{members.join(", ")}\n\n"
    text << "h3. 1. 本イテレーションの方針について\n\n"
    text << "h3. 2. 新規チケットの作成について\n\n"
    text << "h3. 3. GN開発合宿について\n\n"
    text << "h3. 4. その他\n\n"
    @wiki_page.text = text
  end

  ### バージョンを指定 ###
  def create_version
    @wiki_page.version = 1
  end

  ### テキストをアップデート ###
  def update_text
    text = @wiki_page.text
    get_issues(@second_latest_event_date, @latest_event_date)
    text << "h1. #{@latest_event_date}\n\n"
    text << "参加者: 乃村，木村，吉井，檀上，村田，岡田，北垣，河野\n\n"

    text << "h3. 1. チケットのレビュー\n\n"
    text << "(更新あり)\n"
    @issues_for_review.each do |issue|
      text << "##{issue.id} #{issue.status_name} #{issue.subject} #{issue.assigned_to_name} #{issue.fixed_version_name}\n"
    end

    text << "\n"
    text << "(更新なし)\n"
    @issues_for_non_target_review.each do |issue|
      text << "##{issue.id} #{issue.status_name} #{issue.subject} #{issue.assigned_to_name} #{issue.fixed_version_name}\n"
    end
    @wiki_page.text = text
  end

  ### wiki_pageをredmineから取得 ###
  def get_wiki_page
    title = File.read(File.dirname(__FILE__) + '/latest_iteration.txt').chomp
    @wiki_page = @redmine_adapter.get_wiki_page(@project, title)
  end

  ### issue(ticket)をredmineから取得 ###
  def get_issues(second_latest_date, latest_date)
    project = "LastNote"
    versions = YAML.load_file(File.dirname(__FILE__) + '/settings.yml')["versions"]
    @issues_for_review = @redmine_adapter.get_updated_issues(second_latest_date, project, versions)
    @issues_for_non_target_review = @redmine_adapter.get_non_updated_issues(second_latest_date, project, versions)
  end
end
##########################################

### main
@gcal = GCal.new('GenMinutes')
@google_calendar_id = YAML.load_file(File.dirname(__FILE__) + '/settings.yml')["google_calendar_id"]
second_latest_date, latest_date = @gcal.get_event_date_last_two(@google_calendar_id, ".*談話会$")
minutes_generator = MinutesGenerator.new(second_latest_date, latest_date)
today = Date.today
#if today == latest_date - 3
  minutes = minutes_generator.update_minutes
#elsif today == latest_date
  minutes = minutes_generator.create_minutes
#end
