classdef PMMLCreditScorecardModel < pmml.PMMLModel
    %PMMLTreeModel PMML CreditScorecard regression models
    
    % Copyright 2018 MathWorks Inc.
    properties
        LModel
    end
    
    methods
        function obj = PMMLCreditScorecardModel( model , lmodel , name )
            if ~isa(model,'creditscorecard')
                error('PMMLCreditScorecardModel:BadInput', ...
                    'model must be a CreditScorecardModel object')
            end
            obj = obj@pmml.PMMLModel(model, name);
            obj.LModel = lmodel;
            
        end %constructor
        
        function addDataDictionary( obj )
            %addDataDictionary Adds the DataDictionary xml section
            obj.addDataDictionary_(obj.Model.Data);
        end %addDataDictionary
        
        function addMiningSchema( obj , treeModel )
            %addMiningSchema Adds the MiningSchema xml section
            miningSchema = obj.DocNode.createElement( 'MiningSchema' );
            mField = obj.DocNode.createElement( 'MiningField' );
            mField.setAttribute('name',obj.Model.ResponseVar);
            mField.setAttribute('usageType','predicted');
            miningSchema.appendChild(mField);
            for ii=1:numel(obj.Model.NumericPredictors)
                mField = obj.DocNode.createElement( 'MiningField' );
                mField.setAttribute('name',obj.Model.NumericPredictors(ii));
                mField.setAttribute('usageType','active');
                miningSchema.appendChild(mField);
            end
            for ii=1:numel(obj.Model.CategoricalPredictors)
                mField = obj.DocNode.createElement( 'MiningField' );
                mField.setAttribute('name',obj.Model.CategoricalPredictors(ii));
                mField.setAttribute('usageType','active');
                miningSchema.appendChild(mField);
            end
            treeModel.appendChild(miningSchema);
        end %addMiningSchema
        
        function addModel( obj )
            %addModel Adds the model xml section
            regModel = obj.DocNode.createElement( 'Scorecard' );
            regModel.setAttribute( 'modelName', 'example' );
            regModel.setAttribute( 'functionName', 'regression' );
            pmml = obj.DocNode.getDocumentElement;
            pmml.appendChild( regModel );
            
            obj.addMiningSchema(regModel )
            obj.addOutput(regModel);
            obj.addTargets(regModel);
            
        end %addModel
        
        function addOutput( obj , regModel)
            %addOutput Adds the output xml section
            output = obj.DocNode.createElement( 'Output' );
            
            oField = obj.DocNode.createElement( 'OutputField' );
            oField.setAttribute( 'name', obj.Model.ResponseVar )
            oField.setAttribute( 'feature','predictedValue' )
            oField.setAttribute( 'dataType','double' )
            output.appendChild(oField);
            
            regModel.appendChild(output);
        end %addOutput
        
        function value = evaluate( obj , data )
            assert(isa(data,'table'))
            assert(size(data,2)>=numel(obj.Model.PredictorVars))
            value = score( obj.Model , data );
        end %getScore
        
    end
    
    methods ( Access = private )
        function addTargets( obj , model )
            fPoints = obj.Model.displaypoints();
            rt = obj.DocNode.createElement( 'Characteristics' );
            %rt.setAttribute('initialScore',num2str(fPoints.BasePoints));
            
            % First do all numeric predictors
            for ii=2:size(obj.LModel.Coefficients,1)
                varName = obj.LModel.Coefficients.Row{ii};
                if ~ismember(varName,obj.Model.CategoricalPredictors)
                    ind = ismember(fPoints{:,1},varName);
                    t = fPoints(ind,:);
                    np1 = obj.DocNode.createElement( 'Characteristic' );
                    np1.setAttribute('name',t{1,1}{1});
                    % This information does not seem to be exposed so
                    % it is set to 0
                    np1.setAttribute('baselineScore', '0');
                    np1.setAttribute('reasonCode','RC1');
                    for jj=1:size(t,1)
                        np = obj.DocNode.createElement( 'Attribute' );
                        np.setAttribute('partialScore',num2str(t{jj,3}))
                        np2 = obj.DocNode.createElement( 'CompoundPredicate' );
                        np2.setAttribute('booleanOperator','and')
                        np.appendChild(np2);
                        iCreateBounds(t{jj,2}{1},varName,np2);
                        np.appendChild(np2);
                        np1.appendChild(np);
                        
                    end
                    rt.appendChild(np1);
                end
            end
            % Now do all categorical predictors
            for ii=2:size(obj.LModel.Coefficients,1)
                varName = obj.LModel.Coefficients.Row{ii};
                if ismember(varName,obj.Model.CategoricalPredictors)
                    ind = ismember(fPoints{:,1},varName);
                    t = fPoints(ind,:);
                    np1 = obj.DocNode.createElement( 'Characteristic' );
                    np1.setAttribute('name',t{1,1}{1});
                    % This information does not seem to be exposed so
                    % it is set to 0
                    np1.setAttribute('baselineScore', '0');
                    np1.setAttribute('reasonCode','RC1');
                    for jj=1:size(t,1)
                        np = obj.DocNode.createElement( 'Attribute' );
                        np.setAttribute('partialScore',num2str(t{jj,3}))
                        np2 = obj.DocNode.createElement( 'SimplePredicate' );
                        np2.setAttribute('field',varName)
                        np2.setAttribute('operator','equal')
                        np2.setAttribute('value',t{jj,2}{1})
                        np.appendChild(np2);
                        np1.appendChild(np);
                    end
                    
                    rt.appendChild(np1);
                end
            end
            model.appendChild( rt );
            
            function iCreateBounds( s , varName , parentNode )
                np3 = obj.DocNode.createElement( 'SimplePredicate' );
                np3.setAttribute('field',varName)
                commaPos = strfind(s,',');
                s1 = s(2:commaPos-1);
                if strcmp(s1,'-Inf')
                    s1 = '-1000000000000';
                end
                s2 = s(commaPos+1:end-1);
                if strcmp(s2,'Inf')
                    s2 = '1000000000000';
                end
                switch s(1)
                    case '['
                        np3.setAttribute('operator','greaterOrEqual')
                    case '('
                        np3.setAttribute('operator','greaterThan')
                end
                np3.setAttribute('value',s1)
                parentNode.appendChild(np3);
                
                np3 = obj.DocNode.createElement( 'SimplePredicate' );
                np3.setAttribute('field',varName)
                switch s(end)
                    case ']'
                        np3.setAttribute('operator','lessOrEqual')
                    case ')'
                        np3.setAttribute('operator','lessThan')
                end
                np3.setAttribute('value',s2)
                parentNode.appendChild(np3);
            end %iCreateBounds
            
        end %addRegTable
    end %protected methods
end %classdef


