# Parse job_resources.csv into a hash.  Ping each URL to check server status.
require 'pry'
require 'csv'
require 'net/http'

def test_url(url)
  begin
    uri = URI(url[/http.+(\/|$)/])
    puts "Testing #{url}\n"
    @res = Net::HTTP.get_response(uri)
    return true
  rescue
    @res = "Net:HTTP Error"
    return false
  end
end

csv = CSV.read('job_resources.csv')
csv.each do |arr|
  arr.compact!
end

find_url = Proc.new {|i| i[/http/]}

csv.each_with_index do |row|
  next unless url = row.select(&find_url)[0]
  next if row[1] == '200' || row[1] == '302'
  test_url(url) ? res = @res.code : res = @res
  puts "Result: #{res}\n"
  row[1] = res
  if res == '301'
    redirect = @res.header['location']
    if test_url(redirect) && @res.code == "200"
      row[0] = redirect
      row[1] = '200'
    end
  end
end

CSV.open('job_resources_checked.csv', "wb") do |row|
  csv.each do |new_row|
    row << new_row
  end
end
