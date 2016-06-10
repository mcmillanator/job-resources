# Parse job_resources.csv into a hash.  Ping each URL to check server status.
require 'pry'
require 'csv'
require 'net/http'

csv = CSV.read('job_resources.csv')
new_csv = []
csv.each do |arr|
  arr.compact!
  arr.pop if arr.length > 1
  new_csv.concat(arr)
end

urls = Hash.new {|urls, key| urls[key] = []}

new_csv.each do |val|
  if val[/http/] == 'http'
    urls[@key] << {
                    url: val,
                    status: nil
                  }
  else
    @key = val.downcase.gsub('/','').gsub(/ {1,}/,"_").to_sym
  end
end
urls.each do |group, arr|
  arr.each do |hash|
    hash[:url]
    next unless hash[:status] == nil
    uri = URI(hash[:url])
    begin
      res = Net::HTTP.get_response(uri)
    rescue
      # this rescue was written when SSL cert check failed causing Net:HTTP
      # to trow and error crashing the script
      puts "Get request failed"
      hash[:status] == 'Net:HTTP Error'
      next
    end
    puts res.code
    hash[:status] = res.code
  end
end
print urls

CSV.open('job_resources_checked.csv', "wb") do |csv|
  urls.each do |key, arr|
    csv << [key.to_s]
    arr.each do |hash|
      csv << [hash[:url], hash[:status]]
    end
  end
end
