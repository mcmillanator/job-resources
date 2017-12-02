# Parse job_resources.csv into a hash.  Ping each URL to check server status.
require 'pry'
require 'csv'
require 'net/http'

@arr = []
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
end

def parse_csv(csv)
	csv.shift
	threads = Array.new
	csv.each do |row|
		threads << Thread.new do
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
	threads.each(&:join)
	threads.map {|i| i.value}
end

def markdown_table(arr)
	binding.pry
end

def write_csv(arr)
	CSV.open(@new_file, 'wb') do |row|
		row << ['URLs last checked: ', Time.now]
		arr.each do |arr|
			row << arr unless arr.nil?
		end
	end
end

csv = read_csv
csv = parse_csv(csv)
write_csv(csv)
