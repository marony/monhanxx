require 'nokogiri'
require 'open-uri'
require 'uri'
require 'csv'

require 'bundler/setup'
require 'sqlite3'

# 「モンハンダブルクロス 攻略情報コミュニティ（MHXX）」
url = 'http://mh-x.com/'

# 防具シリーズレア度
#
# http://mh-x.com/
# <article>
#   <div class="post">
#     <div class="cols">
#       <div class="section-box">
#         <table class="deco txt-c mu0>
#           <tbody>
#             <tr>
#               <td><a href="http://mh-x.com/weapon/def_rare_x_kensi.html">2つ名装備</a></td>
def parse_armor_series_rare(url)
  no = 1
  no2 = 1
  armor_series = []
  doc = Nokogiri::HTML.parse(open(url).read, nil, nil)
  doc.xpath('//table[contains(@class,"deco txt-c")]//td//a').each {|node|
    begin
      # 通番, レア度, URL
      name = node.inner_text
      url2 = node[:href]
      armor_series2, no2 = parse_armor_series(no, no2, name, url2)
      armor_series = armor_series + armor_series2
      no = no + 1
      # FIXME: デバッグ用
      #break
    rescue => ex
      puts ex
      p ex.backtrace
      puts no2, name
      ef = open('armor_error.txt', 'a')
      ef.write(ex)
      ef.write(no2.to_s + ", " + name)
      ef.close()
    end
  }
  return armor_series
end

# 防具シリーズ
#
# http://mh-x.com/weapon/def_rare_x_kensi.html"
# <article>
#   <div class="post">
#     <table class="tdesign1 mum">
#       <tbody>
#         <tr>
#           <td><a href="http://mh-x.com/weapon/series/剣士大雪主.html">大雪主シリーズ</a></td>
#           <td>110</td>
#           <td class="ttd-c">G級<br>770</td>
#           <td class="ttd-c">0</td>
#           <td class="ttd-c bg-fire smanone-cell">-20</td>
#           <td class="ttd-c bg-aqua smanone-cell">15</td>
#           <td class="ttd-c bg-thunder smanone-cell">-10</td>
#           <td class="ttd-c bg-ice smanone-cell">20</td>
#           <td class="ttd-c bg-dragon smanone-cell">0</td>
#           <td><ul class="list-none"><li>回復速度+2</li><li>真・大雪主の魂</li><li>飛燕</li><li>大雪主の魂</li></ul></td>
#           <td><ul class="list-none"><li>回復速度+15</li>
#             <li>真・大雪主+10</li>
#             <li>跳躍+10</li>
#             <li>大雪主+10</li>
#             </ul>
#           </td>
def parse_armor_series(no, no2, name, url)
  armor_series = []
  doc = Nokogiri::HTML.parse(open(url).read, nil, nil)
  doc.xpath('//table[@class="tdesign1 mum"]//tbody//tr').each {|node|
    begin
      # TODO: url.contains("kensi") 剣士 else ガンナー
      han_type = 2
      han_type = 1 if url.include?('kensi')
      armor = []
      url2 = nil
      node.xpath('./td').each {|tr|
        # 通番, 防具シリーズレア度通番, レア度, 防具シリーズ名, 防御力初期, 防御力最大, スロット, 火耐性, 水耐性, 雷耐性, 氷耐性, 龍耐性, 発動スキル, スキルポイント合計, URL, ハンタータイプ
        if url2 == nil
          url2 = tr.at('a')[:href]
        end
        if armor.length == 9
          # 発動スキル(複数)
          skills = []
          tr.xpath('ul//li').each {|li|
            skills << li.inner_text
          }
          armor << skills
        elsif armor.length == 10
          # スキルポイント合計(複数)
          points = []
          tr.xpath('ul//li').each do |li|
            v = li.inner_text
            v = v.split(/([+-])/)
            points << v
          end
          armor << points
        else
          armor << tr.inner_text
        end
        if armor.length >= 11
          armor_series << [no2, no, name] + armor + [url2, han_type]
          armor = []
          no2 = no2 + 1
          url2 = nil
        end
      }
    rescue => ex
      puts ex
      p ex.backtrace
      puts no2, name
      ef = open('armor_error.txt', 'a')
      ef.write(ex)
      ef.write(no2.to_s + ", " + name)
      ef.close()
    end
  }
  return armor_series, no2
