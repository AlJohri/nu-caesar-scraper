#!/usr/bin/env ruby

#encoding: ascii-8bit

require 'rubygems'
require 'mechanize'
require 'net/https'
require 'io/console'
require 'sequel'
require 'json'
require 'colorize'
require 'cgi'
require 'debugger'

################################################################################################################################

class CAESAR
  attr_accessor :agent, :page, :username, :password

	def initialize(username, password)
		@agent = Mechanize.new
		@username = username
		@password = password
	end

	def connect()
		@agent.agent.http.ca_file = '/usr/local/Cellar/openssl/1.0.1c/cacert.pem'
		#@agent.agent.http.ca_file = 'cacert.pem'
		@agent.agent.ssl_version = "SSLv3"
		@page = @agent.get('https://ses.ent.northwestern.edu/psp/s9prod/?cmd=login')
	end

	def authenticate()
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

		i = 0; k = 0
		doc.xpath("//table[@id='ACE_STDNT_ENRL_SSV2$0']/tr/td[@valign='top']/div/table/tr/td[@class='PAGROUPDIVIDER']").each { |x|

			parts = doc.xpath("//table[@id='CLASS_MTG_VW$scroll$" + i.to_s + "']/tr").size-1
			x.text =~ /(^\w+ \d+)(-\d+ - )(.+)/
			name = $1
			caption = $3

			parts.times { |j|
				# Course, ID, Section, Location, Professor, and Type
			  id = doc.xpath("//span[@id='DERIVED_CLS_DTL_CLASS_NBR$" + k.to_s + "']").text
			  section = doc.xpath("//a[@id='MTG_SECTION$" + k.to_s + "']").text
			  location = doc.xpath("//span[@id='MTG_LOC$" + k.to_s + "']").text
			  professor = doc.xpath("//span[@id='DERIVED_CLS_DTL_SSR_INSTR_LONG$" + k.to_s + "']").text
			  type = doc.xpath("//span[@id='MTG_COMP$" + k.to_s + "']").text

			  # Date/Time
			 	doc.xpath("//span[@id='MTG_SCHED$" + k.to_s + "']").text.gsub(/\n|\r/, "") =~ /^(\w+) (\d\d?:\d\d(AM|PM)) - (\d\d?:\d\d(AM|PM))/
			 	days = $1
			 	start_time = $2
			 	end_time = $4

			 	days_orig = days

			 	# Convert abbreviations for days to full form for Google Calendar Quick Add
			 	days = convert_days(days)

			  course = Hash.new
			  course['name'] = "#{name}-#{section}"
			  course['title'] = caption
			  course['id'] = id
			  course['days'] = days_orig
			  course['start_time'] = start_time
			  course['end_time'] = end_time
			  course['location'] = location

			  courses.push course
			  #JSON.generate course

			  #GoogleCL
			  #event = "#{name}-#{section} #{caption} (#{id}) #{days} #{start_time} - #{end_time} Weekly until 3/16 at #{location}"
			  #command = "google calendar add \"#{event}\" --cal \"Course Schedule\""

			  k += 1 # Actual Course (e.g. Chem XXX Lecture or Chem XXX Lab)
			}

			i += 1 # Course Category (e.g. Chem XXX)

		}

		return courses

	end

	def shopping_cart()
		debugger
		@page = @agent.get('https://ses.ent.northwestern.edu/psc/caesar_5/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL?Page=SSR_SSENRL_CART&Action=A&TargetFrameName=None')
		#https://ses.ent.northwestern.edu/psc/caesar_5/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL?Page=SSR_SSENRL_CART&Action=A&TargetFrameName=None&PortalActualURL=https%3a%2f%2fses.ent.northwestern.edu%2fpsc%2fcaesar_5%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL%3fPage%3dSSR_SSENRL_CART%26Action%3dA%26EMPLID%3d2678688%26TargetFrameName%3dNone&PortalContentURL=https%3a%2f%2fses.ent.northwestern.edu%2fpsc%2fcaesar_5%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL&PortalContentProvider=HRMS&PortalCRefLabel=Enrollment%20Shopping%20Cart&PortalRegistryName=EMPLOYEE&PortalServletURI=https%3a%2f%2fses.ent.northwestern.edu%2fpsp%2fcaesar_5%2f&PortalURI=https%3a%2f%2fses.ent.northwestern.edu%2fpsc%2fcaesar_5%2f&PortalHostNode=HRMS&NoCrumbs=yes&PortalKeyStruct=yes')
		doc = @page.parser

		numCourses = doc.xpath("//table[@id='SSR_REGFORM_VW$scroll$0']/tr").size - 2

		courses = Array.new

		numCourses.times { |i|
			# Course, ID
			doc.xpath("//div[@id='win5divP_CLASS_NAME$" + i.to_s + "']").text.gsub(/\n|\r/, "") =~ /(^\w+ \d+-\d+-\d+) \((\d+)\)/
			name = $1
		 	id = $2

		 	# Professor, Location
		 	professor = doc.xpath("//div[@id='win5divDERIVED_REGFRM1_SSR_INSTR_LONG$" + i.to_s + "']").text.gsub(/\n|\r/, "")
		  location = doc.xpath("//div[@id='win5divDERIVED_REGFRM1_SSR_MTG_LOC_LONG$" + i.to_s + "']").text.gsub(/\n|\r/, "")

		 	# Date/Time
		 	doc.xpath("//div[@id='win5divDERIVED_REGFRM1_SSR_MTG_SCHED_LONG$" + i.to_s + "']").text.gsub(/\n|\r/, "") =~ /^(\w+) (\d\d?:\d\d(AM|PM)) - (\d\d?:\d\d(AM|PM))/
		 	days = $1
		 	start_time = $2
		 	end_time = $4

		 	days_orig = days

		 	# Convert abbreviations for days to full form for Google Calendar Quick Add
		 	days = convert_days(days)

		  course = Hash.new
		  course['name'] = name
		  course['title'] = ""
		  course['id'] = id
		  course['days'] = days_orig
		  course['start_time'] = start_time
		  course['end_time'] = end_time
		  course['location'] = location

		  courses.push course
		  #JSON.generate course

		  #GoogleCL
		  #event = "#{name} (#{id}) #{days} #{start_time} - #{end_time} Weekly until 3/16 at #{location}"
		  #command = "google calendar add \"#{event}\" --cal \"Shopping Cart\""
		  #puts command
		}

		return courses

	end

	def course_history()
		@page = @agent.get('https://ses.ent.northwestern.edu/psc/caesar_7/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.SSS_MY_CRSEHIST.GBL?Page=SSS_MY_CRSEHIST&Action=U&ForceSearch=Y&TargetFrameName=None')
		doc = @page.parser

		numCourses = doc.xpath("//table[@id='CRSE_HIST$scroll$0']/tr").size - 2

		courses = Array.new

		numCourses.times { |i|
			name = doc.xpath("//span[@id='CRSE_NAME$" + i.to_s + "']").text
			title = doc.xpath("//a[@id='CRSE_LINK$" + i.to_s + "']").text
			term = doc.xpath("//span[@id='CRSE_TERM$" + i.to_s + "']").text
			grade = doc.xpath("//span[@id='CRSE_GRADE$" + i.to_s + "']").text
			units = doc.xpath("//span[@id='CRSE_UNITS$" + i.to_s + "']").text
			#status #win5divCRSE_STATUS$0

			course = Hash.new
			course['name'] = name
			course['title'] = title
			course['term'] = term
			course['grade'] = grade
			course['units'] = units

			courses.push course
			#JSON.generate course

		}

		return courses

	end

	# DERIVED_CLSRCH_SSR_CLASSNAME_LONG$0
	# MTG_DAYTIME$0
	# MTG_ROOM$0
	# MTG_INSTR$0
	# MTG_TOPIC$0
	# 
	# MTG_DAYTIME$1
	# MTG_ROOM$1
	# MTG_INSTR$1
	# MTG_TOPIC$1
	# 
	# DERIVED_CLSRCH_SSR_CLASSNAME_LONG$1
	# MTG_DAYTIME$2

	def scrape_courses()

		datescraped = Time.now

		db = Sequel.connect(:adapter => 'pg', :user => 'atul', :host => 'localhost', :database => 'caesar', :password=>'')
    
    db.create_table! :courses do
      primary_key :id
      String :uniqueid
      String :dept
      String :course
      String :sec
      String :title
      String :days
      String :start_time
      String :end_time
      String :room
      String :instructor
      String :seats
      String :status
      String :datescraped
    end

    course_list = db[:courses]

    error_counter = 0 

		#File.delete("database.txt") if File.exist?("database.txt")
		@@subjects.each { |key, value|

			@page = @agent.get('https://ses.ent.northwestern.edu/psc/caesar_6/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.CLASS_SEARCH.GBL?Page=SSR_CLSRCH_ENTRY')
			doc = @page.parser
			icsid = doc.xpath("//*[@id='ICSID']/@value").text
			icelementnum = doc.xpath("//*[@id='ICElementNum']/@value").text
			icstatenum = doc.xpath("//*[@id='ICStateNum']/@value").text

			institution = "NWUNV"
			subject = key #ARGV[0]
			match_type = "E"
			career = "UGRD"
			open_course_only = "N"
			term = "4490"

			ajax_headers = { 'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8'}
			params = {
				"ICAction" => "CLASS_SRCH_WRK2_SSR_PB_CLASS_SRCH",
				"ICSID" => icsid,
				"ICElementNum" => icelementnum,
				"ICStateNum" => icstatenum,
				"DERIVED_SSTSNAV_SSTS_MAIN_GOTO$26$" => "9999",
				"CLASS_SRCH_WRK2_INSTITUTION$49$" => institution,
				"CLASS_SRCH_WRK2_STRM$52$"=> term,
				"CLASS_SRCH_WRK2_SUBJECT$65$"=> subject,
				"CLASS_SRCH_WRK2_CATALOG_NBR$73$" => "",
				"CLASS_SRCH_WRK2_SSR_EXACT_MATCH1" => match_type,
				"CLASS_SRCH_WRK2_ACAD_CAREER" => career,
				"CLASS_SRCH_WRK2_SSR_OPEN_ONLY$chk" => open_course_only,
				"DERIVED_SSTSNAV_SSTS_MAIN_GOTO$152$"=>"9999"
			}

			response = @agent.post('https://ses.ent.northwestern.edu/psc/caesar_4/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.CLASS_SEARCH.GBL', params, ajax_headers)
			doc  = Nokogiri::HTML(response.body)

			error = doc.search("span[id^='DERIVED_CLSMSG_ERROR_TEXT']/text()")
			courses = doc.search("span[id^='DERIVED_CLSRCH_DESCR200$']/text()").to_a

			partsCounter = 0

      if (error.empty?)
			  courses.each_with_index { |x,i| 
          courses[i] = CGI.unescapeHTML(courses[i].to_s).delete!("^\u{0000}-\u{007F}")
          courses[i] =~ /(^\w+)(\s+)(\d+-\d+) - (.*)/

          department = $1
          course = $3
          title = $4
					parts = doc.search("div[id='win6div$ICField108GP$" + i.to_s + "'] > table > tr > td[2] > span[3]/text()").to_s.gsub(/1.*of\s/, "").to_i

          parts.times { |x|
          	uniqueid_sec = doc.search("a[id='DERIVED_CLSRCH_SSR_CLASSNAME_LONG$" + partsCounter.to_s + "']").text
          	uniqueid_sec =~ /(\w+)-\w+\((\d+)\)/
          	sec = $1
          	uniqueid = $2

          	days_time = doc.search("span[id='MTG_DAYTIME$" + partsCounter.to_s + "']").text
          	if (days_time != "TBA")
	          	days_time =~ /^(\w+) (\d\d?:\d\d(AM|PM)) - (\d\d?:\d\d(AM|PM))/
						 	days = $1
						 	start_time = $2
						 	end_time = $4
						else
							days = "TBA"
							start_time = "TBA"
							end_time = "TBA"
						end

          	room = doc.search("span[id='MTG_ROOM$" + partsCounter.to_s + "']").text
          	instructor = doc.search("span[id='MTG_INSTR$" + partsCounter.to_s + "']").text
          	dates = doc.search("span[id='MTG_TOPIC$" + partsCounter.to_s + "']").text
          	seats = doc.search("span[id='NW_DERIVED_SS3_AVAILABLE_SEATS$" + partsCounter.to_s + "']").text
          	status = doc.search("div[id='win6divDERIVED_CLSRCH_SSR_STATUS_LONG$" + partsCounter.to_s + "'] > div > img")[0]['alt']

          	#puts status
            
            #debugger

            # http://stackoverflow.com/questions/452859/inserting-multiple-rows-in-a-single-sql-query
            course_list.insert(:uniqueid => uniqueid, :dept => department, :course => course, :sec => sec, :title => title, :days => days, :start_time => start_time, :end_time => end_time, :room => room, :instructor => instructor, :seats => seats, :status => status, :datescraped => datescraped)
          	partsCounter+=1
          }
          
        }
      else
      	error = error.to_s
      	error = error.gsub("The search returns no results that match the criteria specified.", "No courses this quarter.")
      	error = error.gsub("Your search will exceed the maximum limit of 200 sections.  Specify additional criteria to continue.", "Exceeds maximum limit.")
        error_counter+=1
        print "[" + error_counter.to_s + "] " + key + ": "
        if (error.include? "No courses this quarter.")
          puts error
        elsif (error.include? "Exceeds maximum limit.")
          puts error.yellow
        else
        	puts error.red
        end
      end
	
      #courses = CGI.unescapeHTML(courses.join("\n")) + "\n"
			#File.open("database.txt", 'a') { |file| file.write( !error.empty? ? key + ": " + error.to_s + "\n" : courses ) }
 
      #puts "Completed #{key}"

		}

	end

	def backup_database()
		exec '/usr/local/bin/mysqldump -u atul --databases caesar > caesar.sql'
	end

	def convert_days(days)
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
	 	return days
	end

