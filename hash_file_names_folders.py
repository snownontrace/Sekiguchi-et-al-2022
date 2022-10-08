import os, glob, argparse, hashlib
import tkinter as tk
from tkinter.filedialog import askdirectory
from datetime import datetime
from hash_file_names import hash_file_names

def hash_file_names_folders(inputFolder=None):
    '''
    Input:
    ------
    inputFolder:
        The folder containing the folders with files to rename.

    Output:
    -------
        For each of the sub-folders, rename all file names to hashed file names.

    '''
    if inputFolder is None:
        # os.path.join(os.path.expanduser('~'), 'Desktop')
        initialFolder = os.path.join(os.path.expanduser('~'),'Box', 'Shaohe-Box-Yamada-Lab')

        # shows the dialog box
        root = tk.Tk()
        root.withdraw()
        inputFolder = askdirectory(parent=root, initialdir=initialFolder, \
                                 title='Please select the folder containing the files to rename')
    elif inputFolder.endswith(os.path.sep):
        inputFolder = inputFolder[:-1]


    folders = glob.glob( inputFolder + os.path.sep + "*" + os.path.sep )
    for folder in folders:
        hash_file_names(folder)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("inputFolder", nargs='?',
                        help="optional; folder containing subfolders with files to rename",
                        default=None)
    args = parser.parse_args()

    hash_file_names_folders(args.inputFolder)
