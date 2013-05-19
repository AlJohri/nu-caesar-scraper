require 'Mechanize'
require 'debugger'

username = "username"
password = "password"
unique_id = ARGV[0]
ajax_headers = { 'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8' }
caesar_params = { "ICAJAX" => "1", "ICNAVTYPEDROPDOWN" => "0", "ICType" => "Panel", "ICXPos" => "0", "ICYPos" => "0", "ResponsetoDiffFrame" => "-1", "TargetFrameName" => "None", "GSrchRaUrl" => "None", "FacetPath" => "None", "ICFocus" => "", "ICSaveWarningFilter" => "0", "ICChanged" => "-1", "ICResubmit" => "0", "ICActionPrompt" => "false", "ICFind" => "", "ICAddCount" => "" }

agent = Mechanize.new
agent.agent.ssl_version = "SSLv3"
page = agent.get('https://ses.ent.northwestern.edu/psp/s9prod/?cmd=login')
login_form = page.form('login')
login_form.set_fields(:userid => username)
login_form.set_fields(:pwd => password)
login_form.action = 'https://ses.ent.northwestern.edu/psp/caesar/?cmd=?languageCd=ENG'
page = agent.submit(login_form, login_form.buttons.first)
doc = agent.get("https://ses.ent.northwestern.edu/psc/caesar_5/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL?Page=SSR_SSENRL_CART&Action=A&ACAD_CAREER=UGRD&EMPLID=2678688&INSTITUTION=NWUNV&STRM=4500&TargetFrameName=None").parser

# Get variable_params and construct base_params #

icsid = doc.xpath("//*[@id='ICSID']/@value").text
icelementnum = doc.xpath("//*[@id='ICElementNum']/@value").text
icstatenum = doc.xpath("//*[@id='ICStateNum']/@value").text
variable_params = { "ICElementNum" => icelementnum, "ICStateNum" => icstatenum, "ICSID" => icsid }
base_params = caesar_params.merge(variable_params)

# Assemble addcart_params #
addcart_stub_params = {
	"DERIVED_REGFRM1_CLASS_NBR" => unique_id,
	"ICAction" => "DERIVED_REGFRM1_SSR_PB_ADDTOLIST2$69$", "DERIVED_SSTSNAV_SSTS_MAIN_GOTO$22$" => "9999",
	"DERIVED_REGFRM1_SSR_CLS_SRCH_TYPE$75$" => "06", "DERIVED_SSTSNAV_SSTS_MAIN_GOTO$155$" => "9999",
	"P_SELECT$chk$0" => "N", "P_SELECT$chk$2" => "N", "P_SELECT$chk$3" => "N", "P_SELECT$chk$4" => "N",
	"P_SELECT$chk$5" => "N", "P_SELECT$chk$6" => "N", "P_SELECT$chk$7" => "N", "P_SELECT$chk$8" => "N",
	"P_SELECT$chk$9" => "N", "P_SELECT$chk$10" => "N", "P_SELECT$chk$11" => "N", "P_SELECT$chk$12" => "N"
}
addcart_params = addcart_stub_params.merge(base_params)

# Add to shopping cart step 1 - enter number in box and press enter #

response = agent.post('https://ses.ent.northwestern.edu/psc/caesar_5/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL', addcart_params, ajax_headers)
doc = Nokogiri::HTML(response.body)

message = doc.xpath("//div[@id='win5divDERIVED_SASSMSG_ERROR_TEXT$0']").text
if message.include? ("This class is already in your Shopping Cart."); abort("This class is already in your Shopping Cart."); end

title = doc.xpath("//div[@id='win5divDERIVED_REGFRM1_TITLE1']").text
if !title.include? ("Select classes to add"); abort("Some error ocurred in Step 1"); end

sectioncheck = doc.xpath("//div[@id='win5divSSR_CLS_TBL_R1$0']")
if !sectioncheck.empty?; abort("This course has multiple sections. We currently do not support this feature."); end

# SSR_CLS_TBL_R1$sels$0:1
# SSR_CLS_TBL_R1$sels$0:0


# Get variable_params and construct base_params #

icsid = doc.xpath("//*[@id='ICSID']/@value").text
icelementnum = doc.xpath("//*[@id='ICElementNum']/@value").text
icstatenum = doc.xpath("//*[@id='ICStateNum']/@value").text
variable_params = { "ICElementNum" => icelementnum, "ICStateNum" => icstatenum, "ICSID" => icsid }
base_params = caesar_params.merge(variable_params)

# Assemble pressnext_params #
pressnext_stub_params = { "ICAction" => "DERIVED_CLS_DTL_NEXT_PB$76$", 
	"DERIVED_SSTSNAV_SSTS_MAIN_GOTO$4$" => "9999", "DERIVED_CLS_DTL_CLASS_PRMSN_NBR$52$" => "", 
	"DERIVED_SSTSNAV_SSTS_MAIN_GOTO$106$" => "9999" 
}
pressnext_params = pressnext_stub_params.merge(base_params)

# Add to shopping cart step 2 - press next to confirm OR choose section / laboratory #

response = agent.post('https://ses.ent.northwestern.edu/psc/caesar_5/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES_2.SSR_SSENRL_CART.GBL', pressnext_params, ajax_headers)
doc = Nokogiri::HTML(response.body)

message = doc.xpath("//div[@id='win5divDERIVED_SASSMSG_ERROR_TEXT$0']").text
puts message
