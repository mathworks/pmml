function xml = writePMML( model, name, varargin )
% writePMML writes PMML from a machine learning model
%
% writePMML( model, name ) writes the PMML for model to name.pmml
%
% writePMML( model, name, varargin ) supplies additional arguments
%
% pmml = writePMML( ... ) returns the PMML as a string instead of writing
% to file

% Copyright 2018 MathWorks Inc.

nargoutchk(0,1)
narginchk(2,Inf)

modelObj = pmml.PMMLModel.createPMMLModel( model, name, varargin{:} );

if nargout == 1
    xml = modelObj.PMML;
else
    writePMML( modelObj, [name '.xml'] )
end


end