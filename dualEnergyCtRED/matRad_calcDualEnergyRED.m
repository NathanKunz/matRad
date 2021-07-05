function rED = matRad_calcDualEnergyRED(lowEnergyPath,highEnergyPath,modeId)
%function for calculating the relative electron density via dual energy ct
%images, for now only its hard coded to 80kv and 140 kv folder structure

matRad_cfg = MatRad_Config.instance();
    
    %import the dual energy dicom data into a ct struct and get the corespondig
    %alpha value for the following alpha fitting
    dualCt = matRad_importMultiEnergyCt(lowEnergyPath,highEnergyPath);
    
    if exist('alphaConfig.txt','file')
        %read alpha config information from alphaConfig.txt
        t = readtable('alphaConfig.txt');
        %compare given machineId to machine id in config file
        tf = strcmpi(t{:,1}, modeId);
        if any(tf)
            alpha = t{tf,2}(1);
        else
            matRad_cfg.dispError('No matching alpha value for machine id: %s found!',modeId);
        end
    else
        matRad_cfg.dispError('No alphaConfig.txt file found!');
    end
        
    %convert to HU for displaying the blended ct image by: (ret - 1) * 1000HU
    rED = matRad_alphaBlending(alpha,dualCt.ct80kV.cubeHU{1},dualCt.ctSn140kV.cubeHU{1});

end


