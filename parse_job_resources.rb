# Parse job_resources.csv into a hash.  Ping each URL to check server status.
require 'pry'
require 'csv'
require 'net/http'

find_url = proc { |i| i[%r{http(s)?://}] }
file = 'job_resources_checked.csv'

def test_url(url)
  uri = URI(url)
  @res = Net::HTTP.get_response(uri)
  return true
rescue
  @res = 'Net:HTTP Error'
  return false
end

csv = CSV.read(file)
csv.each(&:compact!)

csv.each_with_index do |row|
  next unless (url = row.select(&find_url)[0])
  puts "Testing #{url}\n"
  res = test_url(url) ? @res.code : @res
  puts "Result: #{res}\n"
  row[1] = res
  if res == '301'
    redirect = @res.header['location']
    row[2] = redirect if test_url(redirect)
  end
end

CSV.open(file, 'wb') do |row|
  row << ['URLs last checked: ', Time.now]
  csv.shift
  csv.each do |new_row|
    row << new_row
  end
end
