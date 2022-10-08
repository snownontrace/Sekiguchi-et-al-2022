import os, glob
import tkinter as tk
from tkinter.filedialog import askdirectory

# This script takes a specific set of tif files and add number to reverse the ordering of file names

filesToRename = "LV-401-*.tif"
# filesToRename = "*.txt"
# filesToRename = "*.png"

initialFolder = os.path.join(os.path.expanduser('~'),'Box', 'Shaohe-Box-Yamada-Lab', 'Data-Transfer-Box-COVID-19', '20211022-25-E13-Cas9-bud')

#shows the dialog box
root = tk.Tk()
root.withdraw()
inputFolder = askdirectory(parent=root, initialdir=initialFolder, \
                         title='Please select the folder containing the files to rename')

fList = glob.glob( inputFolder + os.path.sep + filesToRename )
fList.sort()
# print(fList)

for i in range(len(fList)):
    base_name = os.path.basename(fList[i])
    n = len(fList) - i - 1
    new_name = base_name[:-22] + f'{n:02}' + base_name[-23:]

    os.rename( os.path.join(inputFolder, base_name),
               os.path.join(inputFolder, new_name) )
