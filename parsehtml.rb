require 'mechanize'

agent = Mechanize.new
doc = agent.get("https://dl.dropbox.com/u/2623300/nu_wholecat_201213.html").parser

query = doc.search(".sa.c1.l0.w0.r0")

query.each { |x|
	puts x.text
}

#query.each { |x| puts x.text if (x =~ /^[\w\s]+ \d+-\d+ .*/) }