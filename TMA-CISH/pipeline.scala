#!/usr/bin/env anduril
//$OPT --wrapper slurm-prefix
//$OPT --threads 20

import anduril.builtin._, anduril.tools._
import org.anduril.runtime._

object Pipeline {
	// Working path
	val pwd = "/work/"  //The directory of cropped TMA Input images 

	// Find data  
	val root = "/work/TMA_images/"
	val spot_image_list = Folder2Array( INPUT(path = root),
		filePattern = "^(.*)\\.png$", keyMode = "filename" )

	// Access spot images
	val spot_images = NamedMap[Port]("spot_images")
	for ((name, spot_image) <- iterArray(spot_image_list))
		spot_images(name) = INPUT( path = spot_image.getPath() )

        // Find brown deconvoluted channel
        val  rooT = "/color_deconvoluted_images"  //The directory of deconvoluted images from ImageJ color separation
        val channel_image_list = Folder2Array( INPUT(path = rooT),
		filePattern = "^(.*)\\.png$", keyMode = "filename" )
        
        // Access brown channel images
        val channel_images = NamedMap[Port]("channel_images")
        for ((name, channel_image) <- iterArray(channel_image_list))
                channel_images(name) = INPUT( path = channel_image.getPath() )

               
        // Make mask of original image using brown separated channel
         val mask_images = NamedMap[Port]("mask_images")
         for ((name, _) <- iterArray(channel_images)) {
              withName(name) {
                     // Run mask creation
                  val mask = QuickBash(
                       in = Map("spot" -> spot_images(name), "channel" -> channel_images(name)),
                       command = s"""                                  
                              spot="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'spot')"
                                      channel="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'channel')"
                                      ${pwd}/mask.sh "$$spot" "$$channel" $$out
                              """)
                      mask._filename("out", "out.png")

                        // Store
                      mask_images(name) = mask.out
                   }
       }
      
        //GIMP implementation to fill holes
        val filled_images = NamedMap[Port]("filled_images")
        for ((name, _) <- iterArray(spot_images)){
         withName(name) {
                // Run gimp filling
             val filled = QuickBash(
                 in = Map("spot" -> spot_images(name), "mask" -> mask_images(name)),
                 command =s""" 
                         gimp -i -b '(python-fu-inpainting RUN-NONINTERACTIVE "'"$$spot"'" "'"$$mask"'" "'"$$out"'")' -b '(gimp-quit 0)'
        
                       """)
                   filled._filename("out", "out.png")
                   filled._custom("memory") = "10240"
                   
               //store
             filled_images(name) = filled.out
    
           }
        
        }


	// Cell Segmentation
        val segmented_spot_images = NamedMap[Port]("segmented_spot_images")
	for ((name, _) <- iterArray(filled_images)) {
		withName(name) {
		    // Run segmentation
		  val segmented = QuickBash(
                in = Map("filled" -> filled_images(name)), 
			  command = s""" ${pwd}/segment.sh "$$filled" "$$out" """)
		segmented._filename("out", "out.png")
                segmented._custom("memory") = "32768"
	    // Store output
	    segmented_spot_images(name) = segmented.out
		}
	}

	// Cell Classification
	val segment_classes = NamedMap[Port]("segment_classes")
	for ((name, _) <- iterArray(filled_images)) {
		withName(name) {
			// Run classifier 
                         val classes = QuickBash(
   				in = Map("filled" -> filled_images(name), "segmented" -> segmented_spot_images(name)),
				command = s"""					
				filled="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'filled')"
					segmented="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'segmented')"
					${pwd}/classify.sh "$$filled" "$$segmented" "$$out"
				""")
			classes._filename("out", "out.csv")

			// Store
			segment_classes(name) = classes.out
                }
	}

	// Output quantification
	val segment_outputs = NamedMap[Port]("segment_outputs")
	for ((name, _) <- iterArray(filled_images)) {
		withName(name) {
			// Run quantifier
			val output = QuickBash(
				in = Map("spot" -> spot_images(name), "channel" -> channel_images(name), "segmented" -> segmented_spot_images(name),
					"classes" -> segment_classes(name)),
				command = s"""
                                        spot="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'spot')"
					channel="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'channel')"
					segmented="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'segmented')"
					classes="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'classes')"
					${pwd}/quantify.sh "$$spot" "$$channel" "$$segmented" "$$classes" $$out
				""")
			output._filename("out", "out.csv")

                      //Store
			segment_outputs(name) = output.out
		}
	}
}
