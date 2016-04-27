// make avi from tif to use bemovi

// work in batch mode
setBatchMode(true);

// paths to in- and output files
tif_input = '1_raw_tiff/';
avi_output = '1_raw/';

// read list of files for input
list = getFileList(tif_input);

// loop over all these files
  for (i=0; i<lengthOf(list); i++) {
  
  // open the focal file
  file=tif_input+list[i];
  open(file);
  
  // convert to 8 bit for comparability
  run("8-bit");
  
  // convert and save as avi
  outfile = avi_output+substring(list[i],0,11)+".avi";
  run("AVI... ", "compression=JPEG frame=25 save=outfile");
  
  // close window
  close();
  
  }

// quit ImageJ
run("Quit");
