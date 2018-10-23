from django.shortcuts import render
from django.http import HttpResponse
from django import forms
from django.db.models import Q, Prefetch
from monhan.models import *
from monhan.logic import *

def index(request):
    """トップメニュー"""
    return render(request, 'monhan/index.html')

def armor_list(request):
    """防具一覧"""
    # FIXME: SQLite3だとクエリパラメータが999までしか使えない
    armor_series = ArmorSeries.objects.all().select_related().order_by('id')
#    armor_series = ArmorSeries.objects.all().prefetch_related('armor_set').select_related().order_by('id')
#    armor_series = ArmorSeries.objects.all().prefetch_related('armor_set', 'armor_set__armorskillpoint_set', 'armor_set__armorskillpoint_set__skill_system', 'armor_set__armorskillpoint_set__skill_system__skill_set', 'skills', 'armorseriesskillpoint_set', 'armorseriesskillpoint_set__skill_system').select_related().order_by('id')
#    armor_series = armor_series[:100]
    return render(request, 'monhan/armor_list.html', {'armor_series': armor_series})

def skill_list(request):
    """スキル一覧"""
    skills = Skill.objects.all().order_by('id')
    return render(request, 'monhan/skill_list.html', {'skills': skills})

def item_list(request):
    """アイテム一覧"""
    items = Item.objects.all().order_by('id')
    return render(request, 'monhan/item_list.html', {'items': items})

class SearchArmorsForm(forms.Form):
    """防具検索フォーム"""
    HAN_TYPE_KEYS = [
            (1, '剣士'),
            (2, 'ガンナー')]

    SORT_KEYS = [
            ('id', 'なし',),
            ('initial_defense', '初期防御力',),
            ('max_defense', '最大防御力',),
            ('slot', 'スロット数',)]

    han_type = forms.ChoiceField(label="タイプ", choices=HAN_TYPE_KEYS, initial=1, widget=forms.Select, required=True)
    skill_name = forms.CharField(max_length=32, label="スキル名", required=False)
    skill_system_name = forms.CharField(max_length=32, label="スキル系統", required=False)
    skill_point = forms.IntegerField(label="ポイント数", required=False)
    min_slot = forms.IntegerField(label="最小スロット", required=False)
    initial_defense = forms.IntegerField(label="最小初期防御力", required=False)
    max_defense = forms.IntegerField(label="最小最大防御力", required=False)
    sort_key = forms.ChoiceField(label="並び替", choices=SORT_KEYS, initial='id', widget=forms.Select, required=True)

def search_armors(request):
    """スキルから防具を検索"""
    if request.method == 'POST':
        form = SearchArmorsForm(request.POST)
        if form.is_valid():
            han_type = form.cleaned_data['han_type']
            skill_name = form.cleaned_data['skill_name']
            skill_system_name = form.cleaned_data['skill_system_name']
            skill_point = form.cleaned_data['skill_point']
            min_slot = form.cleaned_data['min_slot']
            initial_defense = form.cleaned_data['initial_defense']
            max_defense = form.cleaned_data['max_defense']
            sort_key = form.cleaned_data['sort_key']
            print(sort_key)

            cond = []
            if han_type != None:
                cond.append(Q(han_type=han_type))
            if skill_name != None and len(skill_name) > 0:
                cond.append(Q(armorskillpoint__skill_system__skill__name__contains=skill_name))
            if skill_system_name != None and len(skill_system_name) > 0:
                cond.append(Q(armorskillpoint__skill_system__name__contains=skill_system_name))
            if skill_point != None:
                cond.append(Q(armorskillpoint__point__gte=skill_point))
            if min_slot != None:
                cond.append(Q(slot__gte=min_slot))
            if initial_defense != None:
                cond.append(Q(initial_defense__gte=initial_defense))
            if max_defense != None:
                cond.append(Q(max_defense__gte=max_defense))

            armors = None
            print(cond)
            # FIXME: SQLite3だとクエリパラメータが999までしか使えない
            if (len(cond) > 0):
                armors = Armor.objects.prefetch_related('armorskillpoint_set', 'armorskillpoint_set__skill_system', 'armorskillpoint_set__skill_system__skill_set').select_related().filter(*cond)
            else:
                armors = Armor.objects.prefetch_related('armorskillpoint_set', 'armorskillpoint_set__skill_system', 'armorskillpoint_set__skill_system__skill_set').select_related().all()
            if sort_key == 'id':
                armors = armors.order_by(sort_key)[:999]
            else:
                armors = armors.order_by(sort_key).reverse()[:999]
            count = armors.count()
            print(count)

            # INNER JOINの重複を弾く
            ids = set([])
            armors2 = []
            for armor in armors:
                if not (armor.id in ids):
                    ids.add(armor.id)
                    armors2.append(armor)

            return render(request, 'monhan/search_armors_result.html',
                    {'armors': armors2, 'armors_length': count, 'form': form})
    else:
        form = SearchArmorsForm()
        return render(request, 'monhan/search_armors.html', {'form': form})

