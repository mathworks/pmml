function setupPMML()

%setupPMML Sets the PMML environment environment
if ~isdeployed
    mfilepath = fileparts(mfilename('fullpath'));
    addpath(genpath([mfilepath,'\Test']))
    addpath(genpath([mfilepath,'\Code']))
end


end %setupPMML