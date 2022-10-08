//inputFolder = getArgument();
inputFolder = getDirectory("Choose the folder containing images to process:");

outputFolder = getPath(inputFolder); // get the parental folder path

postfix1 = "-montage";
filenameContains1 = "phase-8bit.tif";


// Shared parameters
nCol = 10;
nRow = 2;

scaleFactor = 0.5;
border_width = 10;

//element_width = 1024;
//figure_width = 65;
//border_width = scaleFactor * element_width * 2 / figure_width;

// specify the starting image number to skip some
startingImage = 1;
incrementStep = 1;

setBatchMode(true);
processFolder(inputFolder, outputFolder, filenameContains1, postfix1);

// If processing multiple folders in a parental folder:
//processFolders(inputFolder, outputFolder);

//make Montage
function processFolder(folder, outputFolder, filenameContains, postfix) {
	run("Image Sequence...", "open=["+folder+"] starting="+startingImage+" increment="+incrementStep+" file="+filenameContains+" sort");
//	run("Make Montage...", "columns="+nCol+" rows="+nRow+" scale="+scaleFactor);
	setForegroundColor(255, 255, 255);
	run("Make Montage...", "columns="+nCol+" rows="+nRow+" scale="+scaleFactor+" border="+border_width+" use");

	folderParts = split(folder,"/");
	outTifName = folderParts[folderParts.length - 1] + postfix + ".tif";
	outJpegName = folderParts[folderParts.length - 1] + postfix + ".jpeg";
	saveAs("Tiff", outputFolder + outTifName);
	saveAs("Jpeg", outputFolder + outJpegName);
	run("Close All");
}

function processFolders(inputFolder, outputFolder) {
	list = getFileList(inputFolder);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/"))
			processFolder(inputFolder+list[i], outputFolder);
	}
}

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
