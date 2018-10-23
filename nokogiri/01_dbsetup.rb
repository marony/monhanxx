require 'bundler/setup'
require 'sqlite3'

db = SQLite3::Database.new 'monhan.db'

# スキル系統(skill_system)
sql = <<-SQL
DROP TABLE IF EXISTS skill_system;
SQL

puts(sql)
db.execute(sql)

sql = <<-SQL
CREATE TABLE skill_system (
  id INTEGER PRIMARY KEY,
  name VARCHAR(256)
);
SQL

puts(sql)
db.execute(sql)

# スキル(skill)
sql = <<-SQL
DROP TABLE IF EXISTS skill;
SQL

puts(sql)
db.execute(sql)

sql = <<-SQL
CREATE TABLE skill (
  id INTEGER PRIMARY KEY,
  skill_system_id INTEGER,
  name VARCHAR(256),
  require_point INTEGER,
  description TEXT
);
SQL

puts(sql)
db.execute(sql)

# 防具シリーズ(armor_series)
sql = <<-SQL
DROP TABLE IF EXISTS armor_series;
SQL

puts(sql)
db.execute(sql)

sql = <<-SQL
CREATE TABLE armor_series (
  id INTEGER PRIMARY KEY,
  name VARCHAR(256),
  rare VARCHAR(32),
  initial_defense VARCHAR(16),
  max_defense VARCHAR(16),
  slot INTEGER,
  fire_resistance INTEGER,
  water_resistance INTEGER,
  thunder_resistance INTEGER,
  ice_resistance INTEGER,
  dragon_resistance INTEGER
);
SQL

puts(sql)
db.execute(sql)

# TODO: 防具シリーズのスキル
# TODO:  防具シリーズのスキルポイント

# 防具(armor)
sql = <<-SQL
DROP TABLE IF EXISTS armor;
SQL

puts(sql)
db.execute(sql)

sql = <<-SQL
CREATE TABLE armor (
  id INTEGER PRIMARY KEY,
  armor_series_id INTEGER,
  type VARCHAR(32),
  name VARCHAR(256),
  slot INTEGER,
  initial_defense VARCHAR(16),
  max_defense VARCHAR(16),
  fire_resistance INTEGER,
  water_resistance INTEGER,
  thunder_resistance INTEGER,
  ice_resistance INTEGER,
  dragon_resistance INTEGER
);
SQL

puts(sql)
db.execute(sql)

# TODO: スキルポイント
# TODO: 生産必要素材

