require 'time'
require 'json'
require 'yaml'

##########################################

def load_settings
  settings = YAML.load_file(File.dirname(__FILE__) + '/settings.yml')
  @api_key = settings["api_key"]
  @usr = settings["usr"]
  @pass = settings["pass"]
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

##########################################

load_settings()

timenow = Time.now.strftime("%Y%m%d%H%M%S")
page = 1

begin
  option = "?page=#{page}&limit=100&status_id=*&project_id=lastnote"
  res =  `curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: #{@api_key}" -u #{@usr}:#{@pass} "http://redmine.swlab.cs.okayama-u.ac.jp/issues.json#{option}"`
  File.write("data/"+ timenow + "-" + page.to_s + ".json", res)  
  page = page + 1
end while JSON::parse(res)["issues"] != []

filenames =  get_latest_filename("data")

issues = []
filenames.each do |filename|
  data = JSON::parse(File.read("data/" + filename))
  issues += data["issues"]  
end

start_date = Time.parse("2013/10/1")
end_date = Time.parse("2013/10/31")
issues.each do |issue|
  if start_date < Time.parse(issue["updated_on"]) && Time.parse(issue["updated_on"])  < end_date
    puts issue["id"].to_s + " : " + issue["subject"] 
  end
end

puts "ticket count: " + issues.size.to_s