class SkillModelChoiceField(forms.ModelChoiceField):
    def label_from_instance(self, skill):
        return skill.name

class CoodinateArmorSetForm(forms.Form):
    """防具提案フォーム"""
    HAN_TYPE_KEYS = [
            (1, '剣士'),
            (2, 'ガンナー')]

    han_type = forms.ChoiceField(label="タイプ", choices=HAN_TYPE_KEYS, initial=1, widget=forms.Select, required=True)
    skill1 = SkillModelChoiceField(label="発動スキル1", queryset=Skill.objects.all(), widget=forms.Select, required=False)
    skill2 = SkillModelChoiceField(label="発動スキル2", queryset=Skill.objects.all(), widget=forms.Select, required=False)
    skill3 = SkillModelChoiceField(label="発動スキル3", queryset=Skill.objects.all(), widget=forms.Select, required=False)
    skill_system1 = SkillModelChoiceField(label="スキル系統1", queryset=SkillSystem.objects.all(), widget=forms.Select, required=False)
    skill_point1 = forms.IntegerField(label="スキルポイント1", required=False)
    skill_system2 = SkillModelChoiceField(label="スキル系統2", queryset=SkillSystem.objects.all(), widget=forms.Select, required=False)
    skill_point2 = forms.IntegerField(label="スキルポイント2", required=False)
    skill_system3 = SkillModelChoiceField(label="スキル系統3", queryset=SkillSystem.objects.all(), widget=forms.Select, required=False)
    skill_point3 = forms.IntegerField(label="スキルポイント3", required=False)
    min_slot = forms.IntegerField(label="最小スロット", required=False)
    initial_defense = forms.IntegerField(label="最小初期防御力", required=False)
    max_defense = forms.IntegerField(label="最小最大防御力", required=False)

# スキルとポイント(複数)と最低防御力と最低スロット数を指定する
# 頭・胴・腕・腰・脚を1つずつ選ん防具セットを一覧にし防御力順に表示
def coodinate_armor_set(request):
    """条件から良い防具のセットを捜す"""
    if request.method == 'POST':
        form = CoodinateArmorSetForm(request.POST)
        if form.is_valid():
            han_type = form.cleaned_data['han_type']
            # これらのスキルが発動する
            skill1 = form.cleaned_data['skill1']
            skill2 = form.cleaned_data['skill2']
            skill3 = form.cleaned_data['skill3']
            # スキルポイントが最低これだけある
            skill_system1 = form.cleaned_data['skill_system1']
            skill_point1 = form.cleaned_data['skill_point1']
            skill_system2 = form.cleaned_data['skill_system2']
            skill_point2 = form.cleaned_data['skill_point2']
            skill_system3 = form.cleaned_data['skill_system3']
            skill_point3 = form.cleaned_data['skill_point3']
            # その他条件
            min_slot = form.cleaned_data['min_slot']
            initial_defense = form.cleaned_data['initial_defense']
            max_defense = form.cleaned_data['max_defense']

            # ロジック
            armor_sets = Logic.coodinate_armor_set(
                    han_type,
                    [skill1, skill2, skill3],
                    [(skill_system1, skill_point1), (skill_system2, skill_point2), (skill_system3, skill_point3)],
                    min_slot, (initial_defense, max_defense))

            count = len(armor_sets)
            return render(request, 'monhan/coodinate_armor_set_result.html',
                    {'armor_sets': armor_sets, 'armor_set_length': count, 'form': form})
    else:
        form = CoodinateArmorSetForm()
        return render(request, 'monhan/coodinate_armor_set.html', {'form': form})

