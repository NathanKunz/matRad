classdef matRad_BackProjectionGpuArray < matRad_BackProjection
% matRad_BackProjectionGpuArray superclass for all backprojection algorithms 
% used within matRad optimzation processes accelerated for the use with
% parallel Toolbox gpuArrays
%
% dij needs to contain a field called phyiscalDoseGpu which contains the
% phyiscal dose(s) represented as a gpuArray object, this should be
% set in the fluenceOptimization
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2019 the matRad development team. 
% 
% This file is part of the matRad project. It is subject to the license 
% terms in the LICENSE file found in the top-level directory of this 
% distribution and at https://github.com/e0404/matRad/LICENSES.txt. No part 
% of the matRad project, including this file, may be copied, modified, 
% propagated, or distributed except according to the terms contained in the 
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    
    methods
        function obj = matRad_BackProjectionGpuArray()
            
        end
    
        function obj = compute(obj,dij,w)
            if ~isequal(obj.wCache,w)
                obj.wCache = w;
                if ~isgpuarray(w)
                    w = gpuArray(w);
                end
                obj.d = obj.computeResult(dij,w);
            end
        end
        
        function obj = computeGradient(obj,dij,doseGrad,w)
            if ~isequal(obj.wGradCache,w)
                obj.wGradCache = w;
                if ~isgpuarray(doseGrad{1})
                    doseGrad = cellfun(@gpuArray, doseGrad,  'UniformOutput', false);
                end
                obj.wGrad = obj.projectGradient(dij,doseGrad,w);
            end
        end
        
        
        function d = GetResult(obj)
            d = obj.d; % we leave d on gpu because it is not needed for IPOPT and maybe speed up other calculations
            %d = cellfun(@(d) gather(d), obj.d, 'UniformOutput', false);
        end
        
        function wGrad = GetGradient(obj)
            % move the wGrad to the cpu because IPOPT can't handle gpuArray
            % objects
            wGrad = cellfun(@(wGrad) gather(wGrad), obj.wGrad, 'UniformOutput', false); 
        end
        
        function d = computeResult(obj,dij,w)
            if ~isfield(dij, 'physicalDoseGpu')
                matRad_cfg = MatRad_Config.instance();
                matRad_cfg.dispError('Optimization on gpu not possible because no physicalDoseGpu is defined in dij.\n');
            end
            
            if ~isgpuarray(dij.physicalDoseGpu{1})
                matRad_cfg = MatRad_Config.instance();
                matRad_cfg.dispError('Optimization on gpu not possible because no physicalDoseGpu is defined in dij.\n');
            end
            
            d = cell(size(dij.physicalDoseGpu));
            d = arrayfun(@(scen) computeSingleScenario(obj,dij,scen,w),ones(size(dij.physicalDoseGpu)),'UniformOutput',false);
            
        end
        
        function wGrad = projectGradient(obj,dij,doseGrad,w)
            if ~isfield(dij, 'physicalDoseGpu')
                matRad_cfg = MatRad_Config.instance();
                matRad_cfg.dispError('Optimization on gpu not possible because no physicalDoseGpu is defined in dij.\n');
            end
            wGrad = cell(size(dij.physicalDoseGpu));
            wGrad = arrayfun(@(scen) projectSingleScenarioGradient(obj,dij,doseGrad,scen,w),ones(size(dij.physicalDoseGpu)),'UniformOutput',false);
        end
    end
    
    %These should be abstract methods, however Octave can't parse them. As soon 
    %as Octave is able to do this, they should be made abstract again 
    %if you want to acces the physicalDose in these methods use
    %dij.physicalDoseGpu
    methods %(Abstract)
        function d = computeSingleScenario(obj,dij,scen,w)
            error('Function needs to be implemented');
        end

        function wGrad = projectSingleScenarioGradient(obj,dij,doseGrad,scen,w)
            error('Function needs to be implemented');
        end
        
    end
end

