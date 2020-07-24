function result = execute( modelName, data , conversionData )
%execute Interface to execute method in Server class to deploy in MPS

% Copyright 2020 MathWorks Inc.

server = pmml.server.Server.getInstance();
dataTable = MPSParameterHandler.cell2Table(data, conversionData);
result = server.executeModel(modelName, dataTable);

end %execute