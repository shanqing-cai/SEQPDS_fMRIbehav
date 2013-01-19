SEQPDS_fMRIbehav
================

Data analysis scripts and programs for the SEQPDS study

The main script to run is now pilotAnalysis2.m. It is created from pilotAnalysis_fMRI_SEQPDS_011413.m.

Usage example: 
pilotAnalysis2('fmrih', 4, 'SEQ03018_fMRI', 'test1', 1.5, 'test1_res')

The second last input argument is newly added. It is the trial length in s.

pilotAnalysis2('fmrih', 4, 'SEQ03018_fMRI', 'test1', 1.5, 'test1_res', 'noFilter')
# The 'noFilter' option allows the user to listen to the original sound, instead of the Wiener-filtered sound.

# (01/18/2013)
pilotAnalysis2('fmrih', 4, 'SEQ03018_fMRI', 'test1', 1.5, 'test1_res', 'noFilter', 'wavplay')
# The 'wavplay' option lets the program use wavplay, instead of the default 'soundsc', as the sound-playing function.

pilotAnalysis2('fmrih', 4, 'SEQ03018_fMRI', 'test1', 1.5, 'test1_res', 'noFilter', 'audioplayer')
# Similar to above, the 'audioplayer' option selects the audioplayer as the default sound-playing function.

