#!/usr/bin/env anduril
//$OPT --wrapper slurm-prefix
//$OPT --threads 20



import anduril.builtin._, anduril.tools._
import org.anduril.runtime._

object Pipeline {
	// Working path
	val pwd = "/work/"

	// Find data  
	val root = "/work/whole_slide_images"
	val spot_image_list = Folder2Array( INPUT(path = root),
		filePattern = "^(.*)_DAPI_(.*)$", keyMode = "filename" )

	 // Access spot images
	 val spot_images = NamedMap[Port]("spot_images")
	 for ((name, spot_image) <- iterArray(spot_image_list))
	 	spot_images(name) = INPUT( path = spot_image.getPath() )

      

        // Crop WSI 
        val cropped_images = NamedMap[Port]("cropped_images")
	 for ((name, _) <- iterArray(spot_images)) {
	 	withName(name) {
	 	    // Run cropping
                     val cropped = BashEvaluate(array1 = Map("spot" -> spot_images(name)),
                                              command = s"""
                                             spot="$$(${pwd}/get-file-by-key.sh "$$(getinput array1)/_index" 'spot')"
                                              ${pwd}/crop.sh "$$spot" @arrayOut1@/crop1.png @arrayOut1@/crop2.png @arrayOut1@/crop3.png @arrayOut1@/crop4.png
                                              ${pwd}/update_anduril_index.py @arrayOut1@ crop*.png
                                               
                                             """)

                    
                     for ((key, file) <- iterArray(cropped.arrayOut1)) {
                       cropped_images(s"${name}_${key}") = INPUT( path = file.getPath() )
                     }
	            
                     
                     
                  }
               }

        // Filter DAPI
	val cropped_DAPI_images = NamedMap[Port]("cropped_DAPI_images")
	for ((name, _) <- iterArray(cropped_images))
		    if (name.matches("^(.*)_DAPI_(.*)$"))
			cropped_DAPI_images(name) = cropped_images(name)


          // Segmentation
         val segmented_spot_images = NamedMap[Port]("segmented_spot_images")
         for ((name, _) <- iterArray(cropped_DAPI_images)) {
		withName(name) {
		    // Run segmentation
		  val segmented = QuickBash(
                             in = Map("cropped" -> cropped_DAPI_images(name)),
                             command = s""" ${pwd}/segment.sh "$$cropped" "$$out" """)
                       	     segmented._filename("out", "out.png")
                             segmented._custom("memory") = "32768"
	    // Store output
	    segmented_spot_images(name) = segmented.out
		}
	}

 
     // Merge segmented images back 
	         
	val tiles_for = scala.collection.mutable.Map[String, Map[String, Port]]()

	for ((key, file) <- iterArray(segmented_spot_images)) {
		val parts = "^(.*)_(crop\\d+)_png$".r
		val parts(name, tile) = key
		tiles_for(name) = tiles_for.getOrElse( name, Map[String, Port]() ) ++ Map( tile -> segmented_spot_images(key) )
	}

	val segmented_merged = NamedMap[Port]("segmented_merged")
	for ((name, _) <- iterArray(spot_images)) {
		withName(name) {
			val merged = QuickBash(
       				in = tiles_for(name),
 	        		command = s"""					
 		        	crop1="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'crop1')"
                                      crop2="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'crop2')"
                                      crop3="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'crop3')"
                                      crop4="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'crop4')"  
 					 ${pwd}/merge.sh "$$crop1" "$$crop2" "$$crop3" "$$crop4" $$out
	 		""")
                        merged._filename("out", "out.png")

			// Store output
			segmented_merged(name) = merged.out
		}
	}          


  // Classification
 	val segment_classes = NamedMap[Port]("segment_classes")
 	for ((name, _) <- iterArray(spot_images)) {
 		withName(name) {
 			// Run classifier 
      			val classes = QuickBash(
       				in = Map("spot" -> spot_images(name), "merged" -> segmented_merged(name)),
 				command = s"""					
				        spot="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'spot')"
 					merged="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'merged')"
 					${pwd}/classify.sh "$$spot" "$$merged" $$out
 				""")
                        classes._custom("memory") = "81920"
                        classes._custom("cpu") = "3"
 			classes._filename("out", "out.csv")

 			// Store
			segment_classes(name) = classes.out
 		}
 	}         
  


   

        // Output quantification

	val segment_outputs = NamedMap[Port]("segment_outputs")
	for ((name, _) <- iterArray(segmented_merged)) {
		withName(name) {
                     val chan1_fn = spot_images(name).content.getPath().replaceAll("^(.*)_DAPI_(.*)$", "$1_Cy5 in use_$2")
                      val chan2_fn = spot_images(name).content.getPath().replaceAll("^(.*)_DAPI_(.*)$", "$1_FITC 38 HE_$2")
                       val chan3_fn = spot_images(name).content.getPath().replaceAll("^(.*)_DAPI_(.*)$", "$1_TRITC 43 HE_$2")
            
			// Run quantifier
			val output = QuickBash(
				in = Map("merged" -> segmented_merged(name), "chan1" -> INPUT(chan1_fn), "chan2" -> INPUT(chan2_fn), "chan3" ->  INPUT(chan3_fn),
					"classes" -> segment_classes(name)),
				command = s"""
					merged="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'merged')"
					classes="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'classes')"
                                        chan1="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'chan1')"
                                        chan2="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'chan2')"
                                        chan3="$$(${pwd}/get-file-by-key.sh "$$(getinput in)/_index" 'chan3')"
					${pwd}/quantify.sh "$$merged" "$$chan1" "$$chan2" "$$chan3" "$$classes" $$out
				""")
			output._filename("out", "out.csv")
                        output._custom("memory") = "71680"
                        output._custom("cpu") = "6"


                      //Store
			segment_outputs(name) = output.out
		}
	 }

  }  

 
      










