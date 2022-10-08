'''
Write a script to take a folder of images, rename the images, preserve a key
and make a new folder output location with the renamed images

'''
import os, glob, argparse
import tkinter as tk
from tkinter.filedialog import askdirectory

def reverse_hashed_file_names(inputFolder=None, hashRecordFileName=None):
    '''
    Input:
    ------
    inputFolder:
        The folder containing the files to rename.

    hashRecordFileName:
        The txt file name containing the record of the original and hashed file names. Has to be in the same parent folder as inputFolder.
            - If None, look for the pattern of files starting with the inputFolder name and ending with "fileNameRecord.txt".
            - The hashRecord file always have a header ("original_file_name\tconverted_file_name").

    Output:
    -------
        Rename all hashed file names back to the original file names.

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
        
    parentFolder = os.path.dirname(inputFolder)
    # inputFolderName = inputFolder.split(os.path.sep)[-1]
    inputFolderName = os.path.basename(inputFolder)

    if hashRecordFileName is None:
        hashRecordList = glob.glob( parentFolder + os.path.sep + inputFolderName + "*fileNameRecord.txt" )
        if len(hashRecordList) == 1:
            hashRecord = hashRecordList[0]
        elif len(hashRecordList) > 1:
            hashRecord = hashRecordList[0]
            print("WARNING! There are multiple hashRecord files. Check what is going on. The first file will be used.")
        else:
            exit("No hash record found!")
    else:
        hashRecord = parentFolder + os.path.sep + hashRecordFileName

    with open(hashRecord, 'r') as f:
        lines = f.readlines()

    assert lines[0] == "original_file_name\tconverted_file_name\n"

    for line in lines[1:]:
        original_file_name = os.path.join( inputFolder, line.split('\t')[0].strip() )
        converted_file_name = line.split('\t')[1].strip()
        try:
            os.rename( os.path.join( inputFolder, converted_file_name ),
                       os.path.join( inputFolder, original_file_name ) )
        except:
            print("Error occurred when processing:", converted_file_name)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("inputFolder", nargs='?',
                        help="optional; folder containing the files to rename",
                        default=None)
    parser.add_argument("-r", "--hashRecordFileName", nargs='?',
                        help="optional; file name of the hashing record",
                        default=None)
    args = parser.parse_args()

    reverse_hashed_file_names(args.inputFolder, args.hashRecordFileName)
