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
page = agent.get('https://ses.ent.northwestern.edu/psc/caesar_5/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL?Page=SSR_SSENRL_CART&Action=A&EMPLID=2678688&TargetFrameName=None&PortalActualURL=https%3a%2f%2fses.ent.northwestern.edu%2fpsc%2fcaesar_5%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL%3fPage%3dSSR_SSENRL_CART%26Action%3dA%26EMPLID%3d2678688%26TargetFrameName%3dNone&PortalContentURL=https%3a%2f%2fses.ent.northwestern.edu%2fpsc%2fcaesar_5%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL&PortalContentProvider=HRMS&PortalCRefLabel=Enrollment%20Shopping%20Cart&PortalRegistryName=EMPLOYEE&PortalServletURI=https%3a%2f%2fses.ent.northwestern.edu%2fpsp%2fcaesar_5%2f&PortalURI=https%3a%2f%2fses.ent.northwestern.edu%2fpsc%2fcaesar_5%2f&PortalHostNode=HRMS&NoCrumbs=yes&PortalKeyStruct=yes')
doc = page.parser

#course: win5divP_CLASS_NAME$0
#timings: win5divDERIVED_REGFRM1_SSR_MTG_SCHED_LONG$0
#proff: win5divDERIVED_REGFRM1_SSR_INSTR_LONG$0
#credits: win5divSSR_REGFORM_VW_UNT_TAKEN$0
#status: win5divDERIVED_REGFRM1_SSR_STATUS_LONG$0

numCourses = doc.xpath("//table[@id='SSR_REGFORM_VW$scroll$0']/tr").size - 2

events = Array.new

numCourses.times { |i|
	doc.xpath("//div[@id='win5divP_CLASS_NAME$" + i.to_s + "']").text.gsub(/\n|\r/, "") =~ /(^\w+ \d+-\d+-\d+) \((\d+)\)/
	course = $1
 	id = $2

 	doc.xpath("//div[@id='win5divDERIVED_REGFRM1_SSR_MTG_SCHED_LONG$" + i.to_s + "']").text.gsub(/\n|\r/, "") =~ /^(\w+) (\d\d?:\d\d(AM|PM)) - (\d\d?:\d\d(AM|PM))/
 	days = $1
 	start = $2
 	endd = $4

 	professor = doc.xpath("//div[@id='win5divDERIVED_REGFRM1_SSR_INSTR_LONG$" + i.to_s + "']").text.gsub(/\n|\r/, "")

 	days =~ /(Mo|Tu|We|Th|Fr)(Mo|Tu|We|Th|Fr)?(Mo|Tu|We|Th|Fr)?(Mo|Tu|We|Th|Fr)?(Mo|Tu|We|Th|Fr)?/
 	days = [$1, $2, $3, $4, $5]
 	days.delete(nil)

 	days.map! {|x| 
 		if (x == "Mo"); x = "Monday";
 		elsif (x == "Tu"); x = "Tuesday";
 		elsif (x == "We"); x = "Wednesday"; 
		elsif (x == "Th"); x = "Thursday"; 
		elsif (x == "Fr"); x = "Friday";
		end
 	}

 	if (days.size > 1); days[-1] = "and #{days.last}"; end

 	days = days.size > 2 ? days.join(", ") : days.join(" ")
 	events.push ("#{course} (#{id}) #{days} #{start} - #{endd} Weekly")
 }

puts events

puts "Time elapsed: #{Time.now - beginning} seconds."