end

################################################################################################################

def define_hashes()
	@@institutions = {
		"NWUNV" => "Northwestern University",
	}

	@@careers = {
		"SPCG" => "Communication Grad",
		"CNED" => "Continuing Education",
		"CGRD" => "Continuing Education Grad",
		"CNCR" => "Continuing Noncredit",
		"EDG"	 => "Education Grad",
		"MGMT" => "J L Kellogg School Management",
		"JRNG" => "Journalism Grad",
		"EMP"	 => "Kellogg Executive Masters Prog",
		"LAW"	 => "Law",
		"ENGG" => "McCormick Engg Grad",
		"MUSG" => "Music Grad",
		"NDGR" => "Non-Degree",
		"PT" => "Physical Therapy",
		"PA" => "Physician Assistant",
		"PO" => "Prosthetics Orthotics",
		"TGS" => "The Graduate School",
		"UGRD" => "Undergraduate",
	}

	@@match_types = {
		"C" => "contains",
		"G" => "greater than or equal to",
		"E" => "exactly",
		"T" => "less than",
	}

	@@subjects = {
		"ACCOUNT" => "ACCOUNT - Accounting",
		"ACCT" => "ACCT - Accounting & Info Systems",
		"ACCTX" => "ACCTX - Accounting & Info Systems",
		"ADVT" => "ADVT - Advertising",
		"AFST" => "AFST - African Studies",
		"AF_AM_ST" => "AF_AM_ST - African American Studies",
		"ALT_CERT" => "ALT_CERT - Alternative Certification",
		"AMER_ST" => "AMER_ST - American Studies",
		"AMES" => "AMES - Asian & Middle Eastern Studies",
		"ANTHRO" => "ANTHRO - Anthropology",
		"APP_PHYS" => "APP_PHYS - Applied Physics",
		"ARABIC" => "ARABIC - Arabic",
		"ART" => "ART - Art Theory & Practice",
		"ART_HIST" => "ART_HIST - Art History",
		"ASIAN_AM" => "ASIAN_AM - Asian American Studies",
		"ASTRON" => "ASTRON - Astronomy",
		"BIOL_SCI" => "BIOL_SCI - Biological Sciences",
		"BLAW" => "BLAW - Business Law",
		"BMD_ENG" => "BMD_ENG - Biomedical Engineering",
		"BUS_ALYS" => "BUS_ALYS - Business Analyst",
		"BUS_INST" => "BUS_INST - Business Institutions",
		"BUS_LAW" => "BUS_LAW - Business Law",
		"CFS" => "CFS - Chicago Field Studies",
		"CHEM" => "CHEM - Chemistry",
		"CHEM_ENG" => "CHEM_ENG - Chemical Engineering",
		"CHINESE" => "CHINESE - Chinese",
		"CHSS" => "CHSS - Comp & Hist Social Science",
		"CIC" => "CIC - CIC Traveling Scholar",
		"CIS" => "CIS - Computer Information Systems",
		"CIV_ENV" => "CIV_ENV - Civil & Envrnmtl Engineering",
		"CLASSICS" => "CLASSICS - Classics - Readings in Englis",
		"CLIN_PSY" => "CLIN_PSY - Clinical Psychology",
		"CLIN_RES" => "CLIN_RES - Clinical Research & Reg Admin",
		"CME" => "CME - Chicago Metropolitan Exchange",
		"CMN" => "CMN - Communication Related Courses",
		"COG_SCI" => "COG_SCI - Cognitive Science",
		"COMM_ST" => "COMM_ST - Communication Studies",
		"COMP_LIT" => "COMP_LIT - Comparative Literary Studies",
		"CONDUCT" => "CONDUCT - Conducting",
		"COUN_PSY" => "COUN_PSY - Counseling Psychology",
		"CRDV" => "CRDV - Career Development",
		"CSD" => "CSD - Comm Sci & Disorders",
		"DANCE" => "DANCE - Dance",
		"DECS" => "DECS - Mngrl Econ & Decision Sci",
		"DECSX" => "DECSX - Mngrl Econ & Decision Sci",
		"DIV_MED" => "DIV_MED - Divorce Mediation Training",
		"DSGN" => "DSGN - Segal Design Institute",
		"EARTH" => "EARTH - Earth and Planetary Sciences",
		"ECON" => "ECON - Economics",
		"EECS" => "EECS - Elect Engineering & Comp Sci",
		"ENGLISH" => "ENGLISH - English",
		"ENTR" => "ENTR - Entrepreneurship",
		"ENVR_POL" => "ENVR_POL - Environmental Policy & Culture",
		"ENVR_SCI" => "ENVR_SCI - Environmental Science",
		"EPI_BIO" => "EPI_BIO - Epidemiology & Biostats",
		"ES_APPM" => "ES_APPM - Engineering Sci & Applied Mat",
		"EXMMX" => "EXMMX - Executive Master in Management",
		"FINANCE" => "FINANCE - Finance",
		"FINC" => "FINC - Finance",
		"FINCX" => "FINCX - Finance",
		"FN_EXTND" => "FN_EXTND - CFP Extended",
		"FRENCH" => "FRENCH - French",
		"GBL_HLTH" => "GBL_HLTH - Global Health",
		"GENET_CN" => "GENET_CN - Genetic Counseling",
		"GEN_CMN" => "GEN_CMN - General Comm & Intro Courses",
		"GEN_ENG" => "GEN_ENG - General Engineering",
		"GEN_LA" => "GEN_LA - General Liberal Arts",
		"GEN_MUS" => "GEN_MUS - General Music",
		"GEOG" => "GEOG - Geography",
		"GERMAN" => "GERMAN - German",
		"GNDR_ST" => "GNDR_ST - Gender Studies",
		"GREEK" => "GREEK - Greek",
		"HDPS" => "HDPS - Human Develop & Psych Svcs",
		"HDSP" => "HDSP - Human Development & Social Pol",
		"HEBREW" => "HEBREW - Hebrew",
		"HEMA" => "HEMA - Health Enterprise Management",
		"HINDI" => "HINDI - Hindi",
		"HISTORY" => "HISTORY - History",
		"HQS" => "HQS - Hlthcare Quality & Pat Safety",
		"HSR" => "HSR - Health Services Research",
		"HUM" => "HUM - Humanities",
		"IBIS" => "IBIS - Interdepartmental Bio Sciences",
		"IEMS" => "IEMS - Indust Eng & Mgmt Sciences",
		"IGP" => "IGP - Integ Life Sciences",
		"IMC" => "IMC - Integ Marketing Communication",
		"INF_TECH" => "INF_TECH - Information Technology",
		"INTG_SCI" => "INTG_SCI - Integrated Science",
		"INTL" => "INTL - International Business",
		"INTLX" => "INTLX - International Business",
		"INTL_ST" => "INTL_ST - International Studies",
		"IPLS" => "IPLS - Liberal Studies",
		"ISEN" => "ISEN - Initiative Sustain & Energy",
		"ITALIAN" => "ITALIAN - Italian",
		"JAPANESE" => "JAPANESE - Japanese",
		"JAZZ_ST" => "JAZZ_ST - Jazz Studies",
		"JOUR" => "JOUR - Journalism",
		"JRN_WRIT" => "JRN_WRIT - Journalistic Writing",
		"JWSH_ST" => "JWSH_ST - Jewish Studies",
		"JW_LEAD" => "JW_LEAD - Jewish Leadership",
		"KELLG_FE" => "KELLG_FE - Financial Economics",
		"KELLG_MA" => "KELLG_MA - Managerial Analytics",
		"KOREAN" => "KOREAN - Korean",
		"LATIN" => "LATIN - Latin",
		"LATINO" => "LATINO - Latina and Latino Studies",
		"LAWSTUDY" => "LAWSTUDY - Law Studies",
		"LDRSHP" => "LDRSHP - Leadership",
		"LEADERS" => "LEADERS - Leadership",
		"LEAD_ART" => "LEAD_ART - Art of Leadership",
		"LEGAL_ST" => "LEGAL_ST - Legal Studies",
		"LING" => "LING - Linguistics",
		"LIT" => "LIT - Literature",
		"LITARB" => "LITARB - Litigation and Arbitration",
		"LOC" => "LOC - Learning & Org Change",
		"LRN_SCI" => "LRN_SCI - Learning Sciences",
		"MATH" => "MATH - Mathematics",
		"MAT_SCI" => "MAT_SCI - Materials Science & Eng",
		"MBIOTECH" => "MBIOTECH - Masters in Biotechnology",
		"MCW" => "MCW - Master of Creative Writing",
		"MDVL_ST" => "MDVL_ST - Medieval Studies",
		"MECH_ENG" => "MECH_ENG - Mechanical Engineering",
		"MECN" => "MECN - Decision Sciences",
		"MECNX" => "MECNX - Decision Sciences",
		"MECS" => "MECS - Managerial Econ & Strategy",
		"MECSX" => "MECSX - Managerial Econ & Strategy",
		"MEDM" => "MEDM - Media Management",
		"MED_INF" => "MED_INF - Medical Informatics",
		"MED_SKIL" => "MED_SKIL - Mediation Skills Training",
		"MGMT" => "MGMT - Management",
		"MGMTX" => "MGMTX - Management",
		"MHB" => "MHB - Medical Humanities & Bioethics",
		"MKTG" => "MKTG - Marketing",
		"MKTGX" => "MKTGX - Marketing",
		"MMSS" => "MMSS - Math Methods in the Social Sc",
		"MORS" => "MORS - Management and Organizations",
		"MORSX" => "MORSX - Management and Organizations",
		"MPD" => "MPD - Master of Product Development",
		"MPPA" => "MPPA - Master of Public Policy Admin",
		"MSA" => "MSA - Sports Administration",
		"MSC" => "MSC - MS in Communication",
		"MSCI" => "MSCI - Master of Science in Clin Inv",
		"MSIA" => "MSIA - Master of Science in Analytics",
		"MSRC" => "MSRC - Master of Regulatory Complianc",
		"MSTP" => "MSTP - Medical Scientist Training",
		"MS_ED" => "MS_ED - MS in Educ & Social Policy",
		"MS_FT" => "MS_FT - MS in Marital & Family Therapy",
		"MS_HE" => "MS_HE - MS in Higher Ed Admin & Policy",
		"MS_LOC" => "MS_LOC - Learning & Org Change",
		"MTS" => "MTS - Media, Technology & Society",
		"MUSEUM" => "MUSEUM - Museum Studies",
		"MUSIC" => "MUSIC - Music",
		"MUSICOL" => "MUSICOL - Musicology",
		"MUSIC_ED" => "MUSIC_ED - Music Education",
		"MUS_COMP" => "MUS_COMP - Music Composition",
		"MUS_HIST" => "MUS_HIST - Music History & Lit",
		"MUS_TECH" => "MUS_TECH - Music Technology",
		"MUS_THRY" => "MUS_THRY - Music Theory",
		"NAV_SCI" => "NAV_SCI - Naval Science",
		"NEUROBIO" => "NEUROBIO - Neurobiology & Physiology",
		"NUIN" => "NUIN - Neuroscience",
		"OPNS" => "OPNS - Operations Management",
		"OPNSX" => "OPNSX - Operations Management",
		"ORG_BEH" => "ORG_BEH - Organizational Behavior",
		"ORTH" => "ORTH - Orthotics",
		"PBC" => "PBC - Plant Biology & Conservation",
		"PERF_ST" => "PERF_ST - Performance Studies",
		"PERSIAN" => "PERSIAN - Persian",
		"PHIL" => "PHIL - Philosophy",
		"PHIL_NP" => "PHIL_NP - Philanthropy & Nonprofit Fund",
		"PHYSICS" => "PHYSICS - Physics",
		"PHYS_TH" => "PHYS_TH - Physical Therapy",
		"PIANO" => "PIANO - Piano",
		"POLI_SCI" => "POLI_SCI - Political Science",
		"PORT" => "PORT - Portuguese",
		"PREDICT" => "PREDICT - Predictive Analytics",
		"PROJ_MGT" => "PROJ_MGT - Project Management",
		"PROJ_PMI" => "PROJ_PMI - Project Management",
		"PROS" => "PROS - Prosthetics",
		"PSYCH" => "PSYCH - Psychology",
		"PUB_HLTH" => "PUB_HLTH - Master's in Public Health",
		"QARS" => "QARS - Qual Assur & Reg Science",
		"REAL" => "REAL - Real Estate",
		"RELIGION" => "RELIGION - Religious Studies",
		"RTVF" => "RTVF - Radio/Television/Film",
		"SCS" => "SCS - School of Continuing Studies",
		"SEEK" => "SEEK - Social Enterprise",
		"SESP" => "SESP - SESP Core",
		"SHC" => "SHC - Science in Human Culture",
		"SLAVIC" => "SLAVIC - Slavic Languages & Literature",
		"SOCIOL" => "SOCIOL - Sociology",
		"SOC_POL" => "SOC_POL - Social Policy",
		"SPANISH" => "SPANISH - Spanish",
		"SPANPORT" => "SPANPORT - Spanish and Portuguese",
		"STAT" => "STAT - Statistics",
		"STRINGS" => "STRINGS - String Instruments",
		"SWAHILI" => "SWAHILI - Swahili",
		"TEACH_ED" => "TEACH_ED - Teacher Education",
		"TGS" => "TGS - TGS General Registrations",
		"TH&DRAMA" => "TH&DRAMA - Theatre & Drama",
		"THEATRE" => "THEATRE - Theatre",
		"TURKISH" => "TURKISH - Turkish",
		"URBAN_ST" => "URBAN_ST - Urban Studies",
		"VOICE" => "VOICE - Voice & Opera",
		"WIND_PER" => "WIND_PER - Wind & Percussion",
		"WRITING" => "WRITING - Writing Arts",
	}

	@@terms = {
		"4000" => "2000 Fall",
		"4005" => "2000-01 Academic Year",
		"4040" => "2001 Fall",
		"4020" => "2001 Spring",
		"4030" => "2001 Summer",
		"4010" => "2001 Winter",
		"4045" => "2001-02 Academic Year",
		"4080" => "2002 Fall",
		"4060" => "2002 Spring",
		"4070" => "2002 Summer",
		"4050" => "2002 Winter",
		"4085" => "2002-03 Academic Year",
		"4120" => "2003 Fall",
		"4100" => "2003 Spring",
		"4110" => "2003 Summer",
		"4090" => "2003 Winter",
		"4125" => "2003-04 Academic Year",
		"4160" => "2004 Fall",
		"4140" => "2004 Spring",
		"4150" => "2004 Summer",
		"4130" => "2004 Winter",
		"4165" => "2004-05 Academic Year",
		"4200" => "2005 Fall",
		"4180" => "2005 Spring",
		"4190" => "2005 Summer",
		"4170" => "2005 Winter",
		"4205" => "2005-06 Academic Year",
		"4240" => "2006 Fall",
		"4220" => "2006 Spring",
		"4230" => "2006 Summer",
		"4210" => "2006 Winter",
		"4245" => "2006-07 Academic Year",
		"4280" => "2007 Fall",
		"4260" => "2007 Spring",
		"4270" => "2007 Summer",
		"4250" => "2007 Winter",
		"4285" => "2007-08 Academic Year",
		"4320" => "2008 Fall",
		"4300" => "2008 Spring",
		"4310" => "2008 Summer",
		"4290" => "2008 Winter",
		"4325" => "2008-09 Academic Year",
		"4360" => "2009 Fall",
		"4340" => "2009 Spring",
		"4350" => "2009 Summer",
		"4330" => "2009 Winter",
		"4365" => "2009-10 Academic Year",
		"4400" => "2010 Fall",
		"4380" => "2010 Spring",
		"4390" => "2010 Summer",
		"4370" => "2010 Winter",
		"4405" => "2010-2011 Academic Year",
		"4440" => "2011 Fall",
		"4420" => "2011 Spring",
		"4430" => "2011 Summer",
		"4410" => "2011 Winter",
		"4445" => "2011-2012 Academic Year",
		"4480" => "2012 Fall",
		"4460" => "2012 Spring",
		"4470" => "2012 Summer",
		"4450" => "2012 Winter",
		"4485" => "2012-2013 Academic Year",
		"4500" => "2013 Spring",
		"4510" => "2013 Summer",
		"4490" => "2013 Winter",
	}
end

################################################################################################################

if __FILE__ == $0

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
		password = ARGV[1];
	end

	beginning = Time.now
	caesar = CAESAR.new(username, password)
	puts ""

	define_hashes()
	caesar.connect()
	connection_time = Time.now - beginning
	puts "Connection Took #{connection_time} seconds.\n"

	caesar.authenticate()
	authenticate_time = (Time.now - beginning) - connection_time
	puts "Authentication Took #{authenticate_time} seconds.\n\n"

	puts caesar.course_list()
	puts caesar.shopping_cart()
	puts caesar.course_history()
	#caesar.backup_database()
	#caesar.scrape_courses()

	puts "Total time elapsed: #{Time.now - beginning} seconds."

end

################################################################################################################




          	# TuTh 11:00AM - 12:20PM
          	# Leverone Auditorium Owen Coon
          	# 

          	# MTG_DAYTIME$0
          	# MTG_ROOM$0
          	# MTG_INSTR$0
          	# MTG_TOPIC$0
          	#
          	# win5divDERIVED_CLSRCH_SSR_STATUS_LONG$1
          	# 
          	# NW_DERIVED_SS3_AVAILABLE_SEATS$2
