from django.db.models import Q, Prefetch
from monhan.models import *
import copy

class Logic:
    class ArmorMemo:
        def __init__(self):
            self.skill_points = {}
            self.skill_system_points = {}
            self.slot = 0
            self.defenses = [(0, 0)]

    def p_skill(armor_set, skills):
        for skill in skills:
            if skill != None:
                point = 0
                for armor in armor_set:
#                    print("p_skill: " + skill.name + ", " + armor.name)
                    point += armor.skill_point(skill.id)
                if (skill.require_point >= 0 and point < skill.require_point) or (skill.require_point < 0 and point > skill.require_point):
                    return False
        return True

    def p_skill_point(armor_set, skill_systems):
        for skill_system in skill_systems:
            ss, p = skill_system
            if ss != None and p != None:
                point = 0
                for armor in armor_set:
#                    print("p_skill_point: " + skill_system.name + ", " + armor.name + ", " + p.to_s)
                    point += armor.skill_system_point(ss.id)
#                print(point, ss.name, ss.skill_set.require_point)
#                if point < ss.skill_set.require_point:
                if (p >= 0 and point < p) or (p < 0 and point > p):
                    return False
        return True

    def p_others(armor_set, min_slot, defenses):
        if min_slot != None:
            slot = 0
            for armor in armor_set:
                slot += armor.slot
            if slot < min_slot:
                return False

        if defenses[0] != None:
            defense = 0
            for armor in armor_set:
                defense += armor.initial_defense
            if defense < defenses[0]:
                return False

        if defenses[1] != None:
            defense = 0
            for armor in armor_set:
                defense += armor.max_defense
            if defense < defenses[1]:
                return False

        return True

    # 途中計算
    def calculate(armor, memo, skills, skill_systems):
        memo2 = copy.deepcopy(memo)
        # スキル
        for skill in skills:
            if skill != None:
                if skill.id in memo2.skill_points.keys():
                    memo2.skill_points[skill.id] += armor.skill_point(skill.id)
                else:
                    memo2.skill_points[skill.id] = armor.skill_point(skill.id)
        # スキル系統
        for skill_system in skill_systems:
            ss, p = skill_system
            if ss != None and p != None:
                if ss.id in memo2.skill_system_points.keys():
                    memo2.skill_system_points[ss.id] += armor.skill_system_point(ss.id)
                else:
                    memo2.skill_system_points[ss.id] = armor.skill_system_point(ss.id)
        # スロット
        memo2.slot += armor.slot
        # TODO: 防御力
#        memo2.defenses[0] = memo2.defenses[0] + armor.initial_defense
#        memo2.defenses[1] = memo2.defenses[1] + armor.max_defense
        return memo2

    def match(memo, skills, skill_systems, min_slot, defenses):
        # スキル
        for skill in skills:
            if skill != None:
                if skill.id in memo.skill_points.keys():
#                    print(memo.skill_points[skill.id], skill.require_point)
                    if (skill.require_point >= 0 and memo.skill_points[skill.id] < skill.require_point) or (skill.require_point < 0 and memo.skill_points[skill.id] > skill.require_point):
                        return False
                else:
                    return False
        # スキル系統
        for skill_system in skill_systems:
            ss, p = skill_system
            if ss != None and p != None:
                if ss.id in memo.skill_system_points.keys():
                    if (p >= 0 and memo.skill_system_points[ss.id] < p) or (p < 0 and memo.skill_system_points[ss.id] > p):
                        return False
                else:
                    return False
        # スロット
        if min_slot != None:
            if memo.slot < min_slot:
                return False
        # TODO: 防御力

        return True

    def sort_by_skills(armors, skills):
        for skill in reversed(skills):
            if skill != None:
                armors = list(reversed(sorted(armors, key=lambda a: a.skill_point(skill.id))))
        return armors

    def sort_by_skill_systems(armors, skill_systems):
        for skill_system, skill_point in reversed(skill_systems):
            if skill_system != None:
                armors = list(reversed(sorted(armors, key=lambda a: a.skill_system_point(skill_system.id))))
        return armors

    def search_armor_sets(counts, armors, now_set, memo, results, skills, skill_systems, min_slot, defenses):
        types = ['頭', '胴', '腕', '腰', '脚']
        l = len(now_set)
        if l < 5:
            armors2 = [a for a in armors if a.type == types[l]]
            for armor in armors2:
                # copy
                now_set2 = now_set[:]
                now_set2.append(armor)
                memo2 = Logic.calculate(armor, memo, skills, skill_systems)
                Logic.search_armor_sets(counts, armors, now_set2, memo2, results, skills, skill_systems, min_slot, defenses)
            return results
        else:
