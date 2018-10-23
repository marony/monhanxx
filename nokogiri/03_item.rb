require 'nokogiri'
require 'open-uri'
require 'uri'
require 'csv'

require 'bundler/setup'
require 'sqlite3'

# 「モンハンダブルクロスに対応！アイテム入手方法/使い道一覧（50音順）【随時更新中】」
url = 'http://mh-x.com/item_all.html'1

# アイテム一覧
#
# http://mh-x.com/item_all.html
# <article>
#   <div class="post">
#     <div class="the_content">
#       <table class="mum">
#         <tbody>
#           <tr>
#             <td width="20%"><a href="http://mh-x.com/item/アイルー茶釜.html" class="n">アイルー茶釜</a></td>
#             <td width="20%"><a href="http://mh-x.com/item/赫い龍液.html" class="n">赫い龍液</a><span class="c-dragon">[XX]</span></td>
def parse_items(url)
  no = 1
  items = []
  doc = Nokogiri::HTML.parse(open(url).read, nil, nil)
#  doc.xpath('//table[@class="mum"]//tbody//tr').each {|node|
  doc.xpath('//table[@class="mum"]//tr[./td]').each {|node|
      node.xpath('./td').each {|td|
        begin
          a = td.at('a')
          if a != nil then
            puts td.inner_text
            url2 = td.at('a')[:href]
            # 通番, URL
#            item = parse_item(url2)
            item = [no, td.inner_text]
            items << item
            no = no + 1
          end
        rescue => ex
          puts ex
          p ex.backtrace
          puts td.inner_text
          ef = open('item_error.txt', 'a')
          ef.write(ex)
          ef.write(td.inner_text)
          ef.close()
        end
      }
  }
  return items
end

# アイテム
#
# http://mh-x.com/item/%E3%82%A2%E3%82%A4%E3%83%AB%E3%83%BC%E8%8C%B6%E9%87%9C.html
# <article>
#   <div class="post">
#     <div class="the_content">
#       <table class="mum">
#         <tbody>
#           <tr>
#             <td width="20%"><a href="http://mh-x.com/item/アイルー茶釜.html" class="n">アイルー茶釜</a></td>
#             <td width="20%"><a href="http://mh-x.com/item/赫い龍液.html" class="n">赫い龍液</a><span class="c-dragon">[XX]</span></td>
def parse_item(url)
  puts url
  no = 1
  items = []
  doc = Nokogiri::HTML.parse(open(URI.escape(url)).read, nil, nil)
#  doc.xpath('//table[@class="mum"]//tbody//tr').each {|node|
  doc.xpath('//table[@class="mum"]').each {|node|
      p node
      node.xpath('/td').each {|td|
        begin
          item = []
          a = td.at('a')
          if a != nil then
            puts td.inner_text
            url2 = td.at('a')[:href]
            # 通番, URL
            item << [no, td.inner_text, url2]
            items << item
            no = no + 1
          end
        rescue => ex
          puts ex
          p ex.backtrace
          puts td.inner_text
          ef = open('item_error.txt', 'a')
          ef.write(ex)
          ef.write(tr.inner_text)
          ef.close()
        end
      }
  }
  return items
end

items = parse_items(url)

CSV.open("item.csv", "w") {|csv|
  items.each {|row|
    csv << row
  }
}

db = SQLite3::Database.new('monhan.db') 

db.execute("DELETE FROM item;")

items.each {|row|
  sql = <<-SQL
INSERT INTO item
(id, name)
VALUES (?, ?);
  SQL
  begin
    p row
    db.execute(sql, row[0], row[1])
  rescue => ex
    puts ex
    p ex.backtrace
    puts row
  end
}

