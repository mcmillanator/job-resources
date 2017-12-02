# Parse job_resources.csv into a hash.  Ping each URL to check server status.
require 'pry'
require 'csv'
require 'net/http'

@arr = []
@new_csv = Array.new
@file = 'job_resources_checked.csv'
@new_file = @file
@find_url = proc { |i| i[%r{http(s)?://}] }


def test_url(url)
  puts "Testing #{url}"
  uri = URI(url)
	res = Net::HTTP.get_response(uri)
rescue => e
	res = false 
ensure
  res
end

def read_csv
	csv = CSV.read(@file)
	csv.each(&:compact!)
	csv.each do |row|
		@new_csv << Thread.new do
			url = row.select(&@find_url).first
			if url 
				res = test_url(url)
				if res
					row = [url, res.code]
					if res.code.to_i >= 300 && res.code.to_i <= 399
						redirect = res.header['location']	
						row << redirect
					end
				else
					row = [url, 'Failed to process url']
				end
			end
			row
		end
	end
	@new_csv.each(&:join)
end

def parse_results
	arr = Array.new
	@new_csv.shift
	@new_csv.each do |i|
		arr << i.value
	end
	arr
end

def write_csv
	CSV.open(@new_file, 'wb') do |row|
		row << ['URLs last checked: ', Time.now]
		parse_results.each do |arr|
			row << arr unless arr.nil?
		end
	end
end

read_csv
write_csv
