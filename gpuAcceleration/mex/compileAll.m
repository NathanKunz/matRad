% function to compile the cuSparse mex and the deconstruct sparase files for gpu acceleration
function compileAll()
    mex -R2018a -outdir 'gpuAcceleration/mex' 'gpuAcceleration/mex/matRad_deconstructSparse.cpp'
    %mexcuda -R2018a -outdir 'gpuAcceleration/mex' 'gpuAcceleration/mex/matRad_deconstructSparseSingle.cpp'
    compileCUDA()
end

