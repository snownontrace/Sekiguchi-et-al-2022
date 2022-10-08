inputFolder = getDirectory("Choose the folder containing images to process:");
//inputFolder = '/Volumes/ShaoheGtech2/2019-spheroids-single-time-point/D193-D266-varying-mix-ratio-selected/D193-D266-6dpt/';
//inputFolder = '/Volumes/ShaoheGtech2/2019-spheroids-single-time-point/D193-D266-varying-mix-ratio-selected/D193-D267-7dpt/';
// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

run("Close All");
setBatchMode(true);

Dialog.create("Specify parameters:");
Dialog.addChoice("Process middle slice, minimum projection, or specified slice?", newArray("Middle Slice", "Min Intensity Projection", "Specify Slice Number"));
Dialog.addNumber("Which slice?", 1)
Dialog.addNumber("Height and width to crop (in pixels)?", 1400)
Dialog.addChoice("Keep temp files to accelerate re-processing?", newArray("Yes", "No"));
Dialog.show();

c1name = "phase";
type = Dialog.getChoice();
specifiedSliceNumber = Dialog.getNumber();
crop_width = Dialog.getNumber();
crop_height = crop_width;
keepTemp = Dialog.getChoice();

processFolder(inputFolder, outputFolder);

function processSingleSlice(id0, typePrefix, outputFolder, outputPrefix, crop_width, crop_height) {
	
	id = crop_spheroid_phase(id0, crop_width, crop_height);

	saturation = 0.5; idC1_8bit = to8bitSatuPhase( id, typePrefix + "-" + c1name, saturation, outputFolder, outputPrefix );
	
	return 1;
}

function processFolder(inputFolder, outputFolder) {
	
	tempFolder = outputFolder + inputFolderPrefix + "-temp" + File.separator;
	if ( !(File.exists(tempFolder)) ) { File.makeDirectory(tempFolder); }
	
	flist = getFileList(inputFolder);
	//for (i=0; i<2; i++) {//for testing 2
	for (i=0; i<flist.length; i++) {
		filename = inputFolder + flist[i];
		outputPrefix = getFilenamePrefix(flist[i]);
		
		if ( endsWith(filename, ".nd2") || endsWith(filename, ".czi") || endsWith(filename, ".tif") ) {
			
			if ( type == "Max Intensity Projection" ) {
				tempFile = tempFolder + outputPrefix + "-MIP" + ".tif";
				if ( File.exists(tempFile) ) { open(tempFile); idMIP = getImageID(); }
				else { open(filename); id0 = getImageID(); idMIP = getMIP(id0, tempFile); }
				processSingleSlice(idMIP, "MIP", outputFolder, outputPrefix, crop_width, crop_height);
			}
			if ( type == "Min Intensity Projection" ) {
				tempFile = tempFolder + outputPrefix + "-MinIP" + ".tif";
				if ( File.exists(tempFile) ) { open(tempFile); idMinIP = getImageID(); }
				else { open(filename); id0 = getImageID(); idMinIP = getMinIP(id0, tempFile); }
				processSingleSlice(idMIP, "MIP", outputFolder, outputPrefix, crop_width, crop_height);
			}
			if ( type == "Middle Slice" ) {
				tempFile = tempFolder + outputPrefix + "-midZ" + ".tif";
				if ( File.exists(tempFile) ) { open(tempFile); idMidZ = getImageID(); }
				else { open(filename); id0 = getImageID(); idMidZ = getMidZ(id0, tempFile); }
				processSingleSlice(idMidZ, "midZ", outputFolder, outputPrefix, crop_width, crop_height);
			}
			if ( type == "Specify Slice Number" ) {
				tempFile = tempFolder + outputPrefix + "-z-"+specifiedSliceNumber + ".tif";
				if ( File.exists(tempFile) ) { open(tempFile); idZ = getImageID(); }
				else { open(filename); id0 = getImageID(); idZ = getZslice(id0, specifiedSliceNumber, tempFile); }
				processSingleSlice(idZ, "z-"+specifiedSliceNumber, outputFolder, outputPrefix, crop_width, crop_height);
			}
			run("Close All");
		}
	}
	
	if ( keepTemp == "No" ) deleteFolder(tempFolder);
}