end

def init_armor(no3, no2, no, armor_series_rare, armor_series, defence, max_defence, slot, fire, water, thunder, ice, dragon, skills, points, url, han_type)
  # 防具シリーズ通番, 防具シリーズレア度通番, レア度, 防具シリーズ名, 防御力初期, 防御力最大, スロット, 火耐性, 水耐性, 雷耐性, 氷耐性, 龍耐性, 発動スキル, スキルポイント合計, URL, ハンタータイプ
  armor = []
  for i in 1..5
    # 通番, ハンタータイプ, 防具シリーズ通番, 防具シリーズレア度通番, 防具シリーズ名, 部位, 防具名, スキルポイント, 生産必要素材, 部位, 防具名, スロット, 防御力(初期), 防御力(最大), 火耐性, 水耐性, 雷耐性, 氷耐性, 龍耐性
    # 部位と防具名がダブってるけど気にしない
    armor << [no3, han_type, no2, no, armor_series]
    no3 += 1
  end
  return no3, armor
end

# 防具
#
# http://mh-x.com/weapon/series/%E5%89%A3%E5%A3%AB%E5%A4%A7%E9%9B%AA%E4%B8%BB.html
# <article>
#   <div class="post>
#     <div class="section">
#       <table class="mum">
#         <tbody>
#           <tr>
#             <td class="ttd-c">頭</td>
#             <td><a href="http://mh-x.com/weapon/d/大雪主ヘルム.html">大雪主ヘルム</a></td>
#             <td><a href="http://mh-x.com/skill/回復速度.html">回復速度</a>+3<br><a href="http://mh-x.com/skill/跳躍.html">跳躍</a>+2<br><a href="http://mh-x.com/skill/大雪主.html">大雪主</a>+2<br><a href="http://mh-x.com/skill/真・大雪主.html">真・大雪主</a>+2</td>
#             <td><a href="http://mh-x.com/item/大雪主狩猟の証1.html">大雪主狩猟の証1</a>x1<br><a href="http://mh-x.com/item/大雪主の毛.html">大雪主の毛</a>x3<br><a href="http://mh-x.com/item/白兎獣の耳.html">白兎獣の耳</a>x4<br><a href="http://mh-x.com/item/大きな骨.html">大きな骨</a>x4</td>
#       <div class="section">
#         <table class="mum">
#           <tbody>
#             <tr>
#               <td class="ttd-c">頭</td>
#               <td><a href="http://mh-x.com/weapon/d/大雪主ヘルム.html">大雪主ヘルム</a></td>
#               <td class="ttd-c">0</td>
#               <td class="ttd-c">22</td>
#               <td class="ttd-c">G級<br>154</td>
#               <td class="bg-fire ttd-c">-4</td>
#               <td class="bg-aqua ttd-c">3</td>
#               <td class="bg-thunder ttd-c">-2</td>
#               <td class="bg-ice ttd-c">4</td>
#               <td class="bg-dragon ttd-c">0</td>
def parse_armors(armor_series)
  no3 = 1
  armors = []
  armor_series.each {|no2, no, armor_series_rare, armor_series, defence, max_defence, slot, fire, water, thunder, ice, dragon, skills, points, url, han_type|
    begin
      doc = Nokogiri::HTML.parse(open(URI.escape(url)).read, nil, nil)
      no3, armor = init_armor(no3, no2, no, armor_series_rare, armor_series, defence, max_defence, slot, fire, water, thunder, ice, dragon, skills, points, url, han_type)
      puts "no = " + no3.to_s + ", " + armor_series
      prev_l = 0
      i = 0
      doc.xpath('//div[contains(@class,"section")][1]/table[@class="mum"]/tbody/tr').each do |node|
        l = node.xpath('td').length
        node.xpath('td').each {|td|
          if prev_l != l
            i = 0
            prev_l = l
            if l == 4 && armor[0].length > 4
              armors = armors + armor
              no3, armor = init_armor(no3, no2, no, armor_series_rare, armor_series, defence, max_defence, slot, fire, water, thunder, ice, dragon, skills, points, url, han_type)
            end
          end
          if l == 4
            # 部位, 防具名, スキルポイント, 生産必要素材
            v = td.inner_text
            if (i % 4) == 2
              td.search('br').each do |br|
                br.replace('\n')
              end
              v = td.inner_text.split('\n')
              v.map! {|c| c.split(/([+-])/)}
            elsif (i % 4) == 3
              td.search('br').each do |br|
                br.replace('\n')
              end
              v = td.inner_text.split('\n')
              v.map! {|c| c.split(/x/)}
            end 
            armor[i / 4] << v
          elsif l == 10
            # 部位, 防具名, スロット, 防御力(初期), 防御力(最大), 火耐性, 水耐性, 雷耐性, 氷耐性, 龍耐性
            armor[i / 10] << td.inner_text
          end
          i = i + 1
        }
      end
      armors = armors + armor
      no3, armor = init_armor(no3, no2, no, armor_series_rare, armor_series, defence, max_defence, slot, fire, water, thunder, ice, dragon, skills, points, url, han_type)
    rescue => ex
      puts ex
      p ex.backtrace
      puts no2, no, armor_series_rare, armor_series, url
      ef = open('armor_error.txt', 'a')
      ef.write(ex)
      ef.write(no2.to_s + ", " + no.to_s + ", " + armor_series_rare + ", " + armor_series + ", " + url)
      ef.close()
    end
  }
  return armors
