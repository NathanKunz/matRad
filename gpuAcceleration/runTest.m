% run test function to do sparse
% vector product with different sizes for all modalitys photon,
% carbon, and 3 different sizes for number of beamlets and graph it

% and cases for:
%   gpuArray before after 
%   mex files:
%       - use build in spasrse library and convert to float
%       - use cusparse or eigen library and convert to float
%       - write a kernel inside the mex file
%   custom kernel that gets directly called from matlab 

matRad_rc

%% test cases
phantoms = {'PROSTATE', 'HEAD_AND_NECK', 'TG119'};
radiationModes = {'photons', 'protons'};
numOfBeamsList = [3];%[3, 5, 7];
bixelWidthList =  [5, 3.5];% [5, 3.5]; %[5, 3.5, 2]

% if there should be different beams or resolutions for different phantoms
% or radiation a for every phantom would be needed
%% create dose calculation for all cases
outputFolder = './gpuAcceleration/workspace/';
runDoseCalc = 1;
fileList = {};
for phantom_i = 1:length(phantoms)
    phantom = phantoms{phantom_i};
    for modalities_i=1:length(radiationModes)
        radiationMode = radiationModes{modalities_i};
        for numOfBeams = numOfBeamsList
            for bixelWidth = bixelWidthList
                
                %check if file already exist
                [~,phantomName,~] = fileparts(phantom);
                filename = sprintf('%s_%s_%d-Beams_%d-Res_data.mat', phantomName, radiationMode, numOfBeams, fix(bixelWidth));  % bixel width is gonna get round to an int for easier file saving so 3 and 3.5 are the same
                filepath = fullfile(matRad_cfg.matRadRoot, outputFolder, filename);
                fileList{end+1} = filepath; % create file list
                
                % start dose calculation
                if exist(filepath, 'file') ~= 2 && runDoseCalc
                    createDoseCalculationData(phantom, radiationMode, numOfBeams, bixelWidth, outputFolder);
                end
                    
                
            end         
        end
    end
end

%% get files for gpu testing
%writeDoc = 1;
selectCustomFiles = 0;
useAllDataFiles = 0;

if useAllDataFiles
    files = dir(fullfile(fullfile(matRad_cfg.matRadRoot, outputFolder), '*.mat'));
    fileList = {files.name};
    fileList = cellfun(@(x) fullfile(matRad_cfg.matRadRoot, outputFolder, x), fileList, 'UniformOutput', false);
end

if selectCustomFiles
    [files,path] = uigetfile('*.mat',...
   'Select One or More Files',...
    fullfile(matRad_cfg.matRadRoot, outputFolder), ...
   'MultiSelect', 'on');
    fileList = cellfun(@(x) fullfile(path, x), files, 'UniformOutput', false);
end

% if neither of those options aboth are used the file List from the dose
% Calc step is used, so all files defined in these parameters

%% run gpu testing
gpuOptTypes = {'none', 'GpuArray', 'GpuMexCuSparse'}; %'gpuArray', 'none', 'gpuMexCuSparse'

% set up diary output for optimization writeup
diaryOutputFolder = fullfile(matRad_cfg.matRadRoot,'./gpuAcceleration/output/diarys');
if ~exist(diaryOutputFolder)
    mkdir(diaryOutputFolder);
end

% set up output for the resulting gui
guiOutputFolder = fullfile(matRad_cfg.matRadRoot,'./gpuAcceleration/output/resGUI');
if ~exist(guiOutputFolder)
    mkdir(guiOutputFolder);
end

% allocate array for results
nel = length(fileList) * length(gpuOptTypes);
phantomRet = cell(nel, 1);
optTypeRet = cell(nel, 1);
radiationModeRet = cell(nel, 1);
nBeamsRet = cell(nel, 1);
resolutionRet = cell(nel, 1);
numberOfScenariosRet = cell(nel, 1);
numOfBixels= cell(nel, 1);

phyiscalDoseSizeMRet = cell(nel, 1);
physicalDoseSizeNRet = cell(nel, 1);
nnzRet = cell(nel, 1);
nnzRatioRet = cell(nel, 1);
bytesRet = cell(nel, 1);

