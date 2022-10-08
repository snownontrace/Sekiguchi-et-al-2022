//macroName = "/Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMGepi-lenti-CRISPR-paper/scripts/fixed-images-general-220608-b1int-IF-time-course-get-arguments.ijm";
macroName = "/Users/wangs20/Box/Shaohe-Box-Yamada-Lab/_SMGepi-lenti-CRISPR-paper/scripts/fixed-images-general-220608-b1int-IF-E16-get-arguments.ijm";

dir = getDirectory("Choose the parent folder containing folders to process:");
fList = getFileList(dir);

for (i=0; i<fList.length; i++) {
	if ( File.isDirectory(dir + fList[i]) ) {
		if ( !( endsWith(fList[i], "output"+File.separator) ) ) {
//		if ( endsWith(fList[i], "output"+File.separator) ) {
			runMacro(macroName, dir + fList[i]);
		}
	}
}