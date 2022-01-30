classdef matRad_DoseProjectionGpuMexCuSparse < matRad_BackProjection
% matRad_DoseProjection class to compute physical dose during optimization
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
        function obj = matRad_DoseProjectionGpuMexCuSparse()
            
        end
    
        function obj = compute(obj,dij,w)
            if ~isequal(obj.wCache,w)
                if ~isgpuarray(w)
                    w = gpuArray(w);
                end
                obj.d = obj.computeResult(dij,w);
                obj.wCache = w;
            end
        end
        
        function obj = computeGradient(obj,dij,doseGrad,w)
            if ~isequal(obj.wGradCache,w)
                obj.wGrad = obj.projectGradient(dij,doseGrad,w);
                obj.wGradCache = w;
            end
        end
        
        function d = GetResult(obj)
            d = obj.d;
            %d = cellfun(@(d) gather(d), obj.d, 'UniformOutput', false);
        end
        
        function wGrad = GetGradient(obj)
            %wGrad = obj.wGrad;
            wGrad = cellfun(@(wGrad) gather(wGrad), obj.wGrad, 'UniformOutput', false);
        end
        
        function d = computeResult(obj,dij,w)
            d = cell(size(dij.physicalDoseGpu));
            d = arrayfun(@(scen) computeSingleScenario(obj,dij,scen,w),ones(size(dij.physicalDoseGpu)),'UniformOutput',false);
        end
        
        function wGrad = projectGradient(obj,dij,doseGrad,w)
            wGrad = cell(size(dij.physicalDoseGpu));
            wGrad = arrayfun(@(scen) projectSingleScenarioGradient(obj,dij,doseGrad,scen,w),ones(size(dij.physicalDoseGpu)),'UniformOutput',false);
        end
        
        function d = computeSingleScenario(~,dij,scen,w)
            if ~isempty(dij.physicalDoseGpu{scen})
                d = dij.physicalDoseGpu{scen}*w;
            else
                d = [];
                matRad_cfg = MatRad_Config.instance();
                matRad_cfg.dispWarning('Empty scenario in optimization detected! This should not happen...\n');
            end 
        end
        
        function wGrad = projectSingleScenarioGradient(~,dij,doseGrad,scen,~)
            if ~isempty(dij.physicalDoseGpu{scen})
                wGrad = (doseGrad{scen}' * dij.physicalDoseGpu{scen})';
            else
                wGrad = [];
                matRad_cfg = MatRad_Config.instance();
                matRad_cfg.dispWarning('Empty scenario in optimization detected! This should not happen...\n');
            end
        end
    end
end