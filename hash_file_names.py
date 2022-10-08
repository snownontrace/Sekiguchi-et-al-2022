import os, glob, argparse, hashlib
import tkinter as tk
from tkinter.filedialog import askdirectory
from datetime import datetime

def hash_file_names(inputFolder=None):
    '''
    Input:
    ------
    inputFolder:
        The folder containing the files to rename.

    Output:
    -------
        Rename all file names to the hashed file names.

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

    # unlock files in the folder (nd2 files off some imaging systems are often locked by default)
    ### chflags = change flags on files/folders such as "locked"
    ### -R = recursive or for everything and follow directories within the specified directory
    ### nouchg = means the file can be changed
    os.system('chflags -R nouchg '+inputFolder)
    
    parentFolder = os.path.dirname(inputFolder)
    # inputFolderName = inputFolder.split(os.path.sep)[-1]
    inputFolderName = os.path.basename(inputFolder)

    # Look for existing hash record files
    hashRecordList = glob.glob( parentFolder + os.path.sep + inputFolderName + "*fileNameRecord.txt" )
    if len(hashRecordList) == 0:
        hashRecord = make_hash_record(inputFolder)
    elif len(hashRecordList) == 1:
        hashRecord = hashRecordList[0]
        print("Hash record found! Files will be renamed according to this record.")
    else:
        hashRecord = hashRecordList[0]
        print("Multiple hash records found! The first one will be used.")

    with open(hashRecord, 'r') as f:
        lines = f.readlines()

    assert lines[0] == "original_file_name\tconverted_file_name\n"

    for line in lines[1:]:
        original_file_name = os.path.join( inputFolder, line.split('\t')[0].strip() )
        converted_file_name = line.split('\t')[1].strip()
        try:
            os.rename( os.path.join( inputFolder, original_file_name ),
                       os.path.join( inputFolder, converted_file_name ) )
        except:
            print("Error occurred when processing:", original_file_name)

def make_hash_record(inputFolder):
    '''
    Input:
    ------
    inputFolder:
        The folder containing the files to rename.

    Output:
    -------
        A text file of a list of original file names and converted file names (hashed).
    '''

    fList = glob.glob( inputFolder + os.path.sep + "*.*" )
    if len(fList) == 0:
        exit("No files in this folder!")

    now = datetime.now()
    timeStamp = datetime.timestamp(now)

    hashRecord = os.path.dirname(inputFolder) + os.path.sep + \
                 os.path.basename(inputFolder) + "-" + \
                 str(int(timeStamp)) + \
                 "-fileNameRecord.txt"

    fileNameRecord = open( hashRecord, "w" )

    # print the first line as the header
    print("original_file_name" + "\t" + "converted_file_name", file = fileNameRecord)

    for f in fList:
        filename, file_extension = os.path.splitext(f)
        hashedF = hashlib.md5(f.encode())
        newFileName = hashedF.hexdigest() + file_extension
        print( os.path.basename(f) + "\t" + newFileName, file = fileNameRecord )

    fileNameRecord.close()

    return hashRecord

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("inputFolder", nargs='?',
                        help="optional; folder containing the files to rename",
                        default=None)
    args = parser.parse_args()

    hash_file_names(args.inputFolder)
