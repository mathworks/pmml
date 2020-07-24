classdef PMMLCompactCreditScorecard
    
    % Copyright 2020 The MathWorks, Inc.
    properties
        NumericPredictors
        CategoricalPredictors
        PredictorVars
        PMMLStruct
        ResponseVar
    end
    
    methods
        function obj = PMMLCompactCreditScorecard( s )
            obj.PMMLStruct = s;
            obj.ResponseVar = s.outputFields.name;
            % extract predictor names
            predNames = {s.characteristics.name};
            % detect categorical predictors
            catInd = ismember({s.fields.optype},'categorical');
            varNames = {s.fields.name};
            catNames = varNames(catInd);
            ind = ismember(predNames,catNames);
            predCategNames = predNames(ind);
            indNum = ismember(s.predvarTypes,'double');
            numericNames =  predNames(indNum);
            
            obj.NumericPredictors = numericNames;
            obj.CategoricalPredictors = predCategNames;
            obj.PredictorVars = predNames;
            
        end %constructor
        
        function [Scores,Points] = score(obj,dataToScore)
            score = 0;
            for ii=1:numel(obj.PMMLStruct.characteristics)
                varName = obj.PMMLStruct.varMap{ii};
                varType = obj.PMMLStruct.predvarTypes{ii};
                c = obj.PMMLStruct.characteristics(ii);
                for jj=1:numel(c.attribute)
                    a = c.attribute(jj);
                    if isempty(a.predicate)
                        continue
                    end
                    value = dataToScore(1,varName);
                    switch varType
                        case 'double'
                            contained = iCheckContained(a.predicate(1), value);
                            if contained && numel(a.predicate)>1
                                contained = iCheckContained(a.predicate(2), value);
                            end
                            if contained
                                if ~isfield(a,'ComplexPartialScore') || isempty(a.ComplexPartialScore)
                                    score = score + a.partialScore;
                                else
                                    score = score + iGetComplexScore( ...
                                        a.ComplexPartialScore.Apply,dataToScore, obj.PMMLStruct.varMap);
                                end
                            end
                        case 'string'
                            contained = iCheckContainedString(a.predicate(1), value);
                            if contained
                                score = score + a.partialScore;
                            end
                        otherwise
                            error('PMMLCompactCreditScorecard:score', ...
                                'Case %s not implemented',varType)
                    end
                end
            end
            Scores = score;
            Points = [];
        end %score
    end %public methods
end %class  PMMLCompactCreditScorecard

function contained = iCheckContained(predicate, value)
if isfield(predicate,'value')
    predValue = str2double(predicate.value);
elseif strcmp(predicate.operator,'isMissing')
    contained = isempty(value);
    return
else
    error('PMMLCompactCreditScorecard:iCheckContainedString', ...
        'Inconsistent entry')
end
value = value{1,1};
switch predicate.operator
    case 'lessThan'
        contained = value < predValue;
    case 'lessOrEqual'
        contained = value <= predValue;
    case 'greaterThan'
        contained = value > predValue;
    case 'greaterOrEqual'
        contained = value >= predValue;
    otherwise
        error('PMMLCompactCreditScorecard:iCheckContained', ...
            'Case %s not implemented',predicate.operator)
end
end %iCheckContained

function contained = iCheckContainedString(predicate, value)
if isfield(predicate,'value')
    predValue = predicate.value;
elseif strcmp(predicate.operator,'isMissing')
    contained = isempty(value);
    return
else
    error('PMMLCompactCreditScorecard:iCheckContainedString', ...
        'Inconsistent entry')
end

value = value{1,1};
switch predicate.operator
    case 'equal'
        contained = strcmp(string(value), predValue);
    otherwise
        error('PMMLCompactCreditScorecard:iCheckContainedString', ...
            'Case %s not implemented',predicate.operator)
end
end %iCheckContainedString

function score = iGetComplexScore( a , data, varMap)
if isfield(a,'Apply')
    score = iGetComplexScore(a.Apply, data, varMap);
    value = str2double(a.Constant.Text);
else
    varName = a.FieldRef.Attributes.field;
    indVar = ismember(varMap(:),varName);
    refValue = data{1,indVar};
    value = str2double(a.Constant.Text);
end

switch a.Attributes.function
    case '-'
        score = score - value;
    case '+'
        score = score + value;
    case '*'
        score = refValue * value;
    otherwise
        error('PMMLCompactCreditScorecard:iGetComplexScore', ...
            'Case %s not implemented',a.Attributes.function)
end
end %iGetComplexScore
