# Parse job_resources.csv into a hash.  Ping each URL to check server status.
require 'pry'
require 'csv'
require 'net/http'

@arr = []
@file = 'job_resources_checked.csv'
@new_file = 'out' 
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
	csv.shift
	csv
end

def parse_csv(csv)
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
	arr.map! do |row|
		row = row.split(',') if row.class == String
		row.map {|i| row.index(i) == row.count-1 ? "| #{i} |" : "| #{i} "}
	end
	arr.insert(1, ['| ------------- | ------------- | ------------- |'])
end

def write_markdown(arr)
	file = File.open('TEST.md', 'w')
	arr.map!(&:join)
	arr.map!{|i| "#{i}\n" unless i.empty?}.compact!
	arr.each do |row|
		file.write(row) 
	end
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
md = markdown_table(csv)
# csv = parse_csv(csv)
write_markdown(md)
#write_csv(csv)
