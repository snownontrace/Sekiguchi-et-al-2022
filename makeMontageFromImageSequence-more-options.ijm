//inputFolder = getArgument();
inputFolder = getDirectory("Choose the folder containing images to process:");
//inputFolder = '/Volumes/ShaoheGtech2/2019-DLD-1-and-L-engineering-and-characterization/191025-D193-D266-D267-Ecad-b1integrin/191025-D193-NLS-mNG-561-Ecad-647-beta1integrin-slide2-output/';
//inputFolder = '/Volumes/ShaoheGtech2/2019-DLD-1-and-L-engineering-and-characterization/191025-D193-D266-D267-Ecad-b1integrin/191025-D266-D267-488-Ecad-NLS-mSL-647-beta1integrin-slide2-output/';
//inputFolder = '/Volumes/ShaoheGtech2/2019-DLD-1-and-L-engineering-and-characterization/191220-IF-DLD-1-cells-E-cadherin-integrin/D193-D301-D304-b1integrin-Ecad-costaining-output/';

outputFolder = getPath(inputFolder); // get the parental folder path

postfix1 = "-montage-fluorescence";
filenameContains1 = "-z-1-mNG_inGreen-mSL_inMagenta.tif";//select files

postfix2 = "-montage-merge";
filenameContains2 = "-z-1-phase_inGray-mNG_inGreen-mSL_inMagenta.tif";//select files

postfix3 = "-montage-phase";
filenameContains3 = "-z-1-phase-8bit.tif";//select files

postfix4 = "-mask";
filenameContains4 = "-mask.tif";//select files

postfix5 = "-all-channels";
filenameContains5 = "Ecad_inCyan-mNG_inGreen-mSL_inMagenta-LMN_inYellow.tif";//select files
//filenameContains5 = "-b1int_inCyan-mNG_inGreen-mSL_inMagenta-LMN_inYellow.tif";//select files

postfix6 = "-CY-channels";
filenameContains6 = "Ecad_inCyan-LMN_inYellow.tif";//select files
//filenameContains6 = "-b1int_inCyan-LMN_inYellow.tif";//select files

postfix7 = "-montage";
filenameContains7 = ".tif";//select files

postfix8 = "-collagenase-montage";
filenameContains8 = "-collagenase20-";//select files

postfix9 = "-control-montage";
filenameContains9 = "-control-";//select files

postfix10 = "-BGMY-31-41-montage";
//postfix10 = "-BGMY-montage";
filenameContains10 = "LMN_inBlue-mNG_inGreen-mSL_inMagenta-Ki67_inYellow.tif";//select files

postfix11 = "-YGMC-31-41-montage";
//postfix11 = "-YGMC-montage";
filenameContains11 = "Ki67_inCyan-mNG_inGreen-mSL_inMagenta-LMN_inYellow.tif";//select files

postfix12 = "-GMY-montage";
filenameContains12 = "-GMY-mNG_inGreen-mSL_inMagenta-LMN_inYellow.tif";//select files

postfix13 = "-GC-montage";
filenameContains13 = "-mNG_inGreen-Ecad_inCyan.tif";

postfix14 = "-CM-montage";
filenameContains14 = "-Ecad_inCyan-mSL_inMagenta.tif";

postfix15 = "-NLS-b1int-merge-montage";
filenameContains15 = "-mNG_inGreen-b1int_inCyan.tif";

postfix16 = "-NLS-Ecad-merge-montage";
filenameContains16 = "-mNG_inGreen-Ecad_inMagenta.tif";

postfix17 = "-NLS-Ecad-merge-montage";
filenameContains17 = "-mNG_inGreen-Ecad_inCyan.tif";

postfix18 = "-CM-montage";
filenameContains18 = "-b1int_inCyan-mSL_inMagenta.tif";

postfix19 = "-montage";
filenameContains19 = "8bit.tif";

postfix20 = "-MinIP-Phase-montage";
filenameContains20 = "MinIP-Phase-8bit.tif";


// Shared parameters
nCol = 4;
nRow = 6;

scaleFactor = 0.5;
border_width = 10;

//element_width = 1024;
//figure_width = 65;
//border_width = scaleFactor * element_width * 2 / figure_width;

// specify the starting image number to skip some
startingImage = 1;
incrementStep = 1;

setBatchMode(true);
//processFolder(inputFolder, outputFolder, filenameContains1, postfix1);
//processFolder(inputFolder, outputFolder, filenameContains2, postfix2);
//processFolder(inputFolder, outputFolder, filenameContains3, postfix3);
//processFolder(inputFolder, outputFolder, filenameContains4, postfix4);
//processFolder(inputFolder, outputFolder, filenameContains5, postfix5);
//processFolder(inputFolder, outputFolder, filenameContains6, postfix6);
//processFolder(inputFolder, outputFolder, filenameContains7, postfix7);
//processFolder(inputFolder, outputFolder, filenameContains8, postfix8);
//processFolder(inputFolder, outputFolder, filenameContains9, postfix9);
//processFolder(inputFolder, outputFolder, filenameContains10, postfix10);
//processFolder(inputFolder, outputFolder, filenameContains11, postfix11);
//processFolder(inputFolder, outputFolder, filenameContains12, postfix12);
//processFolder(inputFolder, outputFolder, filenameContains13, postfix13);
//processFolder(inputFolder, outputFolder, filenameContains14, postfix14);
//processFolder(inputFolder, outputFolder, filenameContains15, postfix15);
//processFolder(inputFolder, outputFolder, filenameContains16, postfix16);
//processFolder(inputFolder, outputFolder, filenameContains17, postfix17);
//processFolder(inputFolder, outputFolder, filenameContains18, postfix18);
//processFolder(inputFolder, outputFolder, filenameContains19, postfix19);
processFolder(inputFolder, outputFolder, filenameContains20, postfix20);

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