#            if Logic.p_others(now_set, memo, min_slot, defenses) and Logic.p_skill(now_set, memo, skills) and Logic.p_skill_point(now_set, memo, skill_systems):
            if Logic.match(memo, skills, skill_systems, min_slot, defenses):
                results.append(now_set)
            
            counts[1] += 1
            if counts[1] % 1000 == 0:
                print(counts[0], counts[1])

            return results

    def coodinate_armor_set(han_type, skills, skill_systems, min_slot, defenses):
        cond = []
        cond.append(Q(han_type=han_type))
        # skill1, 2, 3
        # これらのスキルポイントを備えた防具を検索(ポイント数は少なくてもいい)
        cond1 = []
        for skill in skills:
            if skill != None:
                cond1.append(skill.id)
        # skill_system1, skill_point1, 2, 3
        # これらのスキルポイントを備えた防具を検索(ポイント数は少なくてもいい)
        cond2 = []
        for skill_system, skill_point in skill_systems:
            if skill_system != None:
                cond2.append(skill_system.id)
        if len(cond1) > 0:
            cond.append(Q(armorskillpoint__skill_system__skill__id__in=cond1))
        if len(cond2) > 0:
            cond.append(Q(armorskillpoint__skill_system__id__in=cond2))
        print(cond)
        armors = Armor.objects.prefetch_related('armorskillpoint_set', 'armorskillpoint_set__skill_system', 'armorskillpoint_set__skill_system__skill_set').select_related().filter(*cond)
        #armors = Armor.objects.select_related().filter(*cond)

        print(armors.count())

        armors = Logic.sort_by_skills(armors, skills)
        armors = Logic.sort_by_skill_systems(armors, skill_systems)

        # INNER JOINの重複を弾く
        ids = set([])
        armors2 = []
        for armor in armors:
            if armor.id not in ids:
                ids.add(armor.id)
                armors2.append(armor)

        # 頭・胴・腕・腰・脚の全組み合わせについて
        print("armors = " + str(len(armors)) + ", armors2 = " + str(len(armors2)))
        a1 = [a for a in armors if a.type == "頭"][0:5]
        l1 = len(a1)
        print("頭 = ", l1)
        a2 = [a for a in armors if a.type == "胴"][0:5]
        l2 = len(a2)
        print("胴 = ", l2)
        a3 = [a for a in armors if a.type == "腕"][0:5]
        l3 = len(a3)
        print("腕 = ", l3)
        a4 = [a for a in armors if a.type == "腰"][0:5]
        l4 = len(a4)
        print("腰 = ", l4)
        a5 = [a for a in armors if a.type == "脚"][0:5]
        l5 = len(a5)
        print("脚 = ", l5)
        counts = [l1 * l2 * l3 * l4 * l5, 0]
        armors3 = a1
        armors3.extend(a2)
        armors3.extend(a3)
        armors3.extend(a4)
        armors3.extend(a5)
        armor_sets = Logic.search_armor_sets(counts, armors3, [], Logic.ArmorMemo(), [], skills, skill_systems, min_slot, defenses)
        # 合計でmin_slot, initial_defense, max_defenseを満すもの以外除外
#        armor_sets = [armor_set for armor_set in armor_sets if Logic.p_others(armor_set, min_slot, defenses)]
        # skill1, 2, 3が発動する組み合わせ以外除外
#        armor_sets = [armor_set for armor_set in armor_sets if Logic.p_skill(armor_set, skills)]
        # skill_system1, skill_point1, 2, 3を満たすもの以外除外
#        armor_sets = [armor_set for armor_set in armor_sets if Logic.p_skill_point(armor_set, skill_systems)]

        return armor_sets

