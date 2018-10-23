from django.db.models import Q, Prefetch 
from django.db import models

# TODO: ふたつのスキルを兼ねたスキルの扱い
# TODO: 防御力を数値型にする

# スキル系統というよりも、スキルのベース
# 27|回復速度
class SkillSystem(models.Model):
    """スキル系統"""
    class Meta:
        db_table = 'skill_system'

    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=256)
    # armorseriesskillpoint_set
    # armorskillpoint_set
    # skill_set

# 36|回復速度+2|15|体力ゲージの赤い部分を通常の4倍の速度で回復できる。|27
# 37|回復速度+1|10|体力ゲージの赤い部分を通常の2倍の速度で回復できる。|27
# 38|回復速度-1|-10|体力ゲージの赤い部分の回復速度が通常の1/2になる。|27
# 39|回復速度-2|-15|体力ゲージの赤い部分の回復速度が通常の1/4になる。|27
class Skill(models.Model):
    """スキル"""
    class Meta:
        db_table = 'skill'

    id = models.IntegerField(primary_key=True)
    skill_system = models.ForeignKey(SkillSystem)
    name = models.CharField(max_length=256)
    require_point = models.IntegerField()
    description = models.CharField(max_length=1024)
    # armorseries_set

class Item(models.Model):
    """アイテム"""
    class Meta:
        db_table = 'item'

    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=256)

class ArmorSeries(models.Model):
    """防具"""
    class Meta:
        db_table = 'armor_series'

    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=256)
    rare = models.CharField(max_length=32)
    initial_defense = models.CharField(max_length=16)
    max_defense = models.CharField(max_length=16)
    slot = models.IntegerField()
    fire_resistance = models.IntegerField()
    water_resistance = models.IntegerField()
    thunder_resistance = models.IntegerField()
    ice_resistance = models.IntegerField()
    dragon_resistance = models.IntegerField()
    # armor_set(foreign keyの逆参照)
    skills = models.ManyToManyField(Skill)
    # armorseriesskillpoint_set(foreign keyの逆参照)


class ArmorSeriesSkillPoint(models.Model):
    """防具シリーズスキルポイント"""
    class Meta:
        db_table = 'armor_series_skill_point'

    armor_series = models.ForeignKey(ArmorSeries)
    skill_system = models.ForeignKey(SkillSystem)
    point = models.IntegerField()


class Armor(models.Model):
    """防具"""
    class Meta:
        db_table = 'armor'

    id = models.IntegerField(primary_key=True)
    han_type = models.IntegerField()
    armor_series = models.ForeignKey(ArmorSeries)
    type = models.CharField(max_length=32)
    name = models.CharField(max_length=256)
    slot = models.IntegerField()
    initial_defense = models.CharField(max_length=16)
    max_defense = models.CharField(max_length=16)
    fire_resistance = models.IntegerField()
    water_resistance = models.IntegerField()
    thunder_resistance = models.IntegerField()
    ice_resistance = models.IntegerField()
    dragon_resistance = models.IntegerField()
    # armorskillpoint_set(foreign keyの逆参照)

    def skill_point(self, skill_id):
        point = 0
        for skill_point in self.armorskillpoint_set.filter(Q(skill_system__skill__id=skill_id)).iterator():
            point = point + skill_point.point
        return point

    def skill_system_point(self, skill_system_id):
        point = 0
        for skill_point in self.armorskillpoint_set.filter(Q(skill_system__id=skill_system_id)).iterator():
            point = point + skill_point.point
        return point

# select * from armor_skill_point inner join skill_system on armor_skill_point.skill_system_id = skill_system.id inner join armor on armor_skill_point.armor_id = armor.id where skill_system.name like '%回復速度%';
# 25673|5|15246|27|27|回復速度|15246|頭|フルフルXキャップ|1|64|G級91|-4|1|5|2|1|1030|2
# 25676|2|15247|27|27|回復速度|15247|胴|フルフルXレジスト|0|64|G級91|-4|1|5|2|1|1030|2
# 25679|4|15248|27|27|回復速度|15248|腕|フルフルXガード|2|64|G級91|-4|1|5|2|1|1030|2
# 25683|4|15250|27|27|回復速度|15250|脚|フルフルXレギンス|1|64|G級91|-4|1|5|2|1|1030|2
# 25688|6|15262|27|27|回復速度|15262|胴|フルフルXRレジスト|1|61|G級88|-4|1|5|2|1|1031|2
# 25692|5|15264|27|27|回復速度|15264|腰|フルフルXRコート|2|61|G級88|-4|1|5|2|1|1031|2
# 25695|8|15265|27|27|回復速度|15265|脚|フルフルXRレギンス|1|61|G級88|-4|1|5|2|1|1031|2
# 27594|3|17301|27|27|回復速度|17301|頭|屍装甲・真【頭骨】|2|75|G級99|-1|-1|-1|-1|-1|1169|2
# 27598|3|17302|27|27|回復速度|17302|胴|屍装甲・真【胸骨】|1|75|G級99|-1|-1|-1|-1|-1|1169|2
# 27602|3|17303|27|27|回復速度|17303|腕|屍装甲・真【上腕骨】|1|75|G級99|-1|-1|-1|-1|-1|1169|2
# 27606|3|17304|27|27|回復速度|17304|腰|屍装甲・真【腰骨】|2|75|G級99|-1|-1|-1|-1|-1|1169|2
# 27610|3|17305|27|27|回復速度|17305|脚|屍装甲・真【大腿骨】|1|75|G級99|-1|-1|-1|-1|-1|1169|2
class ArmorSkillPoint(models.Model):
    """防具スキルポイント"""
    class Meta:
        db_table = 'armor_skill_point'

    armor = models.ForeignKey(Armor)
    skill_system = models.ForeignKey(SkillSystem)
    point = models.IntegerField()

