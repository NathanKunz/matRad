function res = createDoseCalculationData(phantom, radiationMode, nBeams, bixelWidth, outputFolder)
%createDoseCalculationData function for caling the dose calculation with
% different parameters based on the matRad main script 
% and saves it in a given folder 
% created for testing gpu acceleration of the dose optimization
% call
%   resultID = saveDoseCalculationData(phantom,radiationMode,outputFolder)
%   
% input
%   phantom:        patient data -> HEAD_AND_NECK.mat / TG119.mat / PROSTATE.mat / LIVER.mat / BOXPHANTOM.mat
%   radiationMode:        radiation mode ->  photons / protons / carbon 
%   nBeam:      number of Beams used -> 5 7 9
%   bixelWidth:     bixelWidth and resolution used -> 5 3.5 2
%   outputFolder: outputFolder for the resulting file relative to
%   matRad_root dictionary
%
% output
%   res:  1 File was saved, 0 Problem accured
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2015 the matRad development team. 
% 
% This file is part of the matRad project. It is subject to the license 
% terms in the LICENSE file found in the top-level directory of this 
% distribution and at https://github.com/e0404/matRad/LICENSES.txt. No part 
% of the matRad project, including this file, may be copied, modified, 
% propagated, or distributed except according to the terms contained in the 
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

matRad_rc
matRad_cfg.disableGUI = true; % disable gui 
% load patient data, i.e. ct, voi, cst

%load HEAD_AND_NECK.mat
%load TG119.mat
%load PROSTATE.mat
%load LIVER.mat
%load BOXPHANTOM.mat
load(phantom, 'ct', 'cst');

% meta information for treatment plan

%pln.radiationMode   = 'photons';     % either photons / protons / carbon
pln.radiationMode = radiationMode;
pln.machine         = 'Generic';

pln.numOfFractions  = 30;

% beam geometry settings
%pln.propStf.bixelWidth      = 5; % [mm] / also corresponds to lateral spot spacing for particles
pln.propStf.bixelWidth      = bixelWidth;
%pln.propStf.gantryAngles    = [0:72:359]; % [?]
pln.propStf.gantryAngles    = [0:360/nBeams:359]; % [?]
%pln.propStf.couchAngles     = [0 0 0 0 0]; % [?]
pln.propStf.couchAngles     = zeros(1,nBeams);
pln.propStf.numOfBeams      = numel(pln.propStf.gantryAngles);
pln.propStf.isoCenter       = ones(pln.propStf.numOfBeams,1) * matRad_getIsoCenter(cst,ct,0);

% dose calculation settings
%pln.propDoseCalc.doseGrid.resolution.x = 5; % [mm]
%pln.propDoseCalc.doseGrid.resolution.y = 5; % [mm]
%pln.propDoseCalc.doseGrid.resolution.z = 5; % [mm]

pln.propDoseCalc.doseGrid.resolution.x = bixelWidth; % [mm]
pln.propDoseCalc.doseGrid.resolution.y = bixelWidth; % [mm]
pln.propDoseCalc.doseGrid.resolution.z = bixelWidth; % [mm]

% optimization settings
pln.propOpt.optimizer       = 'IPOPT';
pln.propOpt.bioOptimization = 'none'; % none: physical optimization;             const_RBExD; constant RBE of 1.1;
                                      % LEMIV_effect: effect-based optimization; LEMIV_RBExD: optimization of RBE-weighted dose
pln.propOpt.runDAO          = false;  % 1/true: run DAO, 0/false: don't / will be ignored for particles
pln.propOpt.runSequencing   = false;  % 1/true: run sequencing, 0/false: don't / will be ignored for particles and also triggered by runDAO below

%% initial visualization and change objective function settings if desired
   %matRadGUI

%% generate steering file
stf = matRad_generateStf(ct,cst,pln);

%% dose calculation
if strcmp(pln.radiationMode,'photons')
    dij = matRad_calcPhotonDose(ct,stf,pln,cst);
    %dij = matRad_calcPhotonDoseVmc(ct,stf,pln,cst);
elseif strcmp(pln.radiationMode,'protons') || strcmp(pln.radiationMode,'carbon')
    dij = matRad_calcParticleDose(ct,stf,pln,cst);
end

%% save data file
[~,phantomName,~] = fileparts(phantom);
filename = sprintf('%s_%s_%d-Beams_%d-Res_data.mat', phantomName, radiationMode, nBeams, fix(bixelWidth)); % bixel width is gonna get round to an int for easier file saving so 3 and 3.5 are the same
filepath = fullfile(matRad_cfg.matRadRoot, outputFolder, filename);
save(filepath, 'cst', 'ct', 'pln', 'stf', 'dij', '-v7.3');
res = 1;

matRad_cfg.reset(); 
%% inverse planning for imrt
%resultGUI = matRad_fluenceOptimization(dij,cst,pln);

end

