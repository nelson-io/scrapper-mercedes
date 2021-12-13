# -*- coding: utf-8 -*-
"""
Created on Sun Dec 12 15:29:47 2021

@author: Nelson
"""

import numpy as np
import pandas as pd
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
import os
import time
import re

#set chromedriver path 

chrome_path = 'chromedriver\\chromedriver.exe'



#init lists

df_list = []
df_meta_list = []
error_mesa = []

#set padron path

path = 'https://www.padron.gob.ar/publica/'
    
elecc = 'ELECCIONES PASO 13/08/2017'

for i in range(200):



    #navigate padron
    # initialize chromedriver
    driver = webdriver.Chrome(chrome_path)

    driver.get(path)
    
    time.sleep(1)
    
    try:
    
        elem_distelectoral = driver.find_element_by_id('site')
        
    
        
        
        elem_distelectoral.send_keys('BUENOS AIRES')
        time.sleep(1)
        elem_eleccion = driver.find_element_by_id('elec')
        elem_eleccion.send_keys(elecc)
        
        time.sleep(1)
        elem_secelec = driver.find_element_by_id('secm')
        elem_secelec.send_keys('MERCEDES')
        
        elem_mesa = driver.find_element_by_id('mesa')
        elem_mesa.send_keys(str(i + 1))
        
        
        elem_consultarbutton = driver.find_element_by_id('btnVer')
        elem_consultarbutton.click()
        
        time.sleep(1)
        
        elem_circuito = driver.find_element_by_id('zonadesc')
        circuito = int(re.findall('\d{4}', elem_circuito.text)[0])
        
        elem_tbl = driver.find_element_by_class_name('table-striped')
        mydfs = pd.read_html(driver.page_source)
        
        df_meta = mydfs[0]
        df_data = mydfs[1]
        
        df_meta['mesa'] = i + 1
        df_data['mesa'] = i + 1
        
        df_meta['eleciones'] = elecc
        df_data['eleciones'] = elecc
        
        df_meta['circuito'] = circuito
        df_data['circuito'] = circuito
        
        df_meta_list.append(df_meta)
        df_list.append(df_data)
        
    except:
        error_mesa.append(i+1)
        
    finally:
        
        driver.close()
        time.sleep(3)
        
        
df_data_full = pd.concat(df_list)
df_meta_full = pd.concat(df_meta_list) 

df_data_full.to_csv('out\\elec_paso_08_2017_data.csv')  
df_meta_full.to_csv('out\\elec_paso_08_2017_meta.csv')   
    