function crop_spheroid_phase(id, crop_width, crop_height){
	// This function takes a 3-channel image, assuming channel 2 and 3 are fluorescent markers of the cells,
	// use the max projection of fluroescence channels to identify the centroid of the object,
	// make a rectangle 

	selectImage(id); w = getWidth(); h = getHeight();
	if (crop_width > w) { exit("specified cropping width is larger than the image width!"); }
	if (crop_height > h) { exit("specified cropping height is larger than the image height!"); }

	// Duplicate the image to segment the spheroid
	selectImage(id); run("Duplicate...", " "); idDup = getImageID();
	// Smoothen the image
	selectImage(idDup); run("Gaussian Blur...", "sigma=10");
	// Subtract background
	run("Subtract Background...", "rolling=200 light");
	// Threshold the image
	setAutoThreshold("Default"); setOption("BlackBackground", false); run("Convert to Mask");
	// Keep the largest object
	run("Keep Largest Region"); idMask = getImageID();
	// Identify the bounding rectangle dimensions
	selectImage(idMask); run("Create Selection"); run("Select Bounding Box"); getBoundingRect(x, y, width, height);
	// Calculate the initial upper left corner coodinates of cropping region
	crop_x = x + width/2 - crop_width/2;
	crop_y = y + height/2 - crop_height/2;
	// Modify the coordinates if the cropping box goes beyond the image boundary
	if ( (crop_x+crop_width) > w ) { crop_x = w - crop_width; }
	if ( crop_x < 0 ) { crop_x = 0; }
	if ( (crop_y+crop_height) > h ) { crop_y = h - crop_height; }
	if ( crop_y < 0 ) { crop_y = 0; }
	
//	print(crop_x);
//	print(crop_y);
//	print(crop_width);
//	print(crop_height);
//	selectImage(id); waitForUser("check this image!");
	
	// Use the calculated coordinates to duplicate the ROI
	selectImage(id); makeRectangle(crop_x, crop_y, crop_width, crop_height); run("Duplicate...", " "); idCrop = getImageID();
	// Close image intermediates
	selectImage(idDup); run("Close");
	selectImage(idMask); run("Close");
	selectImage(id); run("Close");
	
	return idCrop;
}

function crop_spheroid(id, crop_width, crop_height){
	// This function takes a 3-channel image, assuming channel 2 and 3 are fluorescent markers of the cells,
	// use the max projection of fluroescence channels to identify the centroid of the object,
	// make a rectangle 

	selectImage(id); w = getWidth(); h = getHeight();
	if (crop_width > w) { exit("specified cropping width is larger than the image width!"); }
	if (crop_height > h) { exit("specified cropping height is larger than the image height!"); }

	// Make the max projection of fluorescent channels
	selectImage(id); run("Z Project...", "start=2 projection=[Max Intensity]"); idMIP = getImageID();
	// Smoothen the image
	selectImage(idMIP); run("Gaussian Blur...", "sigma=10");
	// Threshold the image
	setAutoThreshold("Huang dark"); setOption("BlackBackground", false); run("Convert to Mask");
	// Keep the largest object
	run("Keep Largest Region"); idMask = getImageID();
	// Identify the bounding rectangle dimensions
	selectImage(idMask); run("Create Selection"); run("Select Bounding Box"); getBoundingRect(x, y, width, height);
	// Calculate the initial upper left corner coodinates of cropping region
	crop_x = x + width/2 - crop_width/2;
	crop_y = y + height/2 - crop_height/2;
	// Modify the coordinates if the cropping box goes beyond the image boundary
	if ( (crop_x+crop_width) > w ) { crop_x = w - crop_width; }
	if ( crop_x < 0 ) { crop_x = 0; }
	if ( (crop_y+crop_height) > h ) { crop_y = h - crop_height; }
	if ( crop_y < 0 ) { crop_y = 0; }
	// Use the calculated coordinates to duplicate the ROI
	selectImage(id); makeRectangle(crop_x, crop_y, crop_width, crop_height); run("Duplicate...", " "); idDup = getImageID();
	// Close image intermediates
	selectImage(idMIP); run("Close");
	selectImage(idMask); run("Close");
	selectImage(id); run("Close");
	
	return idDup;
}

function adjustColorScheme(id) {
	selectImage(id); run("Make Composite");
	Stack.setChannel(1); run("Grays"); satu = 0.5; run("Enhance Contrast", "saturated="+satu);
	Stack.setChannel(2); run("Green"); setMinAndMax(150, 10000);
	Stack.setChannel(3); run("Magenta"); setMinAndMax(50, 50000);
}

function getChannel(id, c) {
	selectImage(id); run("Duplicate...", "duplicate channels="+c); idC = getImageID(); return idC;
}

