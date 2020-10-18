import os
import re
import sys

# requires pandas
import pandas as pd

# requres pdfminer and pdfminer.six
from pdfminer.high_level import extract_text
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.converter import TextConverter
from pdfminer.layout import LAParams
from pdfminer.pdfpage import PDFPage
from io import StringIO

'''
pdfminer and pdfminer.six are packages to handle pdf operations and both are needed
    (pip install pdfminer and pip install pdfminer.six)
    (conda install -c conda-forge pdfminer and conda install -c conda-forge pdfminer.six)
pandas is a pthon package for dataframe files (xlsx, csv, text, etc.)
    (pip install pandas) or (conda install -c anaconda pandas)
'''

# extracts the text from PDF
def convert_pdf_to_txt(path):
    rsrcmgr = PDFResourceManager()
    retstr = StringIO()
    codec = 'utf-8'
    laparams = LAParams()
    device = TextConverter(rsrcmgr, retstr, codec=codec, laparams=laparams)
    fp = open(path, 'rb')
    interpreter = PDFPageInterpreter(rsrcmgr, device)
    password = ""
    maxpages = 10
    caching = True
    pagenos=set()

    for page in PDFPage.get_pages(fp, pagenos, maxpages=maxpages, password=password,caching=caching, check_extractable=True):
        interpreter.process_page(page)

    text = retstr.getvalue()

    fp.close()
    device.close()
    retstr.close()
    return text

# path to your pdf files
path = r'pdf_file_paths'
# where you want the excel file saved
savePath = r'path_to_excel_file'

searchedFileFolder = []
pdfFiles = [os.path.join(root, name)
             for root, dirs, files in os.walk(path)
             for name in files
             if name.endswith((".pdf"))]

# list of keywords, can either be a list or single keyword
keywords = ['multiple', 'keywords']
for file in pdfFiles:
    try:
        text = extract_text(file)
        if any(re.findall('|'.join(keywords), text)):
            searchedFileFolder.append(file)
    except Exception:
        continue

# takes a dictionary in, right now it's set for just the path to the files where keywords are in
# can be set however you want, maybe using os.path.splitext()
df = pd.DataFrame({'Files':searchedFileFolder})
df.to_excel(os.path.join(savePath, 'pdf_list.xlsx'), index=False)

#print(df)