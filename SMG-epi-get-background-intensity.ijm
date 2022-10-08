inputFolder = getDirectory("Choose the folder containing images to process:");

parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
//outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
//if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

channel_of_interest = 4; // the channel to measure; here the anti-HSP47 staining

run("Close All"); run("Collect Garbage"); // Release occupied memory
run("Clear Results");

// Create a text file to store measurement results
// Use time stamp to keep different versions from multiple runs
timeStamp = getTime() % 10000;//last four digits of current time in milliseconds
f = File.open(parentFolder + inputFolderPrefix + "-BG-mean-intensity-" + timeStamp + ".txt");
print(f, "file_name" + "," + "mean_BG_intensity_b1int");

flist = getFileList(inputFolder);
for (i=0; i<flist.length; i++) {
	if ( endsWith(flist[i], ".nd2") || endsWith(flist[i], ".czi") || endsWith(flist[i], ".tif") ) {
		outputPrefix = getFilenamePrefix(flist[i]);
		open(inputFolder + flist[i]); id0 = getImageID();

		setTool("rectangle");
		waitForUser("Draw a box in the background area");
		
		// Measure backbround intensity
		Stack.setChannel(channel_of_interest);
		run("Measure");
		mean_BG_intensity = getResult("Mean", 0);
		
		print(f, outputPrefix + "," + mean_BG_intensity);
		
		// Clear the results table
		run("Clear Results");
		// Close images
		run("Close All");
	}
}
File.close(f);

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