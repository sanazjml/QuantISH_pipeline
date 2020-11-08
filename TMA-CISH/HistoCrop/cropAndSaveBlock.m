 function cropAndSaveBlock(bs) 
 save_loc = pwd; 
 destinationName = [save_loc, '/img/','img', int2str(bs.location(1)), '_', int2str(bs.location(2)), '.png']; 
 imwrite(bs.data, destinationName)  
 end
 
