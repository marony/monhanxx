require 'nokogiri'
require 'open-uri'

i = 1
++i
puts i
puts ++i
puts i

charset = nil

no = 1
doc = Nokogiri::HTML.parse(File.open('test.html'), nil, charset)
doc.xpath('//div[contains(@class,"section")][1]/table[@class="mum"]/tbody/tr').each do |node|
  puts "length = " + (node.xpath('td').length).to_s
  node.xpath('td').each do |td|
    p no, td.inner_text
  end
  no = no + 1
end

