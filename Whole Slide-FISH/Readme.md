## QuantISH: RNA in situ hybridization image analysis pipeline (Whole slide images)

This repository contains the image analysis pipeline introduced in paper “RNA in situ hybridization image analysis reveals target RNA quantification and survival associated expression variability in high grade serous ovarian cancer”. 

QuantISH is a comprehensive image analysis pipeline for RNA in situ hybridization images which quantifies target RNAs in individual cells and patients. The pipeline is capable of analyzing Tissue Microarray (TMA) and Whole Slide images either with chromogenic or immunofluorescence signals efficiently. 


Software requirements: 
Matlab
Python
CaseViewer
CellProfiler software (version 3.1.8)
Anduril2 

Getting Started 
Make sure that the required softwared are installed on your computer. Besides, as the pipline exploits the parallelisation in Anduril2 as a workflow platform for analyzing large data sets, you can install the Anduril on your own computer using instructions available in “https://www.anduril.org”. 

Pre-processing
-Caseviewer
We have used CaseViewer software to read the MRXS immunoflorescence image, and separate its different channels as DAPI staining, and fluorescein (FITC 38 HE), Cyanine 3 (TRITC 48 HE), and Cyanine 5 (Cy5) channels for each target RNA to be quantified. The output will be saved as tiff format images. 


Main analysis

-pipeline.scala

This scala scripts contains the main body of the QuantISH pipeline. It receives the DAPI statining and three separated channles of whole slide image as inputs, and implements other downstream steps as follows:

1. Crop DAPI image into four smaller tiles. As whole slide images are too big to be input of Cellprofiler segmentation, we implement a MATLAB script in Anduril pipeline to crop the DAPI staining into four. (crop.sh, crop_wsi.m, crop_run.m functions are being called in this step)


2. Cell segmentation . The pipeline calls CellProfiler software and the saved segment.cpproj in which the non-default parameters for the images in analysis were determined experimentally. (segment.cpproj and segment.sh are called in this step)

3. Merge segmented images back. Using a MATLAB script called in Anduril, the segmented images are being merged back together for downsctream analysis (merge.sh, merge_run.m and merge_wsi.m are called in this step)

4. Cell type classification. Anduril pipeline uses quadratic classifier for DAPI staining cell type classification. We trained a supervised quadratic classifier using 402 cells with the area, mean nucleus stain intensity and the eccentricity of each segmented object and desired cell types. (classify.m, classify_run.m, classify.sh, convfft.m, rgb2label.m are called in this step, ‘training_data.mat’ contains the training data needed in classification) 

5. RNA signals quantification.  Cross-channel fluorescence bleed of Cy5, FITC and TRITC staining was reduced by finding a suitable basis near for the intensity data of all pixels near the principal axes using power iteration. This procedure is being done through running ‘princompgen.m’ in quantification step. Next, the fluorescence intensity signal was quantified using the negative response of a Laplacian of Gaussian filter with standard deviation of unity (quantify_run.m, quantify.sh and quantify.m functions are called in this step). Eventually, the quantification results in each indivdual cell of each TMA will be saved as a csv file. These files contain the segment Id, class type, SumIntensity of 3 channles including (Cy5, FITC and TRITC) and area of cell as well to do any normalization of interest.










