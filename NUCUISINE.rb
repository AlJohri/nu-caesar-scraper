#!/usr/bin/env ruby

require 'mechanize'
require 'net/https'
require 'io/console'

################################################################################################################################

class NUCUISINE

	def initialize(username, password)
		@agent = Mechanize.new
		@username = username
		@password = password
	end	

	def connect()
		@agent.add_auth("https://go.dosa.northwestern.edu/uhfs/foodservice/balancecheck", @username, @password)
		@page = @agent.get("https://go.dosa.northwestern.edu/uhfs/foodservice/balancecheck")
	end

	def balance_check()
		doc = @page.parser
		name = doc.xpath('//div[@id="content"]/table/tr[1]/td[2]').text
		plan = doc.xpath('//div[@id="content"]/table/tr[2]/td[2]').text
		board_meals = doc.xpath('//div[@id="content"]/table/tr[3]/td[2]').text
		equiv_meals = doc.xpath('//div[@id="content"]/table/tr[4]/td[2]').text
		points = doc.xpath('//div[@id="content"]/table/tr[5]/td[2]').text
		munch_money = doc.xpath('//div[@id="content"]/table/tr[6]/td[2]').text
		munch_money_bonus = doc.xpath('//div[@id="content"]/table/tr[7]/td[2]').text

		return [name, plan, board_meals, equiv_meals, points, munch_money, munch_money_bonus]
	end

end

################################################################################################################

if __FILE__ == $0

	beginning = Time.now

	if (ARGV.length == 0)
		print "What is your netID?: "
		username = gets.chop
	else
		username = ARGV[0]; 
	end

	if (ARGV.length <= 1); 
		print "What is your password?: "
		password = STDIN.noecho(&:gets).chop; 
		puts ""
	else
		password = ARGV[1]; end

	nucuisine = NUCUISINE.new(username, password)
	nucuisine.connect()
	puts "Connection Took #{Time.now - beginning} seconds."
	puts nucuisine.balance_check()
	puts "Balance Check Took #{Time.now - beginning} seconds."

	puts "Total time elapsed: #{Time.now - beginning} seconds."

end

################################################################################################################