#!/usr/bin/env ruby

require 'mechanize'
require 'json'
require 'debugger'

# CONSTANTS

BASE1 = "http://www.northwestern.edu/class-descriptions/"
BASE2 = "http://www.northwestern.edu"
EXT1 = "/index.json"
EXT2 = ".json"

def scrape_descriptions
	@agent = Mechanize.new
	terms = get_json("terms", "class-descriptions")
	terms.each { |term| 
		next if (term['id'].to_i < 4400)
		schools = get_json("schools", term['id'])
		next if (schools.empty?)
		schools.each { |school|
			subjects = get_json("subjects", term['id'], school['id'])
			next if (subjects.empty?)
			subjects.each { |subject| 
				courses = get_json("courses", subject['path'])
				next if (courses.empty?)
				courses.each { |course|
					sections = get_json("sections", course['path'])
					next if (sections.empty?)
					sections.each { |section|
						data = get_json("data", section['path'])
						next if (data.empty?)
						puts "#{section['id']} #{term['id']} #{school['id']} #{subject['abbv']} #{course['abbv']} #{section['name']}"
						data['descriptions'].each { |description|
							#puts "#{description['name']}: #{description['value']}"
						}
					}
				}
			}
		}
	}
end

def get_json(type, *paths)
	case type
		when /^(terms)$/						; page = @agent.get(BASE1 + EXT1[1..-1])
		when /^(schools|subjects)$/ ; page = @agent.get(BASE1 + paths.join('/') + EXT1)
		when /^(courses|sections)$/ ; page = @agent.get(BASE2 + paths.join('/') + EXT1)
		when /^(data)$/							; page = @agent.get(BASE2 + paths.join('/') + EXT2)
	end
	text = page.body.gsub(/(var )?\w+\s?=\s?([\[\{])/, '\2').gsub(/\;\/\/<xml><\/xml>/, "").gsub(/\t/,"").gsub(/([^:{[,]])"([\w'\s]+)"([" ])/, '\1\2\3 ')
	return (text != "<xml/>") ? JSON.parse(text) : ""
end

scrape_descriptions













# def parse_shit(shit)
# 	shit = shit.gsub(/(var )?\w+\s?=\s?([\[\{])/, '\2').gsub(/\;\/\/<xml><\/xml>/, "").gsub(/\t/,"")
# 	shit = shit.gsub(/([^:{[,]])"([\w'\s]+)"([" ])/, '\1\2\3 ')
# 	return JSON.parse(shit)
# end

# def no_html(shit) ; return Nokogiri::HTML(shit).xpath("//text()").remove.to_s; end


#JSON.parse (data.gsub("var data = ", "").gsub(/;\/\/<xml><\/xml>/, ""))

=begin
	
	# shit = shit.gsub(/"Others"/, "Others") #Random special case 1
	# shit = shit.gsub(/"Ion"/, "Ion")  #Random special case 2
	# shit = shit.gsub(/"Blue House"/, "Blue House") #Random special case 3
	#shit = shit.gsub(/"Weird"/, "Weird") #Random special case 4
	# shit = shit.gsub(/"You Tube"/, "You Tube") #Random special case 5
	# shit = shit.gsub(/"Islamic Jihad"/, "Islamic Jihad")
	# shit = shit.gsub(/"Phaedo"/, "Phaedo")
	# shit = shit.gsub(/"The"/, "The")
	# shit = shit.gsub(/"Protagoras"/, "Protagoras")
	# shit = shit.gsub(/"Murder Speeches"/, "Murder Speeches")
	# shit = shit.gsub(/"Mad Men"/, "Mad Men")

	#shit = shit.gsub(/[^:]"([\w\s]+)"[^:]/, ' \1 ')
	#shit = shit.gsub(/[^:{,]"(\w+)"/, ' \1')
	#shit = shit.gsub(/[^:{[,]]"([\w\s]+)""/, ' \1"') # Generic Special Case Regex
	#shit = shit.gsub(/[^:{[,]]"([\w\s]+)"([" ])/, ' \1\2 ')
	#shit = shit.gsub(/([^:{[,]])"([\w\s]+)"([" ])/, '\1\2\3 ')

							overviewStr = "Overview of Class"
							emptyStr = "Contact the department for further information"

							# data['descriptions'].each { |description| 
							# 	if (description['name'] == overviewStr and (description['value'] == emptyStr or description['value'] == ""))
							# 		empty = true
							# 	elsif (description['name'] == overviewStr)
							# 		puts description
							# 	end
							# }

								#filename = "#{section['id']} #{term['id']} #{school['id']} #{subject['abbv']} #{course['abbv']} #{section['name']}.txt"
								#filename = no_html(filename.gsub(/\//,"-"))

=end


=begin
	
page = agent.get(class_descriptions + term['id'] + "/index.json")
schools = parse_shit(page)

page = agent.get(class_descriptions + term['id'] + "/" + school['id'] + "/index.json")
subjects = parse_shit(page)

page = agent.get(base + subject['path'] + "/index.json")
courses = parse_shit(page)

page = agent.get(base + course['path'] + "/index.json")
next if (page.body == "<xml/>")
sections = parse_shit(page)

page = agent.get(base + section['path'] + ".json")
next if (page.body == "<xml/>")
data = parse_shit(page)

=end