function getMidZ(id, tempFile) {
	selectImage(id);
	if ( nSlices > 1 ) { Stack.getDimensions(w, h, c, s, f); } //width, height, channels, slices, frames
	if ( f == 1 ) { idf1 = id; }
	if ( f > 1 && c*s == 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		selectImage(id); run("Duplicate...", "duplicate range=1-1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( f > 1 && c*s > 1 ) {
		selectImage(id); run("Duplicate...", "duplicate frames=1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( s == 1 ) { selectImage(idf1); save(tempFile); return idf1; }
	if ( s > 1 ) {
		sMid = floor( s/2 );
		// when only f > 1, in duplicate it has to be called "range"
		if ( c == 1 ) { selectImage(idf1); run("Duplicate...", "duplicate range="+sMid+"-"+sMid); idMidZ = getImageID(); }
		if ( c > 1 ) { selectImage(idf1); run("Duplicate...", "duplicate slices="+sMid); idMidZ = getImageID(); }
		selectImage(idMidZ); save(tempFile); return idMidZ;
	}
}

function getZslice(id, zN, tempFile) {
	selectImage(id);
	if ( nSlices > 1 ) { Stack.getDimensions(w, h, c, s, f); } //width, height, channels, slices, frames
	if ( f == 1 ) { idf1 = id; }
	if ( f > 1 && c*s == 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		selectImage(id); run("Duplicate...", "duplicate range=1-1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( f > 1 && c*s > 1 ) {
		selectImage(id); run("Duplicate...", "duplicate frames=1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( s == 1 ) { selectImage(idf1); save(tempFile); return idf1; }
	if ( s > 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		if ( c == 1 ) { selectImage(idf1); run("Duplicate...", "duplicate range="+zN+"-"+zN); idzN = getImageID(); }
		if ( c > 1 ) { selectImage(idf1); run("Duplicate...", "duplicate slices="+zN); idzN = getImageID(); }
		selectImage(idzN); save(tempFile); return idzN;
	}
}

function getMinIP(id, tempFile) {
	selectImage(id);
	//if ( nSlices > 1 ) { Stack.getDimensions(w, h, c, s, f); } //width, height, channels, slices, frames
	Stack.getDimensions(w, h, c, s, f); //width, height, channels, slices, frames
	if ( f == 1 ) { idf1 = id; }
	if ( f > 1 && c*s == 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		selectImage(id); run("Duplicate...", "duplicate range=1-1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( f > 1 && c*s > 1 ) {
		selectImage(id); run("Duplicate...", "duplicate frames=1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( s == 1 ) { selectImage(idf1); save(tempFile); return idf1; }
	if ( s > 1 ) { selectImage(idf1); run("Z Project...", "projection=[Min Intensity]"); idMinIP = getImageID(); save(tempFile); return idMinIP;}
}

function getMIP(id, tempFile) {
	selectImage(id);
	//if ( nSlices > 1 ) { Stack.getDimensions(w, h, c, s, f); } //width, height, channels, slices, frames
	Stack.getDimensions(w, h, c, s, f); //width, height, channels, slices, frames
	if ( f == 1 ) { idf1 = id; }
	if ( f > 1 && c*s == 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		selectImage(id); run("Duplicate...", "duplicate range=1-1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( f > 1 && c*s > 1 ) {
		selectImage(id); run("Duplicate...", "duplicate frames=1"); idf1 = getImageID();
		print("There are multiple time frames. Processing only the first time point.");
		print("WARNING: It is unusual to have multiple frames for IF images, please look into your images.");
	}
	if ( s == 1 ) { selectImage(idf1); save(tempFile); return idf1; }
	if ( s > 1 ) { selectImage(idf1); run("Z Project...", "projection=[Max Intensity]"); idMIP = getImageID(); save(tempFile); return idMIP;}
}

function makeMIPfolder(inputFolder, outputFolder) {
	flist = getFileList(inputFolder);
	for (i=0; i<flist.length; i++) {
		filename = inputFolder + flist[i];
		outputPrefix = getFilenamePrefix(flist[i]);
		if ( endsWith(filename, ".nd2") || endsWith(filename, ".czi") || endsWith(filename, ".tif") ) {
			open(filename); id0 = getImageID();
			idMIP = getMIP(id0);
			save(outputFolder + outputPrefix + "-MIP.tif");
			run("Close All");
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

// scale the image using global min and specified saturation of max, change to 8-bit and save it
function to8bitSatuPhase( id, cName, satu, outputFolder, outputPrefix ){
	selectImage(id); run("Grays");
//	run("Enhance Contrast", "saturated=0.01"); getMinAndMax(min1, max1);
	run("Enhance Contrast", "saturated="+satu); getMinAndMax(min2, max2);
	setMinAndMax(0, max2); run("8-bit");
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

function mergeGM( cGreen, greenName, cMagenta, magentaname, outputFolder, outputPrefix ){
	// merge channels in order in green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c6=["+cMagenta+"] keep");
	outputFilename = outputPrefix + "-" + greenName + "_inGreen-" + magentaname + "_inMagenta.tif";
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

function mergeGrGM( cGray, grayName, cGreen, greenName, cMagenta, magentaName, outputFolder, outputPrefix ){
	// merge channels in order in gray, green and magenta colors
	// c1: red; c2: green; c3:blue; c4:gray; c5:cyan; c6: magenta; c7: yellow
	run("Merge Channels...", "c2=["+cGreen+"] c4=["+cGray+"] c6=["+cMagenta+"] keep");
	outputFilename = outputPrefix + "-" + grayName + "_inGray-" + greenName + "_inGreen-" + magentaName + "_inMagenta.tif";
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