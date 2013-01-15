SEQPDS_fMRIbehav
================

Data analysis scripts and programs for the SEQPDS study

The main script to run is now pilotAnalysis2.m. It is created from pilotAnalysis_fMRI_SEQPDS_011413.m.

Usage example: 
pilotAnalysis2('fmrih', 4, 'SEQ03018_fMRI', 'test1', 1.5, 'test1_res')

pilotAnalysis2('fmrih', 4, 'SEQ03018_fMRI', 'test1', 1.5, 'test1_res', 'noFilter')

# The 'noFilter' option allows the user to listen to the original sound, instead of the Wiener-filtered sound.

The second last input argument is newly added. It is the trial length in s.