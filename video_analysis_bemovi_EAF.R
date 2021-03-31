######################################################################
# R script for analysing video files with BEMOVI (www.bemovi.info)
#
# Emanuel A. Fronhofer
#
# February 2021
######################################################################
rm(list=ls())

# load package
#library(devtools)
#install_github("efronhofer/bemovi", ref="experimental")
library(bemovi)

######################################################################
# ANALYSIS TYPE / data location ("local" vs "remote")
data_location <- "remote"
location_on_server <- "XXX/XXX"

######################################################################
# DATA SOURCE ("microscope" or "cytation")
# note: the script is optimized to be used with the Perfex microscope PRO881 with 1x objective and with the Cytation5 2.5x magnification
data_source <- "cytation"

# magnification
# this parameter sets "measured_volume" and "pixel_to_scale" for Perfex Pro 10 stereomicrocope with Perfex SC38800 (IDS UI-3880LE-M-GL) camera and sample height = 0.5mm as well as for Cytation 5 with 2.5x magnification
# possible values (microscope): 0.8, 1, 2, 3 CURRENTLY ONLY 1 AND 2 WORK
# possible values (cytation): 2.5
# if other devices are used, set the two parameters manually
magnification <- 2.5

######################################################################
# VIDEO PARAMETERS: these should always be the same

# video frame rate (in frames per second)
fps <- 15
# length of video (in frames)
total_frames <- 150

######################################################################
# MORE PARAMETERS (USUALLY NOT CHANGED)

# RAM allocation (in fraction of total RAM)
max_RAM_fraction <- 0.96

# RAM per particle linker instance (in MB)
memory.alloc.perLinker <- c(3000)

# UNIX
# set paths to ImageJ and particle linker standalone
IJ.path <- paste0("/home/",Sys.info()[["user"]],"/bin/ImageJ")
to.particlelinker <- paste0("/home/",Sys.info()[["user"]],"/bin/ParticleLinker")

# check whether the files exist
execute_analysis <- TRUE

if(!(file.exists(IJ.path) & file.exists(to.particlelinker))){
  print("ImageJ or particlelinker files not found!")
  execute_analysis <- FALSE
}

# get total RAM
total_ram <- as.numeric(system("echo $(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024)))", intern=T))
# use fraction of total RAM defined by "max_RAM_fraction"
memory.alloc <- round(total_ram*max_RAM_fraction)


# WINDOWS
# set paths to ImageJ, particle linker standalone and java
# note: paths should not be too long (less than 250 characters incl. folder and file names)
#IJ.path <- "C:/ImageJ/ImageJ.exe"
#to.particlelinker <- "C:/"
#java.path <- "C:/java/bin/javaw.exe"

# WINDOWS WARNING: some parts of the script don't work under windows!

# directories and file names
to.data <- paste(getwd(),"/",sep="")
video.description.folder <- "0_video_description/"
video.description.file <- "video_description.txt"
raw.video.folder <- "1_raw/"
particle.data.folder <- "2_particle_data/"
trajectory.data.folder <- "3_trajectory_data/"
temp.overlay.folder <- "4a_temp_overlays/"
overlay.folder <- "4_overlays/"
merged.data.folder <- "5_merged_data/"
ijmacs.folder <- "ijmacs/"

# server location for remote data
base_path_server <- "/media/data_nas"

######################################################################
# SET MEASURED VOLUME AND PIXELS TO SCALE BASED ON MAGNIFICATION

