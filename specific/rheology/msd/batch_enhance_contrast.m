% 3DFM functions
% rheology
% batch_enhance_contrast DBH
%
% this funtion is a wrapper to call multiple *.raw files that are too "dim"
% to allow easy recong. of single fluorescent beads and preform a linear
% gain function between the 0 and the maximum pixel value seen in the image
% stream, remapping the maximum to 255
% 
%
% created 5-17-2004


clear all
close all

% set list of file names
fu = dir('*.raw');

num_files = size(fu);

for n = 1:num_files
    rawin = fu(n).name;
    rawout = strcat(rawin,'en.raw');
    
    enhance_contrast(rawin, rawout);
    
end