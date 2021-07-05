function multiEnergyCt = matRad_importMultiEnergyCt(varargin)
%MULTICTCUBE function for importing energy data from multi ct dicom data
%
% input:
%   vargin:         variable number of paths, which each contains the folder path
%                   to one of the energy ct paths 
%
% output:
%   multEnergCtCube: struct containing a field for each given dicom folder,
%                    with the corresponding ct data stored inside

    %make sure everything inside the matRad project is on the path
    matRad_rc;
    
    matRad_cfg = MatRad_Config.instance();
    
    % temporary container for the ct informations
    ctTmpContainer = cell(length(varargin), 1);
    
    for i = 1:length(varargin)
        
        %import dicom folder
        [fileList,patientList] = matRad_scanDicomImportFolder(varargin{i});
        
        %get some temporary dicom info for additional dicom info
        if verLessThan('matlab','9')
            tmpDicomInfo = dicominfo(fileList{1,1});
        else
            tmpDicomInfo = dicominfo(fileList{1,1},'UseDictionaryVR',true);
        end
        
        
        
        if isempty(fileList) || isempty(patientList)
            matRad_cfg.dispError('Error accured while trying to read dicom data from %s!\n',varargin{i});
        else
            
            %if there are more than one patient, display warning and only
            %use first else save the struct directly, possible improvement
            %by adding patientId as argument or ui element
            if length(patientList) > 1
                matRad_cfg.dispWarning('Dicom at %s contains more than one patient. Using only first patient, because importMulitEnergyCt is only intended for single patient data!\n',varargin{i});
                fileList = fileList(strcmp(fileList(:,3),patientList{1}), :);
            end
            
            res.x = str2double(fileList{1,9});
            res.y = str2double(fileList{1,10});
            res.z = str2double(fileList{1,11});
            ctTmpContainer{i} = matRad_importDicomCt(fileList, res, false);

            
            
            if isfield(tmpDicomInfo,'KVP')
                ctTmpContainer{i}.voltage = tmpDicomInfo.KVP;
                ctTmpContainer{i}.voltageUnit = 'kV';
            else
                matRad_cfg.dispWarning('Dicom data inside %s path does not contain voltage information. Trying to identify voltage withhin the folder path./n',iptnum2ordinal(i));
                %use given folder name as voltage value
                folderName = split(varargin{i}, filesep);
                match = regexp(folderName{end}, '\d{2,}','match');
                if ~isempty(match)
                    ctTmpContainer{i}.voltage = str2double(match{1});
                    ctTmpContainer{i}.voltageUnit = 'kV';
                else
                    matRad_cfg.dispWarning('No voltage identifier for %s path found in neither dicom-data nor filepath. Continue with next./n',iptnum2ordinal(i));
                    ctTmpContainer{i}.voltage = [];
                    ctTmpContainer{i}.voltageUnit = [];
                end
            end
            
            
            %check if ct cube is the same size as the first one
            if i > 1
                if isequal({ctTmpContainer{1}.resolution,ctTmpContainer{1}.x,ctTmpContainer{1}.y,ctTmpContainer{1}.z,ctTmpContainer{1}.cubeDim},...
                    {tmpCheck{1},tmpCheck{2},tmpCheck{3},tmpCheck{4},tmpCheck{5}})
                    tmpCheck = {ctTmpContainer{1}.resolution,ctTmpContainer{1}.x,ctTmpContainer{1}.y,ctTmpContainer{1}.z,ctTmpContainer{1}.cubeDim};
                else
                    matRad_cfg.dispError('Ct cube from %s differs in size, resolution or dimensions.\n',varargin{i});
                end
            else
                tmpCheck = {ctTmpContainer{1}.resolution,ctTmpContainer{1}.x,ctTmpContainer{1}.y,ctTmpContainer{1}.z,ctTmpContainer{1}.cubeDim};
            end
            
            
        end 
        
        multiEnergyCt = [ctTmpContainer{:}];
        
        
    end
    
end

