# Parse job_resources.csv into a hash.  Ping each URL to check server status.
require 'pry'
require 'csv'
require 'net/http'

find_url = Proc.new {|i| i[/http/]}
file = 'job_resources_checked.csv'


def test_url(url)
  begin
    uri = URI(url[/http.+(\/|$)/])
    @res = Net::HTTP.get_response(uri)
    # http = Net::HTTP.new(uri.host, uri.port)
    # http.read_timeout = 15
    # http.open_timeout = 15
    # @res = http.start() do |http|
    #   http.get(url)
    # end
    return true
  rescue
    @res = "Net:HTTP Error"
    return false
  end
end

csv = CSV.read(file)
csv.each do |arr|
  arr.compact!
end

csv.each_with_index do |row|
  next unless url = row.select(&find_url)[0]
  next if row[1] == '200' || row[1] == '302'
  puts "Testing #{url}\n"
  test_url(url) ? res = @res.code : res = @res
  puts "Result: #{res}\n"
  row[1] = res
  if res == '301'
    redirect = @res.header['location']
    if test_url(redirect)
      row[2] = redirect
    end
  end
end

CSV.open(file, "wb") do |row|
  csv.each do |new_row|
    row << new_row
  end
end
