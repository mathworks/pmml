function [modelNames, modelParams] = getModels()
%getModels Interface to get available PMML models to be deployed in MPS
% result: list of model names available in server
% Copyright 2020 MathWorks Inc.
models = pmml.server.Server.getInstance().Models;
if isempty(models)
    modelNames = {};
    modelParams = {};
else
    modelNames = [models.Name];
    modelParams = {models.Predictors};
end

end %getModels