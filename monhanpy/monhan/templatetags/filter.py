from django import template

register = template.Library()

@register.filter("han_type_name")
def han_type_name(v):
    if v == 1:
        return "剣士"
    else:
        return "ガンナー"

@register.filter("skill_point")
def skill_point(skill):
    o = '+'
    if skill.require_point < 0:
        o = ''
    return skill.skill_system.name + o + str(skill.require_point)

