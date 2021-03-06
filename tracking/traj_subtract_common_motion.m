function new_vid_table = traj_subtract_common_motion(vid_table, traj_common)
% at each time point, average all beads x, y, and z values to determine
% center of mass vector and subtract that from each bead's position.
% This routine is insensitive to the disapperance of old trackers or the 
% sudden existence of new trackers that would otherwise cause sudden 
% jumps in the center-of-mass, so a polyfit of the center-of-mass should be
% used.

    video_tracking_constants;   

    
    id_list = unique(vid_table(:,ID));

  
%     new_vid_table = zeros(size(vid_table));
    new_vid_table = [];
    for k = 1:length(id_list); 
        q = vid_table(  vid_table(:,ID) == id_list(k) , :); 
        frameone = q(1,FRAME); 
        frameend = q(end,FRAME); 
        
        commonidx_one = find(traj_common.frame == frameone);
        commonidx_end = find(traj_common.frame == frameend);
        
        my_common_xy = traj_common.xy(commonidx_one:commonidx_end,:);
        c_offset = repmat(my_common_xy(1,:),size(my_common_xy,1),1);
        
        q_subtraj = q(:,X:Y);
        
        q_offset = repmat(q_subtraj(1,:),size(q_subtraj,1),1);
        
        q_subtraj = q_subtraj - q_offset;        
        c_subtraj = my_common_xy - c_offset;
        
        new_subtraj = q_subtraj - c_subtraj;
        
        subtracted_traj = q;
        subtracted_traj(:,X:Y) = new_subtraj + q_offset;
        
        new_vid_table = [new_vid_table ; subtracted_traj];
    end;

    return;