if(!is.element(data_source, c("microscope", "cytation"))){
  print("Data source unknown! Please modify")
  execute_analysis <- FALSE
}else{
  
  if(data_source=="microscope"){
    
    # specify video file format (one of "avi","cxd","mov","tiff")
    # bemovi only works with avi and cxd. other formats are reformated to avi below
    video.format <- "avi"
    
    image_resolution <- c(3088, 2076)
    
    if(!is.element(magnification, c(0.8,1,2,3))){
      print("Magnification unknown! Please modify")
      execute_analysis <- FALSE
    }else{
      if(magnification==0.8){
        # measured volume (in microliter)
        measured_volume <- 172.69
        # size of a pixel (in micrometer)
        pixel_to_scale <- 7.34
      }
      if(magnification==1){
        # measured volume (in microliter)
        measured_volume <- 118.49
        # size of a pixel (in micrometer)
        pixel_to_scale <- 6.08
        
        ######################################################################
        # SEGMENTATION PARAMETERS 
        
        difference.lag <- 10
        thresholds <- c(20,255) # don't change the second value
        
        ######################################################################
        # FILTERING PARAMETERS 
        # optimized for Perfex Pro 10 stereomicrocope with Perfex SC38800 (IDS UI-3880LE-M-GL) camera
        # tested stereomicroscopes: Perfex Pro 10, Nikon SMZ1500, Leica M205 C
        # tested cameras: Perfex SC38800, Canon 5D Mark III, Hamamatsu Orca Flash 4
        # tested species: Tet, Col, Pau, Pca, Eug, Chi, Ble, Ceph, Lox, Spi
        
        # min and max size: area in pixels
        particle_min_size <- 5
        particle_max_size <- 1000
        
        # number of adjacent frames to be considered for linking particles
        trajectory_link_range <- 3
        # maximum distance a particle can move between two frames
        trajectory_displacement <- 30
        
        # these values are in the units defined by the parameters above: fps (seconds), measured_volume (microliters) and pixel_to_scale (micometers)
        filter_min_net_disp <-25
        filter_min_duration <- 1
        filter_detection_freq <- 0.1
        filter_median_step_length <- 1
        
        ######################################################################
        
      }
      if(magnification==2){
        # measured volume (in microliter)
        measured_volume <- 31
        # size of a pixel (in micrometer)
        pixel_to_scale <- 3.11
        
        ######################################################################
        # SEGMENTATION PARAMETERS 
        
        difference.lag <- 10
        thresholds <- c(20,255) # don't change the second value
        
        ######################################################################
        # FILTERING PARAMETERS 
        # optimized for Perfex Pro 10 stereomicrocope with Perfex SC38800 (IDS UI-3880LE-M-GL) camera
        # tested stereomicroscopes: Perfex Pro 10, Nikon SMZ1500, Leica M205 C
        # tested cameras: Perfex SC38800, Canon 5D Mark III, Hamamatsu Orca Flash 4
        # tested species: Tet, Col, Pau, Pca, Eug, Chi, Ble, Ceph, Lox, Spi
        
        # min and max size: area in pixels
        particle_min_size <- 5
        particle_max_size <- 1000
        
        # number of adjacent frames to be considered for linking particles
        trajectory_link_range <- 3
        # maximum distance a particle can move between two frames
        trajectory_displacement <- 30
        
        # these values are in the units defined by the parameters above: fps (seconds), measured_volume (microliters) and pixel_to_scale (micometers)
        filter_min_net_disp <-25
        filter_min_duration <- 1
        filter_detection_freq <- 0.1
        filter_median_step_length <- 1
        
        ######################################################################
        
      }
      if(magnification==3){
        # measured volume (in microliter)
        measured_volume <- 13.73
        # size of a pixel (in micrometer)
        pixel_to_scale <- 2.07
      }
    }
    
    
  }
  if(data_source=="cytation"){
    
    # specify video file format (one of "avi","cxd","mov","tiff")
    # bemovi only works with avi and cxd. other formats are reformated to avi below
    video.format <- "wmv"
    
    image_resolution <- c(1992, 1992)
    
    if(!is.element(magnification, c(2.5))){
      print("Magnification unknown! Please modify")
      execute_analysis <- FALSE
    }else{
      if(magnification==2.5){
        # correction factor (extracted empirically from correlation)
        vol_corr_fact <- 2.1
        # measured volume (in microliter)
        measured_volume <- 6.177^2 * 0.1872 * vol_corr_fact #square field of view (in mm) times depth of field (in mm)
        # size of a pixel (in micrometer)
        pixel_to_scale <- 6177/1992 # field of view in µm / rresolution in pix
        
        ######################################################################
        # SEGMENTATION PARAMETERS 
        
        difference.lag <- 10
        thresholds <- c(15,255) # don't change the second value
        
        ######################################################################
        # FILTERING PARAMETERS 
        # optimized for Perfex Pro 10 stereomicrocope with Perfex SC38800 (IDS UI-3880LE-M-GL) camera
        # tested stereomicroscopes: Perfex Pro 10, Nikon SMZ1500, Leica M205 C
        # tested cameras: Perfex SC38800, Canon 5D Mark III, Hamamatsu Orca Flash 4
        # tested species: Tet, Col, Pau, Pca, Eug, Chi, Ble, Ceph, Lox, Spi
        
        # min and max size: area in pixels
        particle_min_size <- 20
        particle_max_size <- 3000
        
        # number of adjacent frames to be considered for linking particles
        trajectory_link_range <- 3
        # maximum distance a particle can move between two frames
        trajectory_displacement <- 50#16#100
        
        # these values are in the units defined by the parameters above: fps (seconds), measured_volume (microliters) and pixel_to_scale (micometers)
        filter_min_net_disp <-100#25
        filter_min_duration <- 0.1 #0.25
        filter_detection_freq <- 0.1
        filter_median_step_length <- 5
        
        ######################################################################
        
      }
    }
  }
  
}

