% function to compile the cuSparse mex file for gpu acceleration
function compileCUDA()
    
    setenv('MW_ALLOW_ANY_CUDA','1')
    setenv('MW_NVCC_PATH', 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.5\bin\')

    oldDir = pwd;
    newDir = fileparts(mfilename('fullpath'));
    cd(newDir);
    
    try
        mexcuda  'matRad_cuSparse.cu' ...
            -I"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.5\include" ...
            -L"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.5\lib\x64" ...
            NVCCFLAGS='"$NVCCFLAGS -Wno-deprecated-gpu-targets"' LDFLAGS='"$LDFLAGS -Wl,--no-as-needed"'...
            -lcusparse -g -v
        
        % compile command for debugging 
        % mexcuda  'matRad_cuSparse.cu' ...
        %     -I"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.5\include" ...
        %     -L"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.5\lib\x64" ...
        %     NVCCFLAGS='"$NVCCFLAGS -Wno-deprecated-gpu-targets"' LDFLAGS='"$LDFLAGS -Wl,--no-as-needed"'...
        %     -lcusparse -g -v
    catch ME
        cd(oldDir);
        rethrow(ME);
    end
    cd(oldDir);
end