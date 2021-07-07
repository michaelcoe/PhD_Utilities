# -*- coding: utf-8 -*-
"""
Created on Tue Nov 17 09:02:41 2020

@author: mco143
"""
import os

import moviepy.editor as me


movie_location = os.path.join('D:\\', 'velocityanimation.mpeg')
save_location = os.path.join('D:\\', 'output.gif')

clip = me.VideoFileClip(movie_location)
clip.speedx(10.0)
clip.write_gif(save_location)