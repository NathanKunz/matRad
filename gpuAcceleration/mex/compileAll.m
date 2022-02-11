function compileAll()
    mex -R2018a -outdir 'gpuAcceleration/mex' 'gpuAcceleration/mex/matRad_deconstructSparse.cpp'
    mex -R2018a -outdir 'gpuAcceleration/mex' 'gpuAcceleration/mex/matRad_deconstructSparseSingle.cpp'
    compileCUDA()
end

function compileCUDA()

    setenv('MW_ALLOW_ANY_CUDA','1')
    setenv('MW_NVCC_PATH', 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.5\bin\')

    oldDir = pwd;
    newDir = fileparts(mfilename('fullpath'));
    cd(newDir);

    mexcuda  'matRad_cuSparse.cu' ...
        -I"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.5\include" ...
        -L"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.5\lib\x64" ...
        NVCCFLAGS='"$NVCCFLAGS -Wno-deprecated-gpu-targets"' LDFLAGS='"$LDFLAGS -Wl,--no-as-needed"'...
        -lcusparse

    % mexcuda  'matRad_cuSparse.cu' ...
    %     -I"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.5\include" ...
    %     -L"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.5\lib\x64" ...
    %     NVCCFLAGS='"$NVCCFLAGS -Wno-deprecated-gpu-targets"' LDFLAGS='"$LDFLAGS -Wl,--no-as-needed"'...
    %     -lcusparse -g -v

    cd(oldDir);
end