# measured volume (in microliter)
#measured_volume <- 34.4 # for Leica M205 C with 1.6 fold magnification, sample height 0.5 mm and Hamamatsu Orca Flash 4
#measured_volume <- 14.9 # for Nikon SMZ1500 with 2 fold magnification, sample height 0.5 mm and Canon 5D Mark III

# size of a pixel (in micrometer)
#pixel_to_scale <- 4.05 # for Leica M205 C with 1.6 fold magnification, sample height 0.5 mm and Hamamatsu Orca Flash 4
#pixel_to_scale <- 3.79 # for Nikon SMZ1500 with 2 fold magnification, sample height 0.5 mm and Canon 5D Mark III

######################################################################
# get data if data location is remote, i.e. on server
if(data_location == "remote"){
  # get correct path (local and remote MUST match)
  project_path_server <- paste0(base_path_server, "/", location_on_server)
  # check if the folder exists
  if(file.exists(project_path_server)){
    # get no. of files to copy
    no_files_to_copy <- length(list.files(project_path_server, recursive = T))
    # copy data
    system(paste0("cp -r ",project_path_server,"/* ", getwd()))
    
    # check how many files are now locally
    no_files_locally <- length(list.files(getwd(), recursive = T))
    
    if (no_files_locally != (no_files_to_copy+1)){
      print("COPY ERROR FROM SERVER: FILE NUMBERS INCORRECT")
      execute_analysis <- FALSE
    }
    
  }else{
    print("REMOTE LOCATION DOES NOT EXIST")
    execute_analysis <- FALSE
  }
}

######################################################################
# REFORMAT VIDEOS IF NOT CXD OR AVI
# this has only been tested under Linux

if(execute_analysis == TRUE){
  
  # if videos are TIFF stacks they need to be converted to avi before bemovi can analyse them
  # the TIFF stacks should be saved in "1_raw_tiff"
  # note: works only for 25 fps
  if(video.format == "tiff"){
    system("mkdir 1_raw")
    system(paste("~/bin/ImageJ/jre/bin/java -Xmx",memory.alloc,"m -jar ~/bin/ImageJ/ij.jar -batch tif_to_avi.ijm",sep=""))
  }
  
  # if videos are .mov videos they need to be converted to avi before bemovi can analyse them
  # the mov videos should be saved in "1_raw_mov"
  if(video.format == "mov"){
    system("mkdir 1_raw")
    # convert all files in the directory
    for (i in 1:length(list.files("1_raw_mov"))){
      system(paste("ffmpeg -i 1_raw_mov/",list.files("1_raw_mov")[i]," -f avi -vcodec mjpeg -t ",total_frames/fps," 1_raw/",gsub(".mov", '', list.files("1_raw_mov")[i], ignore.case = T),".avi",sep=""))
    }
  }
  
  if(video.format == "mp4"){
    system("mkdir 1_raw")
    # convert all files in the directory
    for (i in 1:length(list.files("1_raw_mp4"))){
      system(paste("ffmpeg -i \"1_raw_mp4/",list.files("1_raw_mp4")[i],"\" -f avi -vcodec rawvideo -pix_fmt gray8 -vf negate -t ",total_frames/fps," \"1_raw/",gsub(" ","_",gsub(".mp4", '', list.files("1_raw_mp4")[i], ignore.case = T),fixed=T),".avi\" ",sep=""))
    }
  }
  
  
  if(video.format == "wmv"){
    system("mkdir 1_raw")
    # convert all files in the directory
    for (i in 1:length(list.files("1_raw_wmv"))){
      system(paste("ffmpeg -i \"1_raw_wmv/",list.files("1_raw_wmv")[i],"\" -f avi -vcodec rawvideo -pix_fmt gray8 -vf negate -t ",total_frames/fps," \"1_raw/",gsub(" ","_",gsub(".wmv", '', list.files("1_raw_wmv")[i], ignore.case = T),fixed=T),".avi\" ",sep=""))
    }
  }
  
  # if analysis mode is "remote" the local copy of the videos in the original format can already be deleted to gain storage space
  
  if(data_location == "remote"){
    # check if all files have been reformatted
    if(length(list.files("1_raw")) == length(list.files(paste0("1_raw_",video.format)))){
      system(paste0("rm -r 1_raw_",video.format))
    }
  }
  
}
######################################################################
# TESTING

