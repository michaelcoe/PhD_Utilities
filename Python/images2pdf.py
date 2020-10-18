# Import libraries
import os

try:
    from PIL import Image
except ImportError:
    import Image
import pytesseract

'''
PIL is the python package Pillow
    (pip install Pillow) or (conda install -c anaconda pillow)
    PIL is used to handle images

Pytesseract is python wrapper to tesseract OCR
    (pip install pytesseract) or (conda install -c conda-forge pytesseract)

Important:  You need tesseract OCR installed on your machine for it to work:
https://github.com/tesseract-ocr/tesseract
'''
# Read a pdf file as image pages
# We do not want images to be to big, dpi=200
# All our images should have the same size (depends on dpi), width=1654 and height=2340
pdfPath = r'path_to_image_pdf'
pdfFile = r'output_to_readable_pdf'
pages = pdf2image.convert_from_path(pdf_path=os.path.join(pdfPath, pdfFile), dpi=200, size=(1654,2340))
# Save all pages as images
with open(os.path.join(r'./', 'test.pdf'), 'wb') as pdf:
    for page in pages:
        # Convert a page to a string (page 2)
        content = pt.image_to_pdf_or_hocr(page, extension='pdf')
        pdf.write(content)