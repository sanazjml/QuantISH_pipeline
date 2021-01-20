## QuantISH: RNA in situ hybridization image analysis pipeline (TMA)
This repository contains the image analysis pipeline introduced in paper “QuantISH: RNA in situ hybridization image analysis pipeline to quantify cell type-specific target RNA expression and variability in tissue samples”.  

Here is the TMA-CISH version of pipeline which quantifies cell type-specific target RNA in chromogenic tissue microarray images. 


### Software requirements: 
Matlab  
Python    
CellProfiler software (version 3.1.8)  
ImageJ software  
GNU Image Manipulation Program (Gimp) software (version 2.8)  
Anduril2     

### Getting Started 
Make sure that the required softwared are installed on your computer. Besides, as the main pipline exploits the parallelisation in Anduril2 as a workflow platform for analyzing large data sets, you can install the Anduril on your own computer using instructions available in “https://www.anduril.org”. 

## Pre-processing
#### - mrxsdump.py
As the TMA scans in this paper were received in MIRAX (MRXS) format files containing a hierarchical pyramid of the scanned images and metadata, this python script extracts contiguous images from the tiled microscope scans. Downsampled full slide images was used for cropping TMAs in next step of pre-processing and extracts from the full resolution layer for actual analysis. Meanwhile, overlapping area caused by the slide scanner tiling is eliminated by extraction process. Here, in order to have a small size image analysis, we have extracted 1 TMA MRXS file from the whole slide TMA MRXS file as input "CCNE1_TMA.mrxs". So, first you need to get the size of all resolution layers from your MRXS image using (please extract the compressed file CCNE1_TMA.zip before any kind of analysis):  
 
 ```
 ./mrxsdump.py  -l CCNE1_TMA.mrxs 
 ```

which prints the list of all images from high to low resolution, and you can easily get the size of smallest and biggest ones for downstream analysis.   
``` 
HIER_0_VAL_0 with 1,760 tiles, 170496x410624 pixels (jpg)..
HIER_0_VAL_1 with 460 tiles, 85248x205312 pixels (jpg)..
HIER_0_VAL_2 with 120 tiles, 42624x102656 pixels (jpg)..
HIER_0_VAL_3 with 30 tiles, 21312x51328 pixels (jpg)..
HIER_0_VAL_4 with 12 tiles, 10656x25664 pixels (jpg)..
HIER_0_VAL_5 with 4 tiles, 5328x12832 pixels (jpg)..
HIER_0_VAL_6 with 2 tiles, 2664x6416 pixels (jpg)..
HIER_0_VAL_7 with 2 tiles, 1332x3208 pixels (jpg)..
HIER_0_VAL_8 with 1 tiles, 666x1604 pixels (jpg)..
HIER_0_VAL_9 with 1 tiles, 333x802 pixels (jpg)..
HIER_1_VAL_0 with 1,760 tiles (dat)..
HIER_1_VAL_1 with 460 tiles, 256x256 pixels (png)..
HIER_2_VAL_0 with 120 tiles, 256x256 pixels (png)..
HIER_2_VAL_1 with 30 tiles, 256x256 pixels (png)..
HIER_2_VAL_2 with 12 tiles, 256x256 pixels (png)..
HIER_3_VAL_0 with 4 tiles, 256x256 pixels (png)..
NONHIER_0_VAL_0 with 1 tiles (dat)..
NONHIER_1_VAL_0 with 1 tiles, 88x212 pixels (bmp)..
NONHIER_1_VAL_1 with 1 tiles (xml)..
NONHIER_1_VAL_2 with 1 tiles, 1400x3373 pixels (jpg)..
NONHIER_1_VAL_3 with 1 tiles, 1776x1301 pixels (jpg)..
NONHIER_1_VAL_4 with 1 tiles, 666x1604 pixels (jpg)..
NONHIER_1_VAL_5 with 1 tiles, 88x212 pixels (bmp)..
NONHIER_1_VAL_7 with 1 tiles (dat)..
NONHIER_1_VAL_8 with 1 tiles (dat)..
NONHIER_2_VAL_0 with 1 tiles (dat)..
NONHIER_3_VAL_0 with 1 tiles (dat)..
NONHIER_4_VAL_0 with 2 tiles (xml)..
NONHIER_5_VAL_0 with 1 tiles (xml)..
NONHIER_5_VAL_1 with 3 tiles (dat)..

```


Consequnetly, to extract the low resolution image for next step of analysis you just need to run the following code. Here, we extract the HIER_0_VAL_8 layer via: 

```
./mrxsdump.py  -g "HIER_0_VAL_8"  -O CCNE1_TMA_lr.png -P  CCNE1_TMA.mrxs
```

in which -g specifies the resolution layer, -O specifies output image name, and -P shows the process. Hence, one will see this message:  

