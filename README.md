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

(01/22/2013)
# Added a new option 'redo' to allow the user redo a specific trial after a first pass run, in case a mistake is made during that trial during the first pass.

Usage example:
pilotAnalysis2('fmrig', 3, 'SEQ03C01_behavioral', 'test7', 3, 'scai', 'noFilter', 'redo', 17)

# This redoes only trial #17.