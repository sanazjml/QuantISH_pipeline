#!/usr/bin/env python

from gimpfu import * 

import os.path

def inpainting(timg, tdrawable, outputFile):
     img = pdb.gimp_file_load(timg, '')
     mask_list = tdrawable
     layer = pdb.gimp_file_load_layer(img, mask_list)
     pdb.gimp_image_insert_layer(img, layer, None, 0)
    # Turn off everything but the blue channel
     blue = pdb.gimp_channel_new_from_component(img, BLUE_CHANNEL, 'blue')
     img.add_channel(blue)
     active_channel = pdb.gimp_image_get_active_channel(img)
     # Channel to selection
     selected_image = pdb.gimp_image_select_item(img, 2, active_channel)
     drawable = img.layers[1]     
     pdb.gimp_edit_cut(drawable)
     #heal_transparency
     samplingRadiusParam=50
     orderParam=2
     pdb.python_fu_heal_transparency(img, drawable, 50, 2)
     #save output
     pdb.gimp_file_save(img, drawable, outputFile, os.path.basename(outputFile))
     pdb.gimp_image_delete(img)


args = [   
     (PF_STRING, "timg", "Path for input file", ""),
     (PF_STRING, "tdrawable", "Path for input layer", ""),
     (PF_STRING, "outputFile", "Path for output filename", "")
    ]

register('python-fu-inpainting', '', '', '', '', '', '', '', args, [], inpainting )
 

main()
   
    
    


     
     







    


    
    
    




