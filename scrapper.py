# -*- coding: utf-8 -*-
"""
Created on Sun Dec 12 15:29:47 2021

@author: Nelson
"""

import numpy as np
import pandas as pd
from selenium import webdriver
import os

#set chromedriver path 

chrome_path = 'chromedriver\\chromedriver.exe'

# initialize chromedriver
driver = webdriver.Chrome(chrome_path)
