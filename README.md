SEQPDS_fMRIbehav
================

Data analysis scripts and programs for the SEQPDS study

The main script to run is now pilotAnalysis2.m. It is created from pilotAnalysis_fMRI_SEQPDS_011413.m.

Usage example: 
pilotAnalysis2('fmrih', 4, 'SEQ03018_fMRI', 'test1', 1.5, 'test1_res')

The second last input argument is newly added. It is the trial length in s.

pilotAnalysis2('fmrih', 4, 'SEQ03018_fMRI', 'test1', 1.5, 'test1_res', 'noFilter')

=== The 'noFilter' option allows the user to listen to the original sound, instead of the Wiener-filtered sound.

=== (01/18/2013)
pilotAnalysis2('fmrih', 4, 'SEQ03018_fMRI', 'test1', 1.5, 'test1_res', 'noFilter', 'wavplay')
=== The 'wavplay' option lets the program use wavplay, instead of the default 'soundsc', as the sound-playing function.

pilotAnalysis2('fmrih', 4, 'SEQ03018_fMRI', 'test1', 1.5, 'test1_res', 'noFilter', 'audioplayer')
=== Similar to above, the 'audioplayer' option selects the audioplayer as the default sound-playing function.

(01/22/2013)
=== Added a new option 'redo' to allow the user redo a specific trial after a first pass run, in case a mistake is made during that trial during the first pass.

Usage example:
pilotAnalysis2('fmrig', 3, 'SEQ03C01_behavioral', 'test7', 3, 'scai', 'noFilter', 'redo', 17)

=== This redoes only trial #17.

(04/25/2013)

=== Added a new option 'redoCatOnly' that functions like 'redo', but skips the onset/offset labeling part, i.e., lets the user change only the categorical rating (accuracy and fluency)
Usage example: 

pilotAnalysis2('fmrih', 3, 'SEQ03C07_behavioral', 'test8', 3, 'scai', 'noFilter', 'redoCatOnly', [1, 18, 22, 27, 2])
(Don't forget to change scai to your own username) 

To do this over all trials of a run, assuming that there are 40 trials in total, do:

pilotAnalysis2('fmrih', 3, 'SEQ03C07_behavioral', 'test8', 3, 'scai', 'noFilter', 'redoCatOnly', [1 : 40])


(07/02/2013)

=== Instructions for extracting short wav files from long ones ===
# Usage example: 
long2short('SEQ03P03_test_long', 'SEQ03P03_behavioral', 'SEQ03P03_reproc', 1, 3.5, 3.0)

# For skipping files, do:
long2short('SEQ03P03_test_long', 'SEQ03P03_behavioral', 'SEQ03P03_reproc', 3, 3.5, 3.0, '--skip', 1)