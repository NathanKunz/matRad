# Run Test for GPU Acceleration:

1. pull matRad Branch dev_gpuAcceleration 
2. call compileAll() in matRad\gpuAcceleration\mex, this should compile the mex files:
    - gpuAcceleration/mex/matRad_deconstructSparse.cpp
    - gpuAcceleration/mex/matRad_deconstructSparseSingle.cpp
    - gpuAcceleration/mex/matRad_cuSparse.cu (gets compiled with mexcuda, CUDA Toolkit has to be installed and on Windows-Path)
3. open runTest
    * in the first block you can set Phantoms, radiationModes, numOfBeamList, bixelWidths and output folder 
    * 2nd block runs the doseCalculation on each given setting and stores the result into the outputFolder (if you want to delete all saved workspaces, it can be set in last block)
    * 3rd block the workspaces for which the gpu Programming should be tested can be individually selected or ignore it
    * 4th block runs through all saved workspaces from the dose calculation and calls the fluenzOptimization with each gpu Implementation on it, measures runtimes, and stores them into the cell arrays
    * 5th block if gpu measurements should be stored you have to run GPU-Z at the same time and write the path to the outputLog from gpu-z into gpuzLogFile Variable, else set useGpuz to 0
    * 6th block creates the table from all measurements
    * last two blocks writes the table to a .csv and .xlsx file and clears the output folder from the doseCalculation if wanted
4. run runTest
    - if you want to measure GPU-measurements start GPU-Z go to the Sensors Tab and Check "Log to file", and select a path and filename that matches the one in the "gpuzLogFile" Variable
    - let the test run
    - after all possible runs finished, Matlab consoles ask for input
    - close GPU-Z
    - give Matlab any Input
    - results should be written to .csv and .xlsx file
