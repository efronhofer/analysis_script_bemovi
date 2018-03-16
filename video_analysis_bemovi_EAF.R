######################################################################
# R script for analysing video files with BEMOVI (www.bemovi.info)
#
# Emanuel A. Fronhofer
#
# March 2018
######################################################################
rm(list=ls())

# load package
#library(devtools)
#install_github("efronhofer/bemovi", ref="experimental")
library(bemovi)

######################################################################
# VIDEO PARAMETERS

# video frame rate (in frames per second)
fps <- 15
# length of video (in frames)
total_frames <- 150

# magnification
# this parameter sets "measured_volume" and "pixel_to_scale" for Perfex Pro 10 stereomicrocope with Perfex SC38800 (IDS UI-3880LE-M-GL) camera and sample height = 0.5mm
# if other devices are used, set the two paramneters manually
# possible values: 0.8, 1, 2, 3
magnification <- 1

# specify video file format (one of "avi","cxd","mov","tiff")
# bemovi only works with avi and cxd. other formats are reformated to avi below
video.format <- "avi"

# setup
difference.lag <- 10
thresholds <- c(50,255) # don't change the second value

# RAM allocation (in MB)
memory.alloc <- c(60000)
# RAM per particle linker instance (in MB)
memory.alloc.perLinker <- c(8000)

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
trajectory_displacement <- 16

# these values are in the units defined by the parameters above: fps (seconds), measured_volume (microliters) and pixel_to_scale (micometers)
filter_min_net_disp <- 25
filter_min_duration <- 1
filter_detection_freq <- 0.1
filter_median_step_length <- 3

######################################################################
# MORE PARAMETERS (USUALLY NOT CHANGED)

# UNIX
# set paths to ImageJ and particle linker standalone
IJ.path <- "/home/emanuel/bin/ImageJ"
to.particlelinker <- "/home/emanuel/bin/ParticleLinker"

# WINDOWS
# set paths to ImageJ, particle linker standalone and java
# note: paths should not be too long (less than 250 characters incl. folder and file names)
#IJ.path <- "C:/ImageJ/ImageJ.exe"
#to.particlelinker <- "C:/"
#java.path <- "C:/java/bin/javaw.exe"

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

######################################################################
# SET MEASURED VOLUME AND PIXELS TO SCALE BASED ON MAGNIFICATION

if(!is.element(magnification, c(0.8,1,2,3))){
  print("Magnification unknown! Please modify")
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
  }
  if(magnification==2){
    # measured volume (in microliter)
    measured_volume <- 31
    # size of a pixel (in micrometer)
    pixel_to_scale <- 3.11
  }
  if(magnification==3){
    # measured volume (in microliter)
    measured_volume <- 13.73
    # size of a pixel (in micrometer)
    pixel_to_scale <- 2.07
  }
}

# measured volume (in microliter)
#measured_volume <- 34.4 # for Leica M205 C with 1.6 fold magnification, sample height 0.5 mm and Hamamatsu Orca Flash 4
#measured_volume <- 14.9 # for Nikon SMZ1500 with 2 fold magnification, sample height 0.5 mm and Canon 5D Mark III

# size of a pixel (in micrometer)
#pixel_to_scale <- 4.05 # for Leica M205 C with 1.6 fold magnification, sample height 0.5 mm and Hamamatsu Orca Flash 4
#pixel_to_scale <- 3.79 # for Nikon SMZ1500 with 2 fold magnification, sample height 0.5 mm and Canon 5D Mark III

######################################################################
# REFORMAT VIDEOS IF NOT CXD OR AVI
# this has only been tested under Linux

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
    # in older distros use ffmpeg with the same syntax
    system(paste("avconv -i 1_raw_mov/",list.files("1_raw_mov")[i]," -f avi -vcodec mjpeg -t ",total_frames/fps," 1_raw/",gsub(".mov", '', list.files("1_raw_mov")[i], ignore.case = T),".avi",sep=""))
  }
}

######################################################################
# TESTING

# check file format and naming
#check_video_file_names(to.data,raw.video.folder,video.description.folder,video.description.file)

# check whether the thresholds make sense (set "dark backgroud" and "red")
#check_threshold_values(to.data, raw.video.folder, ijmacs.folder, 0, difference.lag, thresholds, IJ.path, memory.alloc)

######################################################################
# VIDEO ANALYSIS

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

# get sample level info
summarize_populations(trajectory.data.filtered, morph_mvt, write=T, to.data, merged.data.folder, video.description.folder, video.description.file, total_frames)

# create overlays for validation
create_overlays(trajectory.data.filtered, to.data, merged.data.folder, raw.video.folder, temp.overlay.folder, overlay.folder, 3088, 2076, difference.lag, type = "label", predict_spec = F, IJ.path, contrast.enhancement = 1, memory = memory.alloc)

########################################################################
# some cleaning up
#system("rm -r 2_particle_data")
#system("rm -r 3_trajectory_data")
system("rm -r 4a_temp_overlays")
system("rm -r ijmacs")
########################################################################