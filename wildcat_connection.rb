#!/usr/bin/env ruby

require 'mechanize'
require 'net/https'
require 'io/console'

agent = Mechanize.new

(1..51).each { |i|
	doc = agent.get("https://northwestern.collegiatelink.net/organizations?SearchType=None&SelectedCategoryId=0&CurrentPage=" + i.to_s).parser
	doc.search('//div[@id="results"]/div/h5/a').each {|x| 
		name = x.text
		doc2 = agent.get("https://northwestern.collegiatelink.net" + x.attributes['href']).parser
		url = doc2.search('//a[@class="icon-social facebook"]')[0]
		if (url)
			url = url.attributes['href'].value
			puts name + " - " + url
		else
			puts name
		end
		
	}
}

# https://northwestern.collegiatelink.net/organizations?SearchType=None&SelectedCategoryId=0&CurrentPage=1
# https://northwestern.collegiatelink.net/organizations?SearchType=None&SelectedCategoryId=0&CurrentPage=51