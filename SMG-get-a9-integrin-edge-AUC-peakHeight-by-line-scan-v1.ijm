inputFolder = getDirectory("Choose the folder containing images to process:");

// Create an output folder based on the inputFolder
parentFolder = getPath(inputFolder); inputFolderPrefix = getPathFilenamePrefix(inputFolder);
outputFolder = parentFolder + inputFolderPrefix + "-line-scan-output" + File.separator;
if ( !(File.exists(outputFolder)) ) { File.makeDirectory(outputFolder); }
rawLinescanFolder = outputFolder + "raw-linescan-profile-record" + File.separator;
if ( !(File.exists(rawLinescanFolder)) ) { File.makeDirectory(rawLinescanFolder); }

line_width = 3; // in microns; the script will use image-embedded pixel size information to convert into pixels
n_edges = 5; // number of edges to quantify per filed of view
cITGA9 = 4; // the channel number of alpha9-integrin staining
cNLSmSL = 3; // the channel number of NLS-mSarlet-I

run("Close All"); run("Collect Garbage"); // Release occupied memory
run("Clear Results");
setBatchMode(false); // always needs user input (draw line)

// Create a text window to record the summary metrics of E-cadherin quantification
// Note: this is to create a separate holder to circumvent that the ImageJ macro only allows 1 open file handle at a time
sumTextWindow = "Ecad-quantification-Summary";
if ( isOpen(sumTextWindow) ) { print("["+sumTextWindow+"]", "\\Update:"); } // clears the window
else { run("Text Window...", "name=["+sumTextWindow+"]"); }
print("["+sumTextWindow+"]", "file_name" + "," + "edge_category" + "," + "id" + "," + "a9int_AUC" + "," + "a9int_peak_height" + "," + "NLSmSL_cell_1" + "," + "NLSmSL_cell_2" + "," + "z_position");

fileList = getFileList(inputFolder);
for (i=0; i<fileList.length; i++) {
//for (i=0; i<1; i++) {// uncomment to run only 1 image for testing
	// loop through the file list
	filename = inputFolder + fileList[i];
	outputPrefix = getFilenamePrefix(fileList[i]);
	if ( endsWith(filename, ".nd2") || endsWith(filename, ".czi") || endsWith(filename, ".tif") ) {
		// only process image files that ends with nd2, czi or tif
		open(filename); id = getImageID();
		// get pixel size and convert desired micron-unit of line width to pixel size
		getPixelSize(unit, pixelWidth, pixelHeight);
		if (unit == "microns") {
			line_width_px = round(line_width / pixelWidth);
		}
		else {
			print("WARNING: pixel size is not in microns. Check image scaling.");
			line_width_px = 30; // assuming pixel size is ~0.1 micron, a close estimate for 60x high-resolution immunostaining images
		}

		for (id_edge=1; id_edge<n_edges+1; id_edge++) {
//		for (id_edge=1; id_edge<n_edges*3+1; id_edge++) {
			// Determine the current edge category
			if ( id_edge < n_edges+1 ) { edge_category = "High_High"; }
			if ( (id_edge > n_edges*2) & (id_edge <n_edges*2+1) ) { edge_category = "High_Low"; }
			if ( id_edge > n_edges*2 ) { edge_category = "Low_Low"; }
			
			// ask user to draw a line to get the line scan profile
			setTool("line"); run("Line Width...", "line="+line_width_px); // line width can be adjusted to what you think is appropriate
			waitForUser("Draw a line across an in-focus edge for adjacent NLSmSL " + edge_category + " cells:");
			
			// open a text file to store the line scan profile
			textRecord = rawLinescanFolder + outputPrefix + "-" + id_edge + "-a9int.txt";
			f = File.open(textRecord);
			print(f, "a9int_intensity");
			
			// Get raw data of the E-cadherin line scan profile
			selectImage(id); Stack.setChannel(cITGA9);
			profile = getProfile();
			for (j=0; j<profile.length; j++) {
				print(f, profile[j]);
			}
			File.close(f); // Close the file after saving all line scan values

			a9int_AUC = getAUC(profile);
			a9int_peak_height = getPeakHeight(profile);

			// open a text file to store the line scan profile
			textRecord = rawLinescanFolder + outputPrefix + "-" + id_edge + "-NLSmSL.txt";
			f = File.open(textRecord);
			print(f, "NLSmSL_intensity");
			
			// Get raw data of the NLSmSL line scan profile
			selectImage(id); Stack.setChannel(cNLSmSL);
			profile = getProfile();
			for (j=0; j<profile.length; j++) {
				print(f, profile[j]);
			}
			File.close(f); // Close the file after saving all line scan values

			NLSmSL_cell_1 = getNLSmSL1(profile);
			NLSmSL_cell_2 = getNLSmSL2(profile);

			Stack.getPosition(channel, z_position, frame);
			print("["+sumTextWindow+"]", "\n" + outputPrefix + "," + edge_category + "," + id_edge + "," + a9int_AUC + "," + a9int_peak_height + "," + NLSmSL_cell_1 + "," + NLSmSL_cell_2 + "," + z_position);

			run("Draw", "slice"); // Draw ROI on the image to avoid repeat measurements
		}

		// Duplicate the single slice image and save for record (or re-run line scan on a smaller data set if necessary)
		selectImage(id); run("Close");
	}
}

// Save and the summary text window
selectWindow(sumTextWindow);
inputFolderPrefix = getPathFilenamePrefix(inputFolder);
timeFinish = getTime(); timeStamp = timeFinish % 10000;// time stamp for saving log and summary text files
sumOutFile = outputFolder + inputFolderPrefix + "-" + sumTextWindow + "-" + timeStamp + ".txt";
saveAs("txt", sumOutFile); run("Close");

setTool("rectangle");
run("Close All");
run("Collect Garbage");
run("Clear Results");



function getAUC(profile) {
	background_length = floor(profile.length/10);
	background_profile = Array.trim(profile, background_length);
	Array.getStatistics(background_profile, min, max, mean_background, stdDev);
	Array.getStatistics(profile, min, max, mean_raw, stdDev);
	AUC = profile.length * (mean_raw - mean_background);
	return AUC;
}

function getPeakHeight(profile) {
	background_length = floor(profile.length/10);
	background_profile = Array.trim(profile, background_length);
	Array.getStatistics(background_profile, min, max, mean_background, stdDev);
	Array.getStatistics(profile, min, max_raw, mean, stdDev);
	peak_height = max_raw - mean_background;
	return peak_height;
}

function getNLSmSL1(profile) {
	NLSmSL1_length = floor(profile.length/3);
	NLSmSL1_profile = Array.trim(profile, NLSmSL1_length);
	Array.getStatistics(NLSmSL1_profile, min, max, mean, stdDev);
	return mean;
}

function getNLSmSL2(profile) {
	NLSmSL2_length = floor(profile.length/3);
	NLSmSL2_profile = Array.slice(profile, profile.length-NLSmSL2_length);
	Array.getStatistics(NLSmSL2_profile, min, max, mean, stdDev);
	return mean;
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
