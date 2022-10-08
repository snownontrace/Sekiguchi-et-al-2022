inputFolder = getDirectory("Choose the folder containing images to process:");
// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
//outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
//if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

flist = getFileList(inputFolder);

f = File.open(parentFolder + inputFolderPrefix + "-budCount.txt");
print(f, "file name" + "\t" + "number of buds");

run("Clear Results");
run("Close All");

for (i=0; i<flist.length; i++) {
	showProgress(i+1, flist.length);
	filename = inputFolder+flist[i];
	if ( endsWith(filename, ".tif") | endsWith(filename, ".nd2") ) {
		open(filename);
		run("Z Project...", "projection=[Min Intensity]");
		run("Enhance Contrast", "saturated=0");

		setTool("multipoint");
		waitForUser("Mark all the buds that you think are buds:");
		run("Measure");
		print(f, flist[i] + "\t" + nResults);

		run("Clear Results");
		run("Close All");
	}
}

// reset tool to rectangle
setTool("rectangle");

function getPath(pathFileOrFolder) {
	// this one takes full path of the file (input can also be a folder) and returns the parent folder path
	temp = split(pathFileOrFolder, File.separator);
	if ( File.separator == "/" ) {
	// Mac and unix system
		pathTemp = File.separator;
		for (i=0; i<temp.length-1; i++) {pathTemp = pathTemp + temp[i] + File.separator;}
	}
	if ( File.separator == "\\" ) {
	// Windows system
		pathTemp = temp[0] + File.separator;
		for (i=1; i<temp.length-1; i++) {pathTemp = pathTemp + temp[i] + File.separator;}
	}
	return pathTemp;
}

function getPathFilenamePrefix(pathFileOrFolder) {
	// this one takes full path of the file
	temp = split(pathFileOrFolder, File.separator);
	temp = temp[temp.length-1];
	temp = split(temp, ".");
	return temp[0];
}

function getFilenamePrefix(filename) {
	// this one takes just the file name without folder path
	temp = split(filename, ".");
	return temp[0];
}
