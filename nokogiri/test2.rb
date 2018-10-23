require 'nokogiri'
require 'open-uri'
require 'uri'
require 'csv'

def init_armor(no3)
  armor = []
  for i in 1..5
    armor << [no3]
    no3 += 1
  end
  return no3, armor
end

# 防具
def parse_armors()
  no3 = 0
  armors = []

  doc = Nokogiri::HTML.parse(File.open('test2.html'), nil, nil)
  no3, armor = init_armor(no3)
  prev_l = 0
  i = 0
  doc.xpath('//div[contains(@class,"section")][1]/table[@class="mum"]/tbody/tr').each do |node|
    l = node.xpath('td').length
    node.xpath('td').each do |td|
      if prev_l != l
        i = 0
        prev_l = l
        if l == 4 && armor[0].length > 1
          armors = armors + armor
          no3, armor = init_armor(no3)
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
    end
  end
  armors = armors + armor
  no3, armor = init_armor(no3)

  return armors
end

armors = parse_armors()

armors.each do |row|
  p row
end

