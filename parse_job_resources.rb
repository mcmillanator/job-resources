# Parse job_resources.csv into a hash.  Ping each URL to check server status.
require 'pry'
require 'csv'
require 'net/http'

find_url = proc { |i| i[%r{http(s)?://}] }
file = 'job_resources_checked.csv'

def test_url(url, idx)
	@arr[idx] = Array.new
	@arr[idx] << url
  puts "Testing #{url}"
  uri = URI(url)
  res = Net::HTTP.get_response(uri)
	if res.code == '301'
		redirect = res.header['location']
		@arr[idx][2] = redirect
	end
	res = res.code
rescue
	res = 'Net:HTTP Error'
ensure
  @arr[idx][1] = res
end

csv = CSV.read(file)
csv.each(&:compact!)
@arr = []
@threads = Array.new
csv.each_with_index do |row, idx|
  next unless (url = row.select(&find_url)[0])
  @threads << Thread.new do
		test_url(url, idx) 
	#	row[1] = res
	end
end
@threads.each(&:join)
puts @arr
puts csv.count
puts @arr.count