nIterationsRet = cell(nel, 1);
ipoptTimeRet = cell(nel, 1);
fullTimeRet = cell(nel, 1);

backProjectionMeanRet = cell(nel, 1);
backProjectionStdRet = cell(nel, 1);
backProjectionGradientMeanRet = cell(nel, 1);
backProjectionGradientStdRet = cell(nel, 1);

gpuMaxUsageRet = cell(nel, 1);
gpuMaxMemoryRet = cell(nel, 1);

startTimeRet = cell(nel, 1);
endTimeRet = cell(nel, 1);
errorRet = cell(nel,1);
fileNameRet = cell(nel,1);

res_idx = 1;

% iterate over files and run dose optimization on each
for k = 1:length(fileList)
    f = fileList{k};
    [~,fname,~] = fileparts(f);
    % load resulting data from dose calculation
    load(f, 'cst', 'ct', 'dij', 'pln', 'stf');
    
    for opt_i = 1:length(gpuOptTypes)
        
        optimizationType = gpuOptTypes{opt_i};
        g = gpuDevice(1);
        
        matRad_cfg.dispInfo('Starting optimization for: %s, with gpu type: %s \n', fname, optimizationType);

        % write variable from dose calculation into the result arrays
        fileNameRet{res_idx} = fname;
        fnamesplit = split(fname, '_');
        phantomRet{res_idx} = fnamesplit{1};
        optTypeRet{res_idx} = optimizationType;
        radiationModeRet{res_idx} = pln.radiationMode;
        nBeamsRet{res_idx} = dij.numOfBeams;
        resolutionRet{res_idx} = dij.doseGrid.resolution.x;
        numberOfScenariosRet{res_idx} = dij.numOfScenarios;
        numOfBixels{res_idx} = dij.bixelNum;

        
        % need to extract the physical Dose cube from dij to check the
        % memory size
        pd = dij.physicalDose{1};
        S = whos('pd');
        
        phyiscalDoseSizeMRet{res_idx} = S.size(1);
        physicalDoseSizeNRet{res_idx} = S.size(2);
        nnzRet{res_idx} = nnz(pd);
        nnzRatioRet{res_idx} = nnz(pd) / numel(pd) ;
        bytesRet{res_idx} = S.bytes;
        clear pd S;
               
        %% Inverse Optimization for IMPT
        % The goal of the fluence optimization is to find a set of bixel/spot 
        % weights which yield the best possible dose distribution according to the 
        % clinical objectives and constraints underlying the radiation treatment
        % gpu prop opt setting
        
        try 
            
            pln.propOpt.gpuOpt = optimizationType;
            startTimeRet{res_idx} = datetime('now');

            diary(fullfile(diaryOutputFolder, [fname '_' optimizationType '.txt']));
            tStart = tic;
            resultGUI = matRad_fluenceOptimization(dij,cst,pln);
            wait(g);
            tEnd = toc(tStart);
            diary off;
            save(fullfile(guiOutputFolder, [fname '_' optimizationType '.mat']), 'resultGUI')

            % store resulting times and informations in arrays
            nIterationsRet{res_idx} = resultGUI.info.iter;
            ipoptTimeRet{res_idx} = resultGUI.info.cpu;
            fullTimeRet{res_idx} = tEnd;
            
            
            % run test for back Projection 
            matRad_cfg.dispInfo('Starting timing test for back projection\n');
            [projectTime_mean, projectTime_std, gradTime_mean, gradTime_std] = testBackProjection(pln, dij, 15);
            
            backProjectionMeanRet{res_idx} = projectTime_mean;
            backProjectionStdRet{res_idx} = projectTime_std;
            backProjectionGradientMeanRet{res_idx} = gradTime_mean;
            backProjectionGradientStdRet{res_idx} = gradTime_std;
            matRad_cfg.dispInfo('Finished timing tests for back projection\n');
            
        catch ME
            matRad_cfg.dispWarning('Experiencd an error during gpu test of %s. Error-Message:\n %s\n', [fname '_' optimizationType],getReport(ME));
            errMsg = sprintf('Experiencd an error during gpu test of %s. Error-Message:\n %s\n See %s for more information.', ...
                [fname '_' optimizationType],getReport(ME), fullfile(diaryOutputFolder, [fname '_' optimizationType '.txt']));
            errorRet{res_idx} = errMsg;
            diary off
            toc(tStart);
        end
        % somewhat clear up workspace
        clear('resultGUI');
        % reset gpu for somewhat fair tests
        wait(g);
        reset(g);
        % get end time and pause mainly for gpu z timestamps
        endTimeRet{res_idx} = datetime('now');
        pause(10);
        
        res_idx = res_idx + 1;
        

    end  
    clear('cst','ct','dij','pln','stf');
