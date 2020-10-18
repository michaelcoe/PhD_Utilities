# Import libraries
import os
import pandas as pd
try:
    from PIL import Image
except ImportError:
    import Image
import pytesseract
# Read a pdf file as image pages
# We do not want images to be to big, dpi=200
# All our images should have the same size (depends on dpi), width=1654 and height=2340
pdfPath = r'C:\Users\micha\Documents\Research Papers\Animal Studies\Resistances and Efficiency'
pdfFile = r'Magnuson_Locomotion by scombrid fishes-hydromechanics (1978).pdf'
pages = pdf2image.convert_from_path(pdf_path=os.path.join(pdfPath, pdfFile), dpi=200, size=(1654,2340))
# Save all pages as images
with open(os.path.join(r'./', 'test.pdf'), 'wb') as pdf:
    for page in pages:
        # Convert a page to a string (page 2)
        content = pt.image_to_pdf_or_hocr(page, extension='pdf')
        pdf.write(content)