end

armor_series = parse_armor_series_rare(url)
armors = parse_armors(armor_series)

CSV.open("armor_series.csv", "w") {|csv|
  armor_series.each {|row|
    csv << row
  }
}

CSV.open('armor.csv', "w") {|csv|
  armors.each {|row|
    csv << row
  }
}

db = SQLite3::Database.new('monhan.db') 

db.execute("DELETE FROM armor_series;")
db.execute("DELETE FROM armor_series_skills;")
db.execute("DELETE FROM armor_series_skill_point;")
db.execute("DELETE FROM armor;")
db.execute("DELETE FROM armor_skill_point;")

armor_series.each {|row|
  p row
  sql1 = <<-SQL
INSERT INTO armor_series
(id, name, rare, initial_defense, max_defense, slot,
 fire_resistance, water_resistance, thunder_resistance, ice_resistance, dragon_resistance)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
  SQL
  sql2 = <<-SQL
SELECT id FROM skill WHERE name = ?;
  SQL
  sql3 = <<-SQL
INSERT INTO armor_series_skills
(armorseries_id, skill_id)
VALUES(?, ?);
  SQL
  sql4 = <<-SQL
SELECT id FROM skill_system WHERE name = ?;
  SQL
  sql5 = <<-SQL
INSERT INTO armor_series_skill_point
(point, armor_series_id, skill_system_id)
VALUES (?, ?, ?);
  SQL
  begin
    db.execute(sql1, row[0], row[3], row[2], row[4], row[5], row[6],
              row[7], row[8], row[9], row[10], row[11])
    row[12].each {|skill_system|
      results = db.execute(sql2, skill_system)
      results.each {|id|
        db.execute(sql3, row[0], id)
      }
    }
    row[13].each {|skill, sign, point|
      results = db.execute(sql4, skill)
      results.each {|id|
        db.execute(sql5, point, row[0], id)
      }
    }
  rescue => ex
    puts ex
    p ex.backtrace
    puts row
  end
}

armors.each {|row|
  p row
  sql1 = <<-SQL
INSERT INTO armor
(id, han_type, armor_series_id, type, name, slot, initial_defense, max_defense,
 fire_resistance, water_resistance, thunder_resistance, ice_resistance, dragon_resistance)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
  SQL
  sql2 = <<-SQL
SELECT id FROM skill_system WHERE name = ?;
  SQL
  sql3 = <<-SQL
INSERT INTO armor_skill_point
(point, armor_id, skill_system_id)
VALUES (?, ?, ?);
  SQL
  begin
    db.execute(sql1, row[0], row[1], row[2], row[5], row[6], row[11], row[12], row[13],
              row[14], row[15], row[16], row[17], row[18])
    row[7].each {|skill, sign, point|
      results = db.execute(sql2, skill)
      results.each {|id|
        db.execute(sql3, point, row[0], id)
      }
    }
  rescue => ex
    puts ex
    p ex.backtrace
    puts row
  end
}

