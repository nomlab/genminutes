# -*- coding: utf-8 -*-
##########################################
### RedmineApapter
### Redmineからチケットの情報を取ってきたり
### 生成した議事録をRedmineに登録する
##########################################
class RedmineAdapter

  def initialize
    settings = YAML.load_file(File.dirname(__FILE__) + '/settings.yml')
    @api_key = settings["api_key"]
    @usr = settings["usr"]
    @pass = settings["pass"]
    @url = settings["url"]
    @project = settings["project"]
    @issues = []
    @wiki_page = []
    @logfile = File.dirname(__FILE__) + '/log/genminutes.log'
  end

  ### 更新があったissueを取得する ###
  ### 現在の更新条件: 打合せから打合せ(イテレーション)の間で更新があったもので，終了状態ではないもの，特定のバージョンにひも付いているもの． ###
  def get_updated_issues(date, project, versions)
    get_issues if @issues.empty?
    updated_issues = []
    @issues.each do |issue|
      if  date <= issue.updated_on && issue.status_name != "終了" && project == issue.project_name && versions.include?(issue.fixed_version_name)
        updated_issues << issue
      end
    end
    return updated_issues
  end

  ### 更新がなかったissueを取得する ###
  def get_non_updated_issues(date, project, versions)
    get_issues if @issues.empty?
    non_updated_issues = []
    @issues.each do |issue|
      if issue.updated_on < date && issue.status_name != "終了" && project == issue.project_name && versions.include?(issue.fixed_version_name)
        non_updated_issues << issue
      end
    end
    return non_updated_issues
  end

  ### すべてのissue を取得する ###
  def get_issues
    timenow = Time.now.strftime("%Y%m%d%H%M%S")
    page = 1
    begin
      option = "?page=#{page}&limit=100&status_id=*&project_id=lastnote"
      #res =  `curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: #{@api_key}" -u #{@usr}:#{@pass} "#{@url}/issues.json#{option}" >> #{@logfile} 2>&1`
      res =  `curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: #{@api_key}" -u #{@usr}:#{@pass} "#{@url}/issues.json#{option}"`
      File.write("issues/"+ timenow + "-" + page.to_s + ".json", res)
      page = page + 1
    end while JSON::parse(res)["issues"] != []

    filenames =  get_latest_issue("issues")

    filenames.each do |filename|
      data = JSON::parse(File.read("issues/" + filename))
      data["issues"].each do |d|
        @issues << RedmineIssue.create(d)
      end
    end
    return @issues
  end

  ### wikipageを取得する ###
  def get_wiki_page(project, title)
    # timenow = Time.now.strftime("%Y%m%d%H%M%S")
    wiki_page = `curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: #{@api_key}" "#{@url}/projects/#{project}/wiki/#{title}.json"`
    # File.write("wiki_pages/"+ "#{title}" + timenow + ".json", @wiki_page)
    File.write("wiki_pages/"+ "#{title}" + ".json", wiki_page)
    RedmineWikiPage.create(wiki_page)
  end

  ### wikipageを送る ###
  def send_wiki_page(project, title)
    `curl -v -H "Content-Type: application/json" -X PUT --data "@wiki_pages/#{title}.json" -u #{@usr}:#{@pass} "#{@url}/projects/#{project}/wiki/#{title}.json"`
  end

  private
  ### issueのファイルを読み込む ###
  def get_latest_issue(dir)
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

  ### 最新日を取得する ###
  def latest_date(date1, date2)
    Time.parse(date1) > Time.parse(date2) ? date1 : date2
  end
end
