#!/usr/bin/env ruby

require 'mechanize'
require 'net/https'

beginning = Time.now

agent = Mechanize.new

agent.agent.http.ca_file = '/usr/local/Cellar/openssl/1.0.1c/cacert.pem'
agent.agent.ssl_version = "SSLv3"

page = agent.get('https://ses.ent.northwestern.edu/psp/s9prod/?cmd=login')

login_form = page.form('login')
login_form.set_fields(:userid => ARGV[0]) 
login_form.set_fields(:pwd => ARGV[1])
login_form.action = 'https://ses.ent.northwestern.edu/psp/caesar/?cmd=?languageCd=ENG'

page = agent.submit(login_form, login_form.buttons.first)
page = agent.get('https://ses.ent.northwestern.edu/psc/caesar/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL?ACAD_CAREER=UGRD&INSTITUTION=NWUNV&STRM=4480')
doc = page.parser

numCourses = doc.xpath("//table[@id='ACE_STDNT_ENRL_SSV2$0']/tr/td[@valign='top']").size

# puts numCourses

i = 0
doc.xpath("//table[@id='ACE_STDNT_ENRL_SSV2$0']/tr/td[@valign='top']/div/table/tr/td[@class='PAGROUPDIVIDER']").each{ |x|
	i += 1
	pp [
			x.text,
			doc.xpath("//span[@id='DERIVED_CLS_DTL_CLASS_NBR$" + i.to_s + "']").text,
			doc.xpath("//a[@id='MTG_SECTION$" + i.to_s + "']").text,
			doc.xpath("//span[@id='MTG_COMP$" + i.to_s + "']").text,
			doc.xpath("//span[@id='MTG_SCHED$" + i.to_s + "']").text,
			doc.xpath("//span[@id='MTG_LOC$" + i.to_s + "']").text,
			doc.xpath("//span[@id='DERIVED_CLS_DTL_SSR_INSTR_LONG$" + i.to_s + "']").text,
			doc.xpath("//span[@id='MTG_DATES$" + i.to_s + "']").text,
		]
}
=begin
numCourses.times { |i| 
 	pp [
 			doc.xpath("//span[@id='DERIVED_CLS_DTL_CLASS_NBR$" + i.to_s + "']").text,
 			doc.xpath("//a[@id='MTG_SECTION$" + i.to_s + "']").text,
 			doc.xpath("//span[@id='MTG_COMP$" + i.to_s + "']").text,
 			doc.xpath("//span[@id='MTG_SCHED$" + i.to_s + "']").text,
 			doc.xpath("//span[@id='MTG_LOC$" + i.to_s + "']").text,
 			doc.xpath("//span[@id='DERIVED_CLS_DTL_SSR_INSTR_LONG$" + i.to_s + "']").text,
 			doc.xpath("//span[@id='MTG_DATES$" + i.to_s + "']").text,
 		]
 }
=end
puts "Time elapsed: #{Time.now - beginning} seconds."

#pp page.search("div[@id='win0divSTDNT_ENRL_SSV2$0']").text
#pp doc.xpath("//div[@id='win0divSTDNT_ENRL_SSV2$0']")

# "//span[@id='DERIVED_CLS_DTL_CLASS_NBR$" + i.to_s +  "']"

# doc.css("div[@id='win0divSTDNT_ENRL_SSV2$0'] tr").map{|x| 
# 	puts
# 		[
# 			x.at("span[@id='DERIVED_CLS_DTL_CLASS_NBR$0'").text, 
# 			x.at("a[@id='MTG_SECTION$0'").text,
# 			x.at("span[@id='MTG_COMP$0'").text,
# 			x.at("span[@id='MTG_SCHED$0'").text,
# 			x.at("span[@id='MTG_LOC$0'").text,
# 			x.at("span[@id='DERIVED_CLS_DTL_SSR_INSTR_LONG$0'").text,
# 			x.at("span[@id='MTG_DATES$0'").text,
# 		]
# }

# doc.css("div[@id='win0divSTDNT_ENRL_SSV2$0']/tr").map{|x| puts x.text}

# win0divDERIVED_CLS_DTL_CLASS_NBR$0 -> DERIVED_CLS_DTL_CLASS_NBR$0
# win0divMTG_SECTION$0 -> MTG_SECTION$0
# win0divMTG_COMP$0 -> MTG_COMP$0
# win0divMTG_SCHED$0 -> MTG_SCHED$0
# win0divMTG_LOC$0 -> MTG_LOC$0
# win0divDERIVED_CLS_DTL_SSR_INSTR_LONG$0 -> DERIVED_CLS_DTL_SSR_INSTR_LONG$0
# win0divMTG_DATES$0 -> MTG_DATES$0
