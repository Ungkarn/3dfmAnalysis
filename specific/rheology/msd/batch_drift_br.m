% 3DFM function  
% Rheology 
% last modified 05/11/04 -- commits added 
% batch_drift_br DBH
% 
% This function calls all the nessicary function to take all *.mat files in a
% folder that have been generated by Video Spot Tracker and converted from
% vrpn to Matlab and in the end generates 1 file will all the mean squared
% displacement curves for tracked beads. This version is to be used to
% elliminate drift for beads collected under bright field microscopy on
% Hercules, using the Pulnix camera and the 1.5x optovar
%  
% The program calls subroutines that output:
%
% -- 1 position vs time file per *.mat files inputted (without drift
%    correction). Note each file can contain tracks of several beads
%
% -- 1 drift corrected position vs. time file per *.mat file
%
% -- 1 mean squared displacement vs. tau file per drift corrected data 
%   
% -- 1 mean squared displacement vs. tau for all beads tracker withing the folder 
%  
% Notes:  To effectively use this program, it is necessary arrange *.mat
%   files into folders were 1 bead size / sample type per folder.
%
%   THIS PROGRAM IS ONLY TO BE USED WITH THE PULNIX CAMERA AND THE
%   1.5X OPTOVAR
%    
%   
%  5/04 - created by DBH
%  



% clear all allocated variables and close all plot windows
clear all
close all

% call batch_load_video_tracking_br to convert data from *.mat file to
% position vs. time files (*.dat) -- see help batch_load_video_tracking_br
batch_load_video_tracking_br

qt = 1
% call drift_buster multi which subtracts a least squares linear fit from
% each position coord. to eliminate drfit from data sets. Saves file
% *no_dirft.dat -- see helpdrift_buster_multi
drift_buster_multi

qt =2
% calls batch_msd_2d_d which calculates the mean squared displacement
% curves for all beads in the drift corrected *no_drift.dat file and saves
% them to *.txt files (1 per *.no_drift.dat file)
batch_msd_2d_d

% calls data_merge which complies all the msd files into one
data_merge