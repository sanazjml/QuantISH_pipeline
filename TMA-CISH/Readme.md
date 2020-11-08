## QuantISH: RNA in situ hybridization image analysis pipeline (TMA)

This repository contains the image analysis pipeline introduced in paper “RNA in situ hybridization image analysis reveals target RNA quantification and survival associated expression variability in high grade serous ovarian cancer”. 

QuantISH is a comprehensive image analysis pipeline for RNA in situ hybridization images which quantifies target RNAs in individual cells and patients. The pipeline is capable of analyzing Tissue Microarray (TMA) and Whole Slide images either with chromogenic or immunofluorescence signals efficiently. 


Software requirements: 
Matlab
Python
CellProfiler software (version 3.1.8)
ImageJ software
GNU Image Manipulation Program (Gimp) software (version 2.8)
Anduril2 

Getting Started 
Make sure that the required softwared are installed on your computer. Besides, as the main pipline exploits the parallelisation in Anduril2 as a workflow platform for analyzing large data sets, you can install the Anduril on your own computer using instructions available in “https://www.anduril.org”. 

Pre-processing
1. mrxsdump.py
 As the TMA scans in this paper were received in MIRAX (MRXS) format files containing a hierarchical pyramid of the scanned images and metadata, this python script extracts contiguous images from the tiled microscope scans. Downsampled full slide images was used for cropping TMAs in next step of pre-processing and extracts from the full resolution layer for actual analysis. Meanwhile, overlapping area caused by the slide scanner tiling is eliminated by extraction process. So then, you need first to get the size of all resolution layers from your MRXS image using:
./mrxsdump.py  -l “TMA.png” 
which prints the list of all images from high to low resolution, and you can easily get the size of smallest and biggest ones for downstream analysis. Consequnetly, to extract the low resolution image for next step of analysis you just need to run
./mrxsdump.py  -g “'HIER_0_VAL_8'”  -O thumb.png -r -P  “TMA.png”
in which -g specifies the resolution layer, -O specifies output image name, -r corrects the tiling problem (if is available) and -P shows the process. 


2. cropTMA.m
In order to extract the TMA spots from the whole slide image, we implemented a MATLAB script based on the HistoCrop method [refrence to Valeria github page]. The expected number of rows and columns in the TMA spot matrix is first prespecified in the code. Afterwards, the program will segment each TMA spot in the matrix. A graphical user interface allows adding, removing, or editing any spots that are not correctly detected. Finally, the script exports the bounding box coordinates of each TMA spot as a csv file, which is used to crop each TMA spot into a separate image file for downstream analyses. You should just change the “th” and “tw” in the Matlab script based on height and width of high resolution image. There are other MATLAB function in the HistoCrop folder as dependencies of cropTMA.m function. 


3. crop_spots_all.sh

This bash script cuts the spots of a TMA slide using the coordinates obtained in previous script. Make sure the directory in which the csv files are presnet, are truly referred in crop_spots_all.sh script. 


4. macro.txt (ImageJ)

This script is written in ImageJ macro language and implements a color separation stage to separate the brown marker RNA stain from the blue nucleus stain in each TMA spot (for method details refer to manuscript). To run color separation, you just need to open Process → Batch → macro in ImageJ software and copy the macro.txt content in the blank space. The input directory should be the one in which you have saved the cropped TMA spots.  



Main analysis

- pipeline.scala


This scala scripts contains the main body of the RISMAN pipeline. It receives the cropped TMA spots and separated color channels as inputs, and after implementing several steps, it quantifies target RNA inside each cells of each tissue sample. These are the steps implemented directly in pipeline.scala:

1. Make a mask of deconvoluted brown channel. There is a MATLAB script called directly in Anduril pipeline to make a mask of deconvoluted channel for quantification step. (mask.sh, mask_fun.m, mask_run.m functions are being called in this step)

2.Cleaning demultiplexing artifacts. This step applies cleaning demultiplexing artifacts automatically from the original TMA using the resynthesizer textural synthesis plug-in in GNU Image Manipulation Program. The steps are written in “inpainting.py” in python-fu scripting language, which allows fully automatic batch processing for each TMA spot in the analysis. 


3. Cell segmentation . The pipeline calls CellProfiler software and the saved segment.cpproj in which the non-default parameters for the images in analysis were determined experimentally. (segment.cpproj and segment.sh are called in this step)

4. Cell type classification. Anduril pipeline uses quadratic classifier for cell type classification. We trained a supervised quadratic classifier using 360 cells with the area, the mean nucleus stain intensity, the eccentricity, and the perimeter-to-area ratio of each segmented object and desired cell types. For decsription about classification approach refer to manuscript. (classify.m, classify_run.m, classify.sh, convfft.m, rgb2label.m are called in this step, ‘training_image.mat is the training data needed for classification) 

5. RNA signals quantification. Eventually, the RNA signals are quantified using the isolated channel for each individual TMA in color separation step. (quantify_run.m, quantify.sh and quantify.m functions are called in this step). The quantification results in each indivdual cell of each TMA will be saved as a csv file. This files contains the segment Id, class type, SumIntensity and Area of cell in order to do any normalization of interest.







