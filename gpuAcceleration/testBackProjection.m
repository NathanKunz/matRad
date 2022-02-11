function [projectTime_mean, projectTime_std, gradTime_mean, gradTime_std] = testBackProjection(pln, dij, nRuns)
% testBackProjection runs test for backprojection gpu capabilites
% creates a back projection identical to matRad_fluenceOptimization
% then test the gpu time of the compute and compute gradient function from the backprojection for nRuns time
% and return the result variables

    switch pln.propOpt.bioOptimization
        case 'LEMIV_effect'
            backProjection = matRad_EffectProjection;
        case 'const_RBExD'
            backProjection = matRad_ConstantRBEProjection;
        case 'LEMIV_RBExD'
            backProjection = matRad_VariableRBEProjection;
        case 'none'
    %         backProjection = matRad_DoseProjection;
    %       % gpu Acceleration
            if ~isfield(pln.propOpt, 'gpuOpt')
                backProjection = matRad_DoseProjection;
            else
    %             
                switch pln.propOpt.gpuOpt
                    case 'gpuArray'
                        backProjection = matRad_DoseProjectionGpuArray;
                        % load dij onto gpu for dose calculation with gpu arrays
                        dij.physicalDoseGpu = cellfun(@gpuArray, dij.physicalDose,  'UniformOutput', false);
                     case 'gpuMex'
                         backProjection = matRad_DoseProjectionGpuMex;
                     case 'gpuMexCuSparse'
                         backProjection = matRad_DoseProjectionGpuMexCuSparse;
                         % load dij physical dose into gpu sparse array 
                         dij.physicalDoseGpu = cellfun(@matRad_gpuSparse, dij.physicalDose, 'UniformOutput', false);
    %                 case 'gpuCuda'
    %                     backProjection =  matRad_DoseProjectionGpuCuda;
                    otherwise
                        backProjection = matRad_DoseProjection;
                end
            end

        otherwise
            warning(['Did not recognize bioloigcal setting ''' pln.probOpt.bioOptimization '''!\nUsing physical dose optimization!']);
            backProjection = matRad_DoseProjection;
    end
    
    doseGrad{1} = zeros(dij.doseGrid.numOfVoxels,1);

    T_Projection =  zeros(1,nRuns);
    T_Gradient = zeros(1,nRuns);
    
    for i = 1:nRuns
        
        wOnes       = ones(dij.totalNumOfBixels,1);
        w = rand(dij.totalNumOfBixels,1);
        %w       = wOnes * randWeight;
        
        f_proj = @() backProjection.compute(dij,w);
        f_grad = @() backProjection.computeGradient(dij,doseGrad,w);
        T_Projection(i) = gputimeit(f_proj);
        T_Gradient(i) = gputimeit(f_grad);
        
    end
    
    projectTime_mean = mean(T_Projection);
    projectTime_std = std(T_Projection);
    
    gradTime_mean = mean(T_Gradient);
    gradTime_std = mean(T_Gradient);
end


