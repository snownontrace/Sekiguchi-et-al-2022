inputFolder = getDirectory("Choose the folder containing images to process:");

parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
//outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
//if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

cDAPI = 1; // nuclear staining for background ROI segmentation
cEGFP = 2; // EGFP channel for epithelium body segmentation
cHSP47 = 4; // the channel to measure; here the anti-HSP47 staining

run("Close All"); run("Collect Garbage"); // Release occupied memory
run("Clear Results");
roiManager("reset");
setBatchMode(true);

// Create a text file to store measurement results
// Use time stamp to keep different versions from multiple runs
timeStamp = getTime() % 10000;//last four digits of current time in milliseconds
f = File.open(parentFolder + inputFolderPrefix + "-mean-intensity-" + timeStamp + ".txt");
print(f, "file_name" + "," + "z" + "," + "mean_intensity_raw" + "," + "mean_intensity_BG" + "," + "mean_intensity");

flist = getFileList(inputFolder);
for (i=0; i<flist.length; i++) {
	filename = inputFolder + flist[i];
	outputPrefix = getFilenamePrefix(flist[i]);
	if ( endsWith(filename, ".nd2") || endsWith(filename, ".czi") || endsWith(filename, ".tif") ) {
		open(filename); id0 = getImageID();
		Stack.getDimensions(w, h, c, s, frames); //width, height, channels, slices, frames

		for (z = 1; z < s+1; z++) {
			id = getZslice(id0, z);

			idROI = thresholdChannel(id, cEGFP, 5, -1, "Huang"); // -1 disables rolling ball subtraction
			selectImage(idROI);
			run("Create Selection");
			roiManager("add"); // ROI 0

			run("Enlarge...", "enlarge=-20"); // shrink by 20 microns to get the central bud ROI
			roiManager("add"); // ROI 1

			// Use the DAPI channel to segment background ROI
			idBG = thresholdChannel(id, cDAPI, 1, 50, "Default");
			selectImage(idBG);
			run("Create Selection");
			run("Enlarge...", "enlarge=-1"); // shrink by 1 micron to move away from the boundary
			roiManager("add"); // ROI 2

			// get intersection of the central bud and nuclear ROI
			roiManager("select", newArray(1,2));
			roiManager("AND");
			roiManager("add"); // ROI 3
			
			selectImage(id);
			Stack.setChannel(cHSP47);
			roiManager("select", 0);
			getStatistics(areaROI, meanROI);
			roiManager("select", 3);
			getStatistics(areaBG, meanBG);
	
			meanCorrected = meanROI - meanBG;
			
			print(f, flist[i] + "," + z + "," + meanROI + "," + meanBG + "," + meanCorrected);
			
			roiManager("reset"); // clear the ROI manager
		}
		
		run("Close All"); run("Collect Garbage"); // Release memory
	}
}
File.close(f);


function thresholdChannel(id, c, rGaussian, rRollingBall, threshold_method) {
	// Duplicate and threshold the specified channel
	selectImage(id);
	run("Duplicate...", "duplicate channels="+c); idCOI = getImageID();
	selectImage(idCOI);
	run("Gaussian Blur...", "sigma="+rGaussian);
	if (rRollingBall>0) {
		run("Subtract Background...", "rolling="+rRollingBall);
	}
	setAutoThreshold(threshold_method+" dark");
	setOption("BlackBackground", false);
	if ( nSlices==1 ) { run("Convert to Mask"); }
	else { run("Convert to Mask", "method="+threshold_method+" background=Dark calculate"); }
		
	return idCOI;
}

function getZslice(id, zN) {
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
	if ( s == 1 ) { selectImage(idf1); return idf1; }
	if ( s > 1 ) {
		// when only f > 1, in duplicate it has to be called "range"
		if ( c == 1 ) { selectImage(idf1); run("Duplicate...", "duplicate range="+zN+"-"+zN); idzN = getImageID(); }
		if ( c > 1 ) { selectImage(idf1); run("Duplicate...", "duplicate slices="+zN); idzN = getImageID(); }
		selectImage(idzN); return idzN;
	}
}

function getMidZ(id) {
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
	if ( s == 1 ) { selectImage(idf1); return idf1; }
	if ( s > 1 ) {
		sMid = floor( s/2 );
		// when only f > 1, in duplicate it has to be called "range"
		if ( c == 1 ) { selectImage(idf1); run("Duplicate...", "duplicate range="+sMid+"-"+sMid); idMidZ = getImageID(); }
		if ( c > 1 ) { selectImage(idf1); run("Duplicate...", "duplicate slices="+sMid); idMidZ = getImageID(); }
		selectImage(idMidZ); return idMidZ;
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