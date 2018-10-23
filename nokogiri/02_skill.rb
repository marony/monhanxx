require 'nokogiri'
require 'open-uri'
require 'uri'
require 'csv'

require 'bundler/setup'
require 'sqlite3'

# 「モンハンダブルクロス対応のスキルポイント一覧（50音順）からスキル効果と関連装飾珠を探す」
url = 'http://mh-x.com/skillpoint-all.html'

# スキル系統
# 
# http://mh-x.com/skillpoint-all.html
# <article>
#   <div class="post">
#     <div class="the_content">
#       <table class="txt-c mum">
#         <tbody>
#           <tr>
#             <td><a href="http://mh-x.com/skill/SP延長.html">SP延長</a></td>
def parse_skill_systems(url)
  no = 1
  skill_systems = []
  skill_urls = []
  doc = Nokogiri::HTML.parse(open(url).read, nil, nil)
  doc.xpath('//table[@class="txt-c mum"]//tr').each {|node|
    node.xpath('.//a').each {|skill_system|
      begin
        # 通番, スキル系統
        row = [no, skill_system.inner_text]
        skill_systems << row
        # URL
        puts "no = " + no.to_s + ", skill_system = " + skill_system.inner_text
        skill_urls << [no, skill_system[:href], url]
        no = no + 1
      rescue => ex
        puts ex
        p ex.backtrace
        puts no, skill_system.inner_text
        ef = open('skill_error.txt', 'a')
        ef.write(ex)
        ef.write(no.to_s + ", " + skill_system.inner_text)
        ef.close()
      end
    }
  }
  return skill_systems, skill_urls
end

# スキル
#
# http://mh-x.com/skill/SP%E5%BB%B6%E9%95%B7.html
# <article>
#   <div class="post">
#     <table class="mum">
#       <tbody>
#         <tr>
#           <td>SP延長</td>
#           <td>SP時間延長</td>
#           <td class="ttd-c">10</td>
#           <td>SP狩技で発動するSP状態の効果時間が1.25倍に延長される。</td>
def parse_skills(skill_urls)
  no2 = 1
  skills = []
  skill_urls.each {|no, url|
    skillsystem = ""
    skill = []
    doc = Nokogiri::HTML.parse(open(URI.escape(url)).read, nil, nil)
    doc.xpath('//table[@class="mum"]//tr[./td]').each do |node|
      begin
        i = 0
        node.children.each {|td|
          if i == 0 && node.children.length == 4
            skillsystem = td.inner_text
          else
            skill << td.inner_text
            if skill.length >= 3
              # 通番, スキル系統通番, スキル系統, スキル名, 必要ポイント, 効果説明, URL
              skills << [no2, no, skillsystem] + skill + [url]
              puts "no = " + no2.to_s + ", skill_system = " + skillsystem + ", skill = " + skill[0]
              no2 = no2 + 1
              skill = []
            end
          end
          i += 1
        }
      rescue => ex
        puts ex
        p ex.backtrace
        puts no2, skillsystem
        p skill
        ef = open('skill_error.txt', 'a')
        ef.write(ex)
        ef.write(no2.to_s + ", " + skillsystem + ", " + skill)
        ef.close()
      end
    end
  }
  skills
end

skill_systems, skill_urls = parse_skill_systems(url)
skills = parse_skills(skill_urls)

CSV.open("skill_system.csv", "w") {|csv|
  skill_systems.each {|row|
    csv << row
  }
}

CSV.open("skill.csv", "w") {|csv|
  skills.each {|row|
    csv << row
  }
}

db = SQLite3::Database.new('monhan.db')

db.execute("DELETE FROM skill_system;")
skill_systems.each {|row|
  p row
  sql = "INSERT INTO skill_system (id, name) VALUES(?, ?);"
  begin
    db.execute(sql, row[0], row[1])
  rescue => ex
    puts ex
    p ex.backtrace
    puts row
  end
}

db.execute("DELETE FROM skill;")
skills.each {|row|
  p row
  sql = <<-SQL
INSERT INTO skill
(id, skill_system_id, name, require_point, description)
VALUES (?, ?, ?, ?, ?)
  SQL
  begin
    db.execute(sql, row[0], row[1], row[3], row[4], row[5])
  rescue => ex
    puts ex
    p ex.backtrace
    puts row
  end
}

