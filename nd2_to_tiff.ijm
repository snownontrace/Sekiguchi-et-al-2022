inputFolder = getDirectory("Choose the folder containing images to process:");

// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

run("Close All");
setBatchMode(true);

processFolder(inputFolder, outputFolder);


function processFolder(inputFolder, outputFolder) {
	
	flist = getFileList(inputFolder);
//	for (i=0; i<2; i++) {//for testing
	for (i=0; i<flist.length; i++) {
		filename = inputFolder + flist[i];
		outputPrefix = getFilenamePrefix(flist[i]);
		
		if ( endsWith(filename, ".nd2") ) {
			open(filename);	
			saveAs("Tiff", outputFolder + outputPrefix + ".tif");
			run("Close All");
		}
	}
	
}

// scale the image using saturation, change to 8-bit and save it
function to8bitSatu( id, cName, satu, outputFolder, outputPrefix ){
	selectImage(id); run("Grays"); run("Enhance Contrast", "saturated="+satu); run("8-bit");
	outputFilename = outputPrefix + "-" + cName + "-8bit.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
	//id8bit = getImageID(); return id8bit;
}

// scale the image using specified min and max, change to 8-bit and save it
function to8bitMinMax( id, cName, imgMin, imgMax, outputFolder, outputPrefix ){
	selectImage(id); run("Grays"); setMinAndMax(imgMin, imgMax); run("8-bit");
	outputFilename = outputPrefix + "-" + cName + "-8bit.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
	//id8bit = getImageID(); return id8bit;
}

// open 2 images, make a 2 x 1 montage from them
function montage2( f1, f2, outputFolder, outputPrefix ){
	open(outputFolder + f1); rename("montage-1");
	open(outputFolder + f2); rename("montage-2");
	run("Images to Stack", "name=Stack title=[montage] use");
	run("Make Montage...", "columns=2 rows=1 scale=0.50");
	outputFilename = outputPrefix + "-2Montage.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

// open 3 images, make a 3 x 1 montage from them
function montage3( f1, f2, f3, outputFolder, outputPrefix ){
	open(outputFolder + f1); rename("montage-1");
	open(outputFolder + f2); rename("montage-2");
	open(outputFolder + f3); rename("montage-3");
	run("Images to Stack", "name=Stack title=[montage] use");
	run("Make Montage...", "columns=3 rows=1 scale=0.50");
	outputFilename = outputPrefix + "-3Montage.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function montage4( f1, f2, f3, f4, outputFolder, outputPrefix ){
	// open 4 images, make a 4 x 1 montage from them
	open(outputFolder + f1); rename("montage-1");
	open(outputFolder + f2); rename("montage-2");
	open(outputFolder + f3); rename("montage-3");
	open(outputFolder + f4); rename("montage-4");
	run("Images to Stack", "name=Stack title=[montage] use");
	run("Make Montage...", "columns=4 rows=1 scale=0.50");
	outputFilename = outputPrefix + "-4Montage.tif";
	saveAs("Tiff", outputFolder +  outputFilename);
	return outputFilename;
}

function mergeGM( cGreen, greenName, cMagenta, magentaName, outputFolder, outputPrefix ){
	// merge channels in order in green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c6=["+cMagenta+"] keep");
	outputFilename = outputPrefix + "-" + greenName + "_inGreen-" + magentaName + "_inMagenta.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeGC( cGreen, greenName, cCyan, cyanName, outputFolder, outputPrefix ){
	// merge channels in order in green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c5=["+cCyan+"] keep");
	outputFilename = outputPrefix + "-" + greenName + "_inGreen-" + cyanName + "_inCyan.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}


function mergeCM( cCyan, cyanName, cMagenta, magentaName, outputFolder, outputPrefix ){
	// merge channels in order in green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c5=["+cCyan+"] c6=["+cMagenta+"] keep");
	outputFilename = outputPrefix + "-" + cyanName + "_inCyan-" + magentaName + "_inMagenta.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeBGr( cBlue, blueName, cGray, grayName, outputFolder, outputPrefix ){
	// merge channels in order in blue and gray colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c3=["+cBlue+"] c4=["+cGray+"] keep");
	outputFilename = outputPrefix + "-" + blueName + "_inBlue-" + grayName + "_inGray.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeBGM( cBlue, blueName, cGreen, greenName, cMagenta, magentaName, outputFolder, outputPrefix ){
	// merge channels in order in blue, green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c3=["+cBlue+"] c6=["+cMagenta+"] keep");
	outputFilename = outputPrefix + "-" + blueName + "_inBlue-" + greenName + "_inGreen-" + magentaName + "_inMagenta.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeGMY( cGreen, greenName, cMagenta, magentaName, cYellow, yellowName, outputFolder, outputPrefix ){
	// merge channels in order in blue, green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c6=["+cMagenta+"] c7=["+cYellow+"] keep");
	outputFilename = outputPrefix + "-" + greenName + "_inGreen-" + magentaName + "_inMagenta-" + yellowName + "_inYellow" + ".tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeCGMY( cCyan, cyanName, cGreen, greenName, cMagenta, magentaName, cYellow, yellowName, outputFolder, outputPrefix ){
	// merge channels in order in blue, green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c5=["+cCyan+"] c6=["+cMagenta+"] c7=["+cYellow+"] keep");
	outputFilename = outputPrefix + "-" + cyanName + "_inCyan-" + greenName + "_inGreen-" + magentaName + "_inMagenta-" + yellowName + "_inYellow.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
}

function mergeBGMY( cBlue, blueName, cGreen, greenName, cMagenta, magentaName, cYellow, yellowName, outputFolder, outputPrefix ){
	// merge channels in order in blue, green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c3=["+cBlue+"] c6=["+cMagenta+"] c7=["+cYellow+"] keep");
	outputFilename = outputPrefix + "-" + blueName + "_inBlue-" + greenName + "_inGreen-" + magentaName + "_inMagenta-" + yellowName + "_inYellow.tif";
	saveAs("Tiff", outputFolder + outputFilename);
	return outputFilename;
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

function deleteFolder(folder) {
	// Delete all the files inside the folder, then the folder itself
	list = getFileList(folder);
	// Delete the files and the folder
	for (i=0; i<list.length; i++){
		ok = File.delete(folder+list[i]);
	}
	ok = File.delete(folder);
	if (File.exists(folder))
		exit("Unable to delete the folder: " + folder);
	else
		print("Successfully deleted: " + folder);
}