import pandas as pd

from pathlib import Path

'''
This script will take input from an xlsx sheet and output a latex table script in .txt form
If there are multiple sheets, each sheet will ouptut as it's own .txt file
'''
file_path = Path(r'/path/to/excel/sheet')
save_path = Path(r'./')

xl = pd.ExcelFile(file_path)

sheets = xl.sheet_names # gets the sheet names

dataFrameDict = dict()

for sheet in sheets:
    dataFrameDict[sheet] = xl.parse(sheet, index_col=False)

save_template = file_path.parts[-1].split('.')[0]

# table options
https://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.DataFrame.to_latex.html

for sheet in dataFrameDict:
    df = pd.DataFrame(dataFrameDict[sheet])
    with open(save_path.joinpath(save_template + '_' + table + '.txt'), 'w') as f:
        # write header
        f.write('\\begin{table}[ht] \n')
        f.write('\centering \n')

        # write latex
        # this is the method you put the table options
        f.write(df.to_latex(index=False))

        # write footer
        f.write('\\end{table} \n')
    
    f.close()