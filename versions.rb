#!/usr/bin/env ruby -w

require 'yaml'
require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'
require 'open-uri'

config = YAML.load_file('versions.yml')

class AtlassianVersion
  BASEURL = "https://my.atlassian.com/download/feeds/current/"
  attr_accessor :product, :url

  # check Atlassian page for latest release
  def latest
    a_url = BASEURL + product + ".json"
    page_content = Net::HTTP.get(URI.parse(a_url))

    if page_content.start_with?("downloads")
      versions = JSON.parse(page_content[10..-2])[1]
    end

    # we dont really care which OS versions is available, so just grab first
    # array item
    versions['version']
  end

  # what is installed on instance we care about
  def installed
    page = Nokogiri::HTML(open(url))

    case @product
      when "confluence"
        confluenceVersion(page)
      when "jira"
        jiraVersion(page)
      when "stash"
        stashVersion(page)
      when "crowd"
        crowdVersion(page)
      else
        puts "No product detected for #{product}"
    end
  end

  def confluenceVersion(str)
    str.css("span#footer-build-information")[0].text
  end

  def jiraVersion(str)
    str.css("input[title='JiraVersion']")[0]["value"]
  end

  def stashVersion(str)
    str.css("span#product-version")[0].text[2..-1]
  end

  def crowdVersion(str)
    str.css("div.footer-body p")[0].text.match(/(\d+\.\d+\.\d+) /)
  end
end

config.each do |product, value|
  p         =  AtlassianVersion.new
  p.product = value['type']
  p.url     = value['url']
  puts "%-10s\tCurrent: %-8s\tLatest: %-8s\n" % [product, p.installed, p.latest]
end
