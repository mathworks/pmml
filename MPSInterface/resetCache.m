function result = resetCache(  )
%resetCache Interface to reset persistence service to be deployed in MPS

% Copyright 2020 MathWorks Inc.

result = pmml.PersistenceService.getInstance().reset;

end %resetCache