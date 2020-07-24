classdef PMMLReader
    %PMMLReader PMML files reader class
    
    % Copyright 2020 MathWorks Inc.
    properties
        PMMLStruct struct    %PMML data as a MATLAB structure
        Model                %Machine Learning model object
        ModelParams struct   %structure array containing model params description
    end %properties
    
    methods
        function obj = readPMML( obj , pmmlFilePath )
            assert(ischar(pmmlFilePath))
            try
                s = pmml.xml2struct(pmmlFilePath);
            catch e
                error('PMMLReader:readPMML','Error reading %s %s',pmmlFilePath,e.message)
            end
            if ~isfield(s,'PMML')
                error('PMMLReader:readPMML','File %s is not a PMML file',pmmlFilePath)
            end
            obj.PMMLStruct = s;
            if isfield(s.PMML,'Scorecard')
                warning('off','MATLAB:table:RowsAddedExistingVars')
                obj.Model = obj.createScorecardModel();
                predictorType = cell(numel( obj.Model.PredictorVars,1));
                numeric = ismember( obj.Model.PredictorVars, obj.Model.NumericPredictors);
                categorical = ismember( obj.Model.PredictorVars, obj.Model.CategoricalPredictors);
                predictorType(:) = {'Unset'};
                predictorType(numeric) = {'Numeric'};
                predictorType(categorical) = {'Categorical'};
                obj.ModelParams = struct('Predictors',obj.Model.PredictorVars, ...
                    'PredictorType', predictorType);
                warning('on','MATLAB:table:RowsAddedExistingVars')
            else
                error('PMMLReader:readPMML','Case not implemented')
            end
        end %readPMML
    end % public methods
    
    methods ( Access = private)
        function [sc, obj] = createScorecardModel( obj )
            assert(isfield(obj.PMMLStruct.PMML,'DataDictionary'),'Missing DataDictionary field')
            assert(isfield(obj.PMMLStruct.PMML,'Scorecard'),'Missing Scorecard field')
            assert(isfield(obj.PMMLStruct.PMML.Scorecard,'MiningSchema'),'Missing MiningSchema field')
            assert(isfield(obj.PMMLStruct.PMML.Scorecard,'Output'),'Missing Output field')
            assert(isfield(obj.PMMLStruct.PMML.Scorecard,'Characteristics'),'Missing Characteristics field')
            s = struct;
            s = iProcessDataDictionary(s,obj.PMMLStruct.PMML.DataDictionary);
            s = iProcessMiningSchema(s, obj.PMMLStruct.PMML.Scorecard.MiningSchema);
            s = iProcessOutput(s, obj.PMMLStruct.PMML.Scorecard.Output);
            s = iProcessCharacteristics(s, obj.PMMLStruct.PMML.Scorecard.Characteristics);
            

            sc = pmml.PMMLCompactCreditScorecard(s);
        end %createScorecardModel
    end %private methods
end %PMMLReader class

function y = iConvertPMMLType2MATLABType( c )
switch c
    case 'integer'
        y = 'int64';
    otherwise
        y = c;
end
end %iConvertPMMLType2MATLABType

function varType = iGetVarType( s )
varType = [];
for ii=1:numel(s.attribute)
    if isfield(s.attribute(ii).predicate,'value')
        if ~isempty(str2double(s.attribute(ii).predicate(1).value)) && ...
                ~isnan(str2double(s.attribute(ii).predicate(1).value))
            varType = 'double';
        else
            varType = 'string';
        end
    end
end
assert(~isempty(varType))
end %iGetVarType

function s = iProcessCharacteristics(s, characteristics )
assert(isfield(characteristics,'Characteristic'), 'Missing Characteristic field in Characteristics')

for ii=1:numel(characteristics.Characteristic)
    d = characteristics.Characteristic{ii};
    s.characteristics(ii).baselineScore = str2double(d.Attributes.baselineScore);
    s.characteristics(ii).name = d.Attributes.name;
    jjIndex = 0;
    for jj=1:numel(d.Attribute)
        if isfield(d.Attribute{jj},'Attributes')
            if ~isempty(d.Attribute{jj}.Attributes.partialScore)
                jjIndex = jjIndex + 1;
            end
            s.characteristics(ii).attribute(jjIndex).partialScore = str2double(d.Attribute{jj}.Attributes.partialScore);
        end
        if isfield(d.Attribute{jj},'CompoundPredicate')
            for kk=1:numel(d.Attribute{jj}.CompoundPredicate.SimplePredicate)
                s.characteristics(ii).attribute(jjIndex).predicate(kk) = d.Attribute{jj}.CompoundPredicate.SimplePredicate{kk}.Attributes;
            end
        end
        if isfield(d.Attribute{jj},'SimplePredicate')
            s.characteristics(ii).attribute(jjIndex).predicate = d.Attribute{jj}.SimplePredicate.Attributes;
        
        end
        if isfield(d.Attribute{jj},'ComplexPartialScore')
            s.characteristics(ii).attribute(jjIndex).ComplexPartialScore = d.Attribute{jj}.ComplexPartialScore;
        end
        if isfield(d.Attribute{jj},'True')
            s.characteristics(ii).attribute(jjIndex).True = [];
        end
    end
end

% Extract predictor types
activeVars = ismember({s.miningFields.type},'active');
varTypes = cell(numel(s.characteristics),1);
for ii=1:numel(s.characteristics)
    varTypes{ii} = iGetVarType(s.characteristics(ii));
end
s.predvarTypes = varTypes;
% map of variables in characteristics (i.e., with coefficients in model)
s.varMap =  {s.miningFields(activeVars).name};

end %iProcessCharacteristics

function s = iProcessDataDictionary(s, dataDictionary )
for iField=1:numel(dataDictionary.DataField)
    d = dataDictionary.DataField{iField};
    s.fields(iField).dataType = d.Attributes.dataType;
    % Convert types to MATLAB types
    s.fields(iField).dataType = iConvertPMMLType2MATLABType(s.fields(iField).dataType);
    s.fields(iField).optype = d.Attributes.optype;
    s.fields(iField).name = d.Attributes.name;
    if isfield(d,'Interval')
        s.fields(iField).interval.closure = d.Interval.Attributes.closure;
        s.fields(iField).interval.limits = [str2double(d.Interval.Attributes.leftMargin), ...
            str2double(d.Interval.Attributes.rightMargin)];
    elseif isfield(d,'Value')
        for iValue=1:numel(d.Value)
            s.fields(iField).value(iValue).value = d.Value{iValue}.Attributes.value;
        end
    end
end
end %iProcessDataDictionary

function s = iProcessMiningSchema(s, miningSchema)
assert(isfield(miningSchema,'MiningField'), 'Missing MiningField field in MiningSchema')
for iField=1:numel(miningSchema.MiningField)
    d = miningSchema.MiningField{iField};
    s.miningFields(iField).name = d.Attributes.name;
    s.miningFields(iField).type = d.Attributes.usageType;
end
end %iProcessMiningSchema

function s = iProcessOutput( s, output )
assert(isfield(output,'OutputField'), 'Missing OutputField field in Output')
if numel(output.OutputField)>1
    s.outputFields.name = output.OutputField{1}.Attributes.name;
else
    s.outputFields.name = output.OutputField.Attributes.name;
end
end %iProcessOutput

