function result = addModel( pmmlModel , modelName )
%add Interface to addModel to be deployed in MPS
%    usage: result = addModel( pmmlModel , modelName )
%    pmmlModel: a char or string with either the file path
%               or the PMML content as characters

% Copyright 2020 MathWorks Inc.

server = pmml.server.Server.getInstance();
result = server.addModel(pmmlModel, modelName);

end %addModel