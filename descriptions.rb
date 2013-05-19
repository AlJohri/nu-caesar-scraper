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
	json = Array.new
  @agent = Mechanize.new
	terms = get_json("terms", "class-descriptions")
	terms.each { |term| 
		next if (term['id'].to_i < 4490)
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
						next if (data.empty? or data['descriptions'].empty?)

						hash = {
							uniqueID: section['id'],
							term: term['id'],
							school: school['id'],
							subject: subject['abbv'],
							course: course['abbv'],
							section: section['section'],
              title: section['name'],
							description: data['descriptions'][0]['value']
						}
            json.push hash.to_json
            print "#{hash.to_json}\n\n"

					}
				}
			}
		}
	}
	File.open("description.json", 'w') { |file| file.write "[#{json}]"}
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

=begin
	
	# puts "#{section['id']} #{term['id']} #{school['id']} #{subject['abbv']} #{course['abbv']} #{section['name']}"
	# data['descriptions'].each { |description|
	# 	#puts "#{description['name']}: #{description['value']}"
	# }


	#overviewStr = "Overview of Class"
	#emptyStr = "Contact the department for further information"
	
			# file.write("#{section['id']} #{term['id']} #{school['id']} #{subject['abbv']} #{course['abbv']} #{section['name']}\n")
		# file.write("#{data['descriptions'][0]['value']}")
		# data['descriptions'].each { |description| 
		# 	#if !(description['name'] == overviewStr and (description['value'] == emptyStr or description['value'] == ""))
		# 	file.write("#{description['name']}: #{description['value']}\n")
		# 	#end
		# }
		# puts "#{section['id']} #{term['id']} #{school['id']} #{subject['abbv']} #{course['abbv']} #{section['name']}"	

=end
