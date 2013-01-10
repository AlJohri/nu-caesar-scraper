#!/usr/bin/env ruby

require 'mechanize'
require 'net/https'
require 'io/console'

################################################################################################################################

class CAESAR

	def initialize(username, password)
		@agent = Mechanize.new
		@username = username
		@password = password
	end	

	def connect()
		@agent.agent.http.ca_file = '/usr/local/Cellar/openssl/1.0.1c/cacert.pem'
		@agent.agent.ssl_version = "SSLv3"
		@page = @agent.get('https://ses.ent.northwestern.edu/psp/s9prod/?cmd=login')
		login_form = @page.form('login')
		login_form.set_fields(:userid => @username) #ARGV[0]
		login_form.set_fields(:pwd => @password) #ARGV[1]
		login_form.action = 'https://ses.ent.northwestern.edu/psp/caesar/?cmd=?languageCd=ENG'
		@page = @agent.submit(login_form, login_form.buttons.first)
	end

	def course_list()
		@page = @agent.get('https://ses.ent.northwestern.edu/psc/caesar/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL?ACAD_CAREER=UGRD&INSTITUTION=NWUNV&STRM=4480')
		doc = @page.parser

		numCourses = doc.xpath("//table[@id='ACE_STDNT_ENRL_SSV2$0']/tr/td[@valign='top']").size

		courses = Array.new

		i = 0
		doc.xpath("//table[@id='ACE_STDNT_ENRL_SSV2$0']/tr/td[@valign='top']/div/table/tr/td[@class='PAGROUPDIVIDER']").each{ |x|
			i += 1

			# Course, ID, Section, Location, Professor, and Type
		  course = x.text
		  id = doc.xpath("//span[@id='DERIVED_CLS_DTL_CLASS_NBR$" + i.to_s + "']").text
		  section = doc.xpath("//a[@id='MTG_SECTION$" + i.to_s + "']").text
		  location = doc.xpath("//span[@id='MTG_LOC$" + i.to_s + "']").text
		  professor = doc.xpath("//span[@id='DERIVED_CLS_DTL_SSR_INSTR_LONG$" + i.to_s + "']").text
		  type = doc.xpath("//span[@id='MTG_COMP$" + i.to_s + "']").text
		  
		  # Date/Time
		 	doc.xpath("//span[@id='MTG_SCHED$" + i.to_s + "']").text.gsub(/\n|\r/, "") =~ /^(\w+) (\d\d?:\d\d(AM|PM)) - (\d\d?:\d\d(AM|PM))/
		 	days = $1
		 	start_time = $2
		 	end_time = $4

		 	# Convert abbreviations for days to full form for Google Calendar Quick Add
		 	days =~ /(Mo|Tu|We|Th|Fr)(Mo|Tu|We|Th|Fr)?(Mo|Tu|We|Th|Fr)?(Mo|Tu|We|Th|Fr)?(Mo|Tu|We|Th|Fr)?/
		 	days = [$1, $2, $3, $4, $5]
		 	days.delete(nil)
		 	days.map! {|x| 
		 		if (x == "Mo"); x = "Monday"
		 		elsif (x == "Tu"); x = "Tuesday"
		 		elsif (x == "We"); x = "Wednesday"
				elsif (x == "Th"); x = "Thursday" 
				elsif (x == "Fr"); x = "Friday"
				end
		 	}
		 	if (days.size > 1); days[-1] = "and #{days.last}"; end
		 	days = days.size > 2 ? days.join(", ") : days.join(" ")

		  course = "#{course} (#{id}) #{days} #{start_time} - #{end_time} Weekly until 3/16 at #{location}"
		  courses.push course

		  #GoogleCL Stuff
		  #command = "google calendar add \"#{course}\" --cal \"Course Schedule\""
		  #system command
		}

		return courses

	end

	def shopping_cart()
		@page = @agent.get('https://ses.ent.northwestern.edu/psc/caesar_5/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL?Page=SSR_SSENRL_CART&Action=A&EMPLID=2678688&TargetFrameName=None&PortalActualURL=https%3a%2f%2fses.ent.northwestern.edu%2fpsc%2fcaesar_5%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL%3fPage%3dSSR_SSENRL_CART%26Action%3dA%26EMPLID%3d2678688%26TargetFrameName%3dNone&PortalContentURL=https%3a%2f%2fses.ent.northwestern.edu%2fpsc%2fcaesar_5%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL&PortalContentProvider=HRMS&PortalCRefLabel=Enrollment%20Shopping%20Cart&PortalRegistryName=EMPLOYEE&PortalServletURI=https%3a%2f%2fses.ent.northwestern.edu%2fpsp%2fcaesar_5%2f&PortalURI=https%3a%2f%2fses.ent.northwestern.edu%2fpsc%2fcaesar_5%2f&PortalHostNode=HRMS&NoCrumbs=yes&PortalKeyStruct=yes')
		doc = @page.parser

		numCourses = doc.xpath("//table[@id='SSR_REGFORM_VW$scroll$0']/tr").size - 2

		courses = Array.new

		numCourses.times { |i|
			# Course, ID
			doc.xpath("//div[@id='win5divP_CLASS_NAME$" + i.to_s + "']").text.gsub(/\n|\r/, "") =~ /(^\w+ \d+-\d+-\d+) \((\d+)\)/
			course = $1
		 	id = $2

		 	# Professor, Location
		 	professor = doc.xpath("//div[@id='win5divDERIVED_REGFRM1_SSR_INSTR_LONG$" + i.to_s + "']").text.gsub(/\n|\r/, "")
		  location = doc.xpath("//div[@id='win5divDERIVED_REGFRM1_SSR_MTG_LOC_LONG$" + i.to_s + "']").text.gsub(/\n|\r/, "")

		 	# Date/Time
		 	doc.xpath("//div[@id='win5divDERIVED_REGFRM1_SSR_MTG_SCHED_LONG$" + i.to_s + "']").text.gsub(/\n|\r/, "") =~ /^(\w+) (\d\d?:\d\d(AM|PM)) - (\d\d?:\d\d(AM|PM))/
		 	days = $1
		 	start_time = $2
		 	end_time = $4

		 	# Convert abbreviations for days to full form for Google Calendar Quick Add		 	
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

		  course = "#{course} (#{id}) #{days} #{start_time} - #{end_time} Weekly until 3/16 at #{location}"
		 	courses.push course

		  #GoogleCL Stuff
		  #command = "google calendar add \"#{course}\" --cal \"Shopping Cart\""
		 	#system command
		}

		return courses

	end

end

################################################################################################################

if __FILE__ == $0

	beginning = Time.now

	if (ARGV.length == 0)
		print "What is your netID?: ";
		username = gets.chop
	else
		username = ARGV[0]; 
	end

	if (ARGV.length <= 1); 
		print "What is your password?: ";
		password = STDIN.noecho(&:gets).chop; 
		puts ""
	else
		password = ARGV[1]; end

	caesar = CAESAR.new(username, password)
	caesar.connect()
	puts caesar.course_list()
	puts caesar.shopping_cart()

	puts "Time elapsed: #{Time.now - beginning} seconds."

end

################################################################################################################