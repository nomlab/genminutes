# -*- coding: utf-8 -*-
##########################################
### WikiPage
##########################################
class WikiPage
end

##########################################
### RedmineWikiPage
### WikiPageを継承している
### 将来，Githubでも使えるようにするため
##########################################
class RedmineWikiPage < WikiPage
  attr_accessor :data

  def initialize(data=nil)
    @data = data ? JSON::parse(data) : nil
  end

  def self.create(data)
    wiki_page = RedmineWikiPage.new
    wiki_page.data = JSON::parse(data)
    return wiki_page
  end

  def self.read(filename)
    wiki_page = RedmineWikiPage.new
    wiki_page.data = JSON::parse(File.read(filename))
    return wiki_page
  end

  def text
    @data["wiki_page"]["text"]
  end

  def text=(text)
    @data["wiki_page"]["text"] = text
  end

  def title
    @data["wiki_page"]["title"]
  end

  def title=(title)
    @data["wiki_page"]["title"] = title
  end

  def version
    @data["wiki_page"]["version"]
  end

  def version=(version)
    @data["wiki_page"]["version"] = version
  end

  def next_wiki_page_title
    self.title =~ /([A-z]*)(\d*)/
    $1 + "%04d" % ($2.to_i + 1)
  end

  def previous_wiki_page_title
    self.title =~ /([A-z]*)(\d*)/
    $1 + "%04d" % ($2.to_i - 1)
  end
end
