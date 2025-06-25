# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
#%%

import os
import glob
import pandas as pd
import numpy as np

sbr488 = []
sbr561 = []
sbr640 = []

fwhm488 = []
fwhm561 = []
fwhm640 = []

rsq488 = []
rsq561 = []
rsq640 = []

theor488 = []
theor561 = []
theor640 = []

path=os.getcwd()
print(path)

for x in glob.glob(path+'/*/*/*/*summary.xls',recursive=False):
    print(x)
    currfile = pd.read_csv(x, sep='\t', encoding='ISO-8859-1')
    
    ###channel 488
    sbr488.append(currfile.values[0][1])
    fwhm488.append((currfile.values[2][1:4]))
    rsq488.append((currfile.values[4][1:4]))
    theor488.append((currfile.values[5][1:4]))
    
    ###channel 561
    sbr561.append(currfile.values[0][4])
    fwhm561.append((currfile.values[2][4:7]))
    rsq561.append((currfile.values[4][4:7]))
    theor561.append((currfile.values[5][4:7]))
    
    ###channel 640
    sbr640.append(currfile.values[0][7])
    fwhm640.append((currfile.values[2][7:10]))
    rsq640.append((currfile.values[4][7:10]))
    theor640.append((currfile.values[5][7:10]))
    
    
df488 = pd.concat([pd.DataFrame(sbr488),pd.DataFrame(fwhm488),pd.DataFrame(theor488)],axis=1)
df561 = pd.concat([pd.DataFrame(sbr561),pd.DataFrame(fwhm561),pd.DataFrame(theor561)],axis=1)
df640 = pd.concat([pd.DataFrame(sbr640),pd.DataFrame(fwhm640),pd.DataFrame(theor640)],axis=1)

lbl = ['SBR','FWHM_X','FWHM_Y','FWHM_Z','theor_ratio_X','theor_ratio_Y','theor_ratio_Z']
df488.columns=lbl
df561.columns=lbl
df640.columns=lbl