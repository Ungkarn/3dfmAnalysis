function outs=get_frames(filepath)

file_name=filepath;
info=imfinfo(file_name);
num_images=numel(info);
for k=1:num_images
   frame{k}=imread(file_name,k);
 
end


    
    