# check file format and naming
check_video_file_names(to.data,raw.video.folder, video.description.folder, video.description.file)

# check whether the thresholds make sense (set "dark backgroud" and "red")
#check_threshold_values(to.data, raw.video.folder, ijmacs.folder, 0, difference.lag, thresholds, IJ.path, memory.alloc)

######################################################################
# VIDEO ANALYSIS

if(execute_analysis == TRUE){
  # identify particles
  locate_and_measure_particles(to.data, raw.video.folder, particle.data.folder, difference.lag, thresholds, min_size = particle_min_size, max_size = particle_max_size, IJ.path, memory.alloc)
  
  # link the particles
  link_particles(to.data, particle.data.folder, trajectory.data.folder, linkrange = trajectory_link_range, disp = trajectory_displacement, start_vid = 1, memory = memory.alloc, memory_per_linkerProcess = memory.alloc.perLinker)
  
  # merge info from description file and data
  merge_data(to.data, particle.data.folder, trajectory.data.folder, video.description.folder, video.description.file, merged.data.folder)
  
  # load the merged data
  load(paste0(to.data, merged.data.folder, "Master.RData"))
  
  # filter data: minimum net displacement, their duration, the detection frequency and the median step length
  trajectory.data.filtered <- filter_data(trajectory.data, filter_min_net_disp, filter_min_duration, filter_detection_freq, filter_median_step_length)
  
  # summarize trajectory data to individual-based data
  morph_mvt <- summarize_trajectories(trajectory.data.filtered, calculate.median=F, write = T, to.data, merged.data.folder)
  #morph_mvt <- summarize_trajectories(trajectory.data, calculate.median=F, write = T, to.data, merged.data.folder)
  
  # get sample level info
  summarize_populations(trajectory.data.filtered, morph_mvt, write=T, to.data, merged.data.folder, video.description.folder, video.description.file, total_frames)
  #summarize_populations(trajectory.data, morph_mvt, write=T, to.data, merged.data.folder, video.description.folder, video.description.file, total_frames)
  
  # create overlays for validation
  create_overlays(trajectory.data.filtered, to.data, merged.data.folder, raw.video.folder, temp.overlay.folder, overlay.folder, image_resolution[1], image_resolution[2], difference.lag, type = "label", predict_spec = F, IJ.path, contrast.enhancement = 1, memory = memory.alloc)
  #create_overlays(trajectory.data, to.data, merged.data.folder, raw.video.folder, temp.overlay.folder, overlay.folder, image_resolution[1], image_resolution[2], difference.lag, type = "label", predict_spec = F, IJ.path, contrast.enhancement = 1, memory = memory.alloc)
  
  ########################################################################
  # some cleaning up
  system("rm -r 2_particle_data")
  system("rm -r 3_trajectory_data")
  system("rm -r 4a_temp_overlays")
  system("rm -r ijmacs")
  
  ########################################################################
  # copy data and analysis script to server if data location is remote
  if(data_location == "remote"){
    system(paste0("cp -r ", getwd(),"/",merged.data.folder, " ",project_path_server))
    
    # check that copying worked
    no_res_files_to_copy <- length(list.files(paste0(getwd(),"/",merged.data.folder), recursive = T))
    no_res_files_remote <- length(list.files(paste0(project_path_server,"/",merged.data.folder), recursive = T))
    
    if(no_res_files_remote != no_res_files_to_copy){
      execute_analysis <- FALSE
      print("COPY ERROR OF RESULTS TO SERVER: FILE NUMBERS INCORRECT")
    }
    
    system(paste0("cp ", getwd(),"/*.R", " ",project_path_server))
    
    # check that copying worked
    no_R_files_to_copy <- length(list.files(getwd(), pattern = ".R"))
    no_R_files_remote <- length(list.files(project_path_server, pattern = ".R"))
    
    if(no_R_files_to_copy != no_R_files_remote){
      execute_analysis <- FALSE
      print("COPY ERROR OF RESULTS TO SERVER: FILE NUMBERS INCORRECT")
    }
    
    if(execute_analysis == TRUE){
      # clean up locally (delete everything)
      system("rm -r 1_raw")
      system("rm -r 0_video_description")
      system("rm -r 5_merged_data")
    }
  }
  
  ########################################################################
  #final message
  if(execute_analysis == TRUE){
    print("Analysis done.")
    print("Please check overlays and delete afterwards.")
  }
}
########################################################################