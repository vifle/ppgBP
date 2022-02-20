function [] = storeSettings(baseDatasetDir,settings)
    % check all settings fields that exist
    % build priority list in this function and check the last steps first
    % if they are not there, check next step (in loop), if they are there,
    % break free from loop, do storing and finish function
    
    prioList = {'Test','Train','Features','Decomposition'};
    settingsFields = fieldnames(settings);
    
    % loop through prioList and check for entries in settingsFields
    for step = 1:numel(prioList)
        if(any(strcmp(settingsFields,prioList{step})))
            currentStep = step;
            break;
        else
            currentStep = NaN;
        end
    end
    
    % get new settings
    newSettings = settings.(prioList{currentStep});
    if(newSettings.extractFullDataset)
        full_subset = 'FULL';
    else
        full_subset = 'SUBSET';
    end
    
    % load settings
    if(currentStep==3) % feature extraction
        fromDir = newSettings.fromDir;
        oldSettings = load([baseDatasetDir newSettings.dataset '\Decomposition\' full_subset '\' fromDir '\settings.mat']); % load from previous step
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TODO %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Für Test und Train passt das natürlich so kaum
    % eigentlich kann ich für für jeden Step separat einen Lademechanismus
    % machen
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % append new settings if old ones exist
    if(exist('oldSettings','var')==1)
        oldSettingsFields = fieldnames(oldSettings);
        for currentSetting = 1:numel(oldSettingsFields)
            settings.(oldSettingsFields{currentSetting}) = oldSettings.(oldSettingsFields{currentSetting});
        end
    end
    
    % save settings
    toDir = newSettings.toDir;
    saveDir = [baseDatasetDir newSettings.dataset '\' prioList{currentStep} '\' full_subset '\' toDir '\'];
    if(~(exist(saveDir,'dir')==7))
        mkdir(saveDir);
    end
    save([saveDir 'settings.mat'],'settings')
    
    

    
    
    
    % need to load correct struct
    % - from correct step                           DONE
    % - from correct ending                         
    % - only do that for steps after decomposition  DONE
    % append new settings
    % save settings
    % - to correct step 
    % - to correct ending (settings.toDir)
end