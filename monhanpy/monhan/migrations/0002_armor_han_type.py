# -*- coding: utf-8 -*-
# Generated by Django 1.11.7 on 2017-11-16 12:15
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('monhan', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='armor',
            name='han_type',
            field=models.IntegerField(default=1),
            preserve_default=False,
        ),
    ]