end

%% fill the gpu informations from the test with gpu-z for this gpu-z had to be running 

useGpuz = 1;
gpuzLogFile = [fullfile(matRad_cfg.matRadRoot,'./gpuAcceleration/'), 'GPU-Z Sensor Log.txt'];
if useGpuz
    str = input('Stop gpu-z logging and type anything to continue','s');
    
    if exist(gpuzLogFile, 'file') == 2
        t = readtable(gpuzLogFile,'Delimiter', ','); % load the date from gpuz
        t.Date = arrayfun(@(x) datestr(x), t.Date, 'UniformOutput', false); % format gpu z dates into matlabs default

        % iterate over all cell arrays elements and find the fitting
        % variables in the table
        for time_iter = 1:length(startTimeRet)
            if ~isempty(startTimeRet{time_iter}) && ~isempty(endTimeRet{time_iter})

                startIdx = find(contains(t.Date,datestr((startTimeRet{time_iter}))));
                endIdx = find(contains(t.Date,datestr((endTimeRet{time_iter}))));

                gpuMaxUsageRet{time_iter} = max(t.GPULoad___(startIdx:endIdx)); % table coloumns are named kinda stange
                gpuMaxMemoryRet{time_iter} = max(t.MemoryUsed_MB_(startIdx:endIdx));

            end
        end
    else
        matRad_cfg.dispInfo('No Gpu-Sensor file found continue without it');
    end
    
end
%delete(gpuzLogFile) % delete for next time
    
%% create table from output vector
variableNames_de = {'Phantom','GPU Optimierung', 'Modalität', 'Anzahl Beams', 'Aufloesung', 'Anzahl Szenarien', 'Anzahl Bixel', 'Physical Dose Zeilen', 'Physical Dose Spalten', 'Anzahl NNZ', ...
    'Verhaeltnis NNZ', 'Groeße Physical Dose', 'Iterationen', 'CPU secs in IPOPT', 'Gesamtzeit', 'Laufzeit Back-Projection Mittelwert', 'Laufzeit Back-Projection Standardabweichung', ...
    'Laufzeit Back-Projection Gradient Mittelwert', 'Laufzeit Back-Projection Gradient Standardabweichung', 'Maximale GPU Auslastung', 'Maximaler belegter GPU Speicher', 'Startzeit', 'Endzeit', 'Dateiname', 'Error'};
variableNames_en = {};

resultTable = table(phantomRet ,optTypeRet, radiationModeRet, nBeamsRet, resolutionRet, numberOfScenariosRet, numOfBixels, phyiscalDoseSizeMRet, physicalDoseSizeNRet, nnzRet, ...
    nnzRatioRet, bytesRet, nIterationsRet, ipoptTimeRet, fullTimeRet, backProjectionMeanRet, backProjectionStdRet, backProjectionGradientMeanRet, ...
    backProjectionGradientStdRet, gpuMaxUsageRet, gpuMaxMemoryRet, startTimeRet, endTimeRet, fileNameRet, errorRet, ...
    'VariableNames', variableNames_de);


%% export resulting Table
% fill empty fields in table with nan
%resultTable = fillmissing(resultTable,'constant',nan);

% write table to csv and excel
writetable(resultTable, [fullfile(matRad_cfg.matRadRoot,'./gpuAcceleration/output/'), 'gpuResultData.xlsx'], 'Sheet', 1)
writetable(resultTable, [fullfile(matRad_cfg.matRadRoot,'./gpuAcceleration/output/'), 'gpuResultData.csv'], 'Delimiter', ',');

%% clear the folder if wanted
clearFolder = 0;

if clearFolder
    delete([fullfile(matRad_cfg.matRadRoot, outputFolder),'*']);
end

