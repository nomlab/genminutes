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
  end

  def get_updated_issues(date, project, versions)
    get_issues if @issues.empty?
    issues = []
    @issues.each do |issue|
      issue_project = issue["project"] ? issue["project"]["name"] : ""
      issue_version = issue["fixed_version"] ? issue["fixed_version"]["name"] : ""
      issue_status = issue["status"] ? issue["status"]["name"] : ""
      issue_updated_on = Date.parse(issue["updated_on"])
      if  date <= issue_updated_on && issue_status != "終了" && project == issue_project && versions.include?(issue_version)
        issues << issue
        #puts issue["id"].to_s + " : " + issue["subject"]
      end
    end
    return issues
  end

  def get_non_updated_issues(date, project, versions)
    get_issues if @issues.empty?
    issues = []
    @issues.each do |issue|
      issue_project = issue["project"] ? issue["project"]["name"] : ""
      issue_version = issue["fixed_version"] ? issue["fixed_version"]["name"] : ""
      issue_status = issue["status"] ? issue["status"]["name"] : ""
      issue_updated_on = Date.parse(issue["updated_on"])
      if issue_updated_on<  date && issue_status != "終了" && project == issue_project && versions.include?(issue_version)
        issues << issue
        #puts issue["id"].to_s + " : " + issue["subject"]
      end
    end
    return issues
  end

  def get_issues
    timenow = Time.now.strftime("%Y%m%d%H%M%S")
    page = 1
    begin
      option = "?page=#{page}&limit=100&status_id=*&project_id=lastnote"
      res =  `curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: #{@api_key}" -u #{@usr}:#{@pass} "#{@url}/issues.json#{option}"`
      File.write("issues/"+ timenow + "-" + page.to_s + ".json", res)
      page = page + 1
    end while JSON::parse(res)["issues"] != []

    filenames =  get_latest_issue("issues")

    filenames.each do |filename|
      data = JSON::parse(File.read("issues/" + filename))
      @issues += data["issues"]
    end
    return @issues
  end

  def get_wiki_page(project, title)
    # timenow = Time.now.strftime("%Y%m%d%H%M%S")
    @wiki_page =  `curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: #{@api_key}" "#{@url}/projects/#{project}/wiki/#{title}.json"`
    # File.write("wiki_pages/"+ "#{title}" + timenow + ".json", @wiki_page)
    File.write("wiki_pages/"+ "#{title}" + ".json", @wiki_page)
    @wiki_page
  end

  def send_wiki_page(project, title)
    `curl -v -H "Content-Type: application/json" -X PUT --data "@wiki_pages/#{title}.json" -u #{@usr}:#{@pass} "#{@url}/projects/#{project}/wiki/#{title}.json"`
  end

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

  def latest_date(date1, date2)
    Time.parse(date1) > Time.parse(date2) ? date1 : date2
  end
end
