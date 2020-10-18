import os
import pandas as pd
import camelot as cm

'''
pandas is a package for handling dataframe files
    (pip install pandas)
camelot is a PDF extractor
    (conda install -c conda-forge camelot-py)
'''

filePath = r'pdf_file_path'
fileName = r'pdf'
outputName = r'excel_output'
fullPath = os.path.join(filePath, fileName)

tables = cm.read_pdf(fullPath, pages='pages_of_table')

frames=[]
for idx, table in enumerate(tables):
    frames.append(tables[idx].df)
    
resultTable = pd.concat(frames)

resultTable.to_excel(os.path.join(filePath, outputName))