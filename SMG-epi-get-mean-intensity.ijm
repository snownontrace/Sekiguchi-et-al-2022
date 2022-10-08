inputFolder = getDirectory("Choose the folder containing images to process:");

parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
//outputFolder = parentFolder + inputFolderPrefix + "-output" + File.separator;
//if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }

channel_for_segmentation = 2; // the channel for ROI segmentation; here the EGFP
channel_of_interest = 4; // the channel to measure; here the anti-HSP47 staining
rGaussian = 5; // pixels; radius for Gaussian blur to smoothen the channel
threshold_method = "Huang";
ring_width = 20; // microns to shrink for measuring the ring ROI intensity

run("Close All"); run("Collect Garbage"); // Release occupied memory
run("Clear Results");
setBatchMode(true);

f = File.open(parentFolder + inputFolderPrefix + "-mean-intensity.txt");
print(f, "file_name" + "," + "mean_intensity" + "," + "mean_intensity_ring");

flist = getFileList(inputFolder);
for (i=0; i<flist.length; i++) {
	filename = inputFolder + flist[i];
	outputPrefix = getFilenamePrefix(flist[i]);
	if ( endsWith(filename, ".nd2") || endsWith(filename, ".czi") || endsWith(filename, ".tif") ) {
		open(filename); id = getImageID();
//		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

		idROI = thresholdChannel(id, channel_for_segmentation, rGaussian, threshold_method);
		selectImage(idROI);
		run("Create Selection");
		
		selectImage(id);
		Stack.setChannel(channel_of_interest);
		run("Restore Selection");
		getStatistics(areaROI, meanROI);
		run("Enlarge...", "enlarge=-"+ring_width);
		getStatistics(areaROI_in, meanROI_in);
		meanROI_ring = (areaROI*meanROI - areaROI_in*meanROI_in) / (areaROI-areaROI_in);
		
		print(f, flist[i] + "," + meanROI + "," + meanROI_ring);
		run("Close All"); run("Collect Garbage"); // Release occupied memory
	}
}
File.close(f);

function thresholdChannel(id, c, rGaussian, threshold_method) {
	// Duplicate and threshold the specified channel
	selectImage(id);
	run("Duplicate...", "duplicate channels="+c); idCOI = getImageID();
	selectImage(idCOI);
	run("Gaussian Blur...", "sigma="+rGaussian);
	setAutoThreshold(threshold_method+" dark");
	setOption("BlackBackground", false);
	if ( nSlices==1 ) { run("Convert to Mask"); }
	else { run("Convert to Mask", "method="+threshold_method+" background=Dark calculate"); }
		
	return idCOI;
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