```
warning: output directory . exists and is not empty
warning: NONHIER_5_VAL_1 tile (0,) already exists, ignoring furher data
warning: NONHIER_5_VAL_1 tile (1,) already exists, ignoring furher data
warning: NONHIER_5_VAL_1 tile (2,) already exists, ignoring furher data
warning: NONHIER_5_VAL_1 tile (0,) already exists, ignoring furher data
warning: NONHIER_5_VAL_1 tile (1,) already exists, ignoring furher data
warning: NONHIER_5_VAL_1 tile (2,) already exists, ignoring furher data
warning: NONHIER_5_VAL_1 tile (0,) already exists, ignoring furher data
warning: NONHIER_5_VAL_1 tile (1,) already exists, ignoring furher data
warning: NONHIER_5_VAL_1 tile (2,) already exists, ignoring furher data
HIER_0_VAL_8 with 1 tiles..

```

and also "CCNE1_TMA_lr.png" image is the low resolution one saved for downstream analysis. 


#### - cropTMA.m
In order to extract the TMA spots from the whole slide image, we implemented a MATLAB script based on the HistoCrop method [https://github.com/jopo666/HistoCrop]. Please refer to Histocrop github page for full documentation. The expected number of rows and columns in the TMA spot matrix is first prespecified in the code. Afterwards, the program will segment each TMA spot in the matrix. A graphical user interface allows adding, removing, or editing any spots that are not correctly detected. Finally, the script exports the bounding box coordinates of each TMA spot as a csv file, which is used to crop each TMA spot into a separate image file for downstream analyses. You should just change the "th" and "tw" in the Matlab script based on height and width of high resolution image. There are other MATLAB function in the HistoCrop folder as dependencies of cropTMA.m function. 

#### - crop_spots_all.sh

This bash script cuts the spots of a TMA slide using the coordinates obtained in previous script. Make sure the directory in which the csv files are present, are truly referred in crop_spots_all.sh script. 

As here we have just one TMA in the slide, we would have one cropped TMA coordinates as the output. Here is a snapshot of output spot (note that this is not image file for downstream analysis. We will continue with a portion of cropped TMA spot for downstream analysis):


 ![alt text](https://github.com/sanazjml/QuantISH_pipeline/blob/main/TMA-CISH/CCNE1_TMA_HIER_0_VAL_0.png)    



#### - macro.txt (ImageJ)

This script is written in ImageJ macro language and implements a color separation stage to separate the brown marker RNA stain from the blue nucleus stain in each TMA spot (for method details refer to manuscript). To run color separation, you just need to open Process → Batch → macro in ImageJ software and copy the macro.txt content in the blank space. The input directory should be the one in which you have saved the cropped TMA spots. Here is the snapshot of imagej software and the macro which has copied to the proper box:



 ![alt text](https://github.com/sanazjml/QuantISH_pipeline/blob/main/TMA-CISH/imagej.png)  


Hence, here is the output of imagej color deconvolution for the spot of interest:

 ![alt text](https://github.com/sanazjml/QuantISH_pipeline/blob/main/TMA-CISH/CCNE1_TMA_HIER_0_VAL_0_color_channel.png)



## Main analysis

### pipeline.scala


This scala scripts contains the main body of the QuantISH pipeline. It receives the cropped TMA spots and separated brown color channel as inputs, and after implementing following steps, it quantifies cell type-specific target RNA inside each tissue sample. These are the steps implemented directly in pipeline.scala:

1. Make a mask of deconvoluted brown channel. There is a MATLAB script called directly in Anduril pipeline to make a mask of deconvoluted channel for quantification step. (mask.sh, mask_fun.m, mask_run.m functions are being called in this step)

2. Cleaning demultiplexing artifacts. This step applies cleaning demultiplexing artifacts automatically from the original TMA using the resynthesizer textural synthesis plug-in in GNU Image Manipulation Program. The steps are written in “inpainting.py” in python-fu scripting language, which allows fully automatic batch processing for each TMA spot in the analysis. 


3. Cell segmentation . The pipeline calls CellProfiler software and the saved segment.cpproj in which the non-default parameters for the images in analysis were determined experimentally. (segment.cpproj and segment.sh are called in this step)

4. Cell type classification. Anduril pipeline uses quadratic classifier for cell type classification. We trained a supervised quadratic classifier using 360 cells with the area, the mean nucleus stain intensity, the eccentricity, and the perimeter-to-area ratio of each segmented object and desired cell types. For decsription about classification approach refer to the manuscript. (classify.m, classify_run.m, classify.sh, convfft.m, rgb2label.m are called in this step, 'training_image.mat' is the training data needed for classification) 

5. RNA signals quantification. Eventually, the RNA signals are quantified using the isolated channel for each individual TMA in color separation step. (quantify_run.m, quantify.sh and quantify.m functions are called in this step). The quantification results in each indivdual cell of each TMA will be saved as a csv file. This files contains the segment Id, class type, SumIntensity and Area of cell in order to do any normalization of interest.

### Downstream analysis  

- Otsu thresholding has been done for two class classification of positive control intensities to filter out unreliable spots. (use Otsu.R  script)    
- Average expression and expression variability can be quantified using Downstream_CISH.R script. Actually the csv outputs of the pipeline.scala contains all information needed for quantification. However, files should be aggeragated and mapped to the patients' annotation resulting in a single file containing the spot IDs and patients names as well (like a table named CCNE1 in script). Then Downstream_CISH.R script can be used to quantify average expression and expression variability for each individual spot and patient directly.  
- Applying ANOVA on nested factorial linear models to perform variance analysis has been done via lmnf.R. 






