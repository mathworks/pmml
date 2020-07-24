classdef PMMLLinearModel < pmml.PMMLModel
    %PMMLTreeModel PMML Linear regression models
    
    % Copyright 2018 MathWorks Inc.
    methods
        function obj = PMMLLinearModel( model , name )
            if ~isa(model,'LinearModel')
                error('PMMLLinearModel:BadInput', ...
                    'model must be a LinearModel object')
            end
            obj = obj@pmml.PMMLModel(model, [], name);
        end %constructor
        
        function addDataDictionary( obj )
            %addDataDictionary Adds the DataDictionary xml section
            obj.addDataDictionary_(obj.Model.Variables);
        end %addDataDictionary
        
        function addMiningSchema( obj , treeModel )
            %addMiningSchema Adds the MiningSchema xml section
            miningSchema = obj.DocNode.createElement( 'MiningSchema' );
            mField = obj.DocNode.createElement( 'MiningField' );
            mField.setAttribute('name',obj.Model.ResponseName);
            mField.setAttribute('usageType','predicted');
            miningSchema.appendChild(mField);
            for ii=1:numel(obj.Model.PredictorNames)
                mField = obj.DocNode.createElement( 'MiningField' );
                mField.setAttribute('name',obj.Model.PredictorNames(ii));
                mField.setAttribute('usageType','active');
                miningSchema.appendChild(mField);
            end
            treeModel.appendChild(miningSchema);
        end %addMiningSchema
        
        function addModel( obj )
            %addModel Adds the model xml section
            regModel = obj.DocNode.createElement( 'RegressionModel' );
            regModel.setAttribute( 'modelName', 'example' );
            regModel.setAttribute( 'functionName', 'regression' );
            regModel.setAttribute( 'algorithmName', 'least squares' );
            pmml = obj.DocNode.getDocumentElement;
            pmml.appendChild( regModel );
            
            obj.addMiningSchema(regModel )
            obj.addOutput(regModel);
            obj.addRegTable(regModel);
            
        end %addModel
        
        function addOutput( obj , regModel)
            %addOutput Adds the output xml section
            output = obj.DocNode.createElement( 'Output' );
 
            oField = obj.DocNode.createElement( 'OutputField' );
            oField.setAttribute( 'name', obj.Model.ResponseName )
            oField.setAttribute( 'feature','predictedValue' )
            oField.setAttribute( 'dataType','double' )
            output.appendChild(oField);
            
            regModel.appendChild(output);
        end %addOutput
        
        function value = evaluate( obj , data )
            assert(isa(data,'dataset') || isa(data,'table') || isa(data,'double'))
            assert(size(data,2)>=obj.Model.NumPredictors)
            value = predict( obj.Model , data );
        end %getScore
        
    end
    
    methods ( Access = private )
        function addRegTable( obj , model )
            rt = obj.DocNode.createElement( 'RegressionTable' );
            rt.setAttribute('intercept', ...
                num2str(obj.Model.Coefficients{'(Intercept)',1}))
            for ii=2:size(obj.Model.Coefficients,1)
                np = obj.DocNode.createElement( 'NumericPredictor' );
                np.setAttribute('name',obj.Model.CoefficientNames{ii})
                np.setAttribute('exponent','1')
                np.setAttribute('coefficient', ...
                    num2str(obj.Model.Coefficients{ii,1}))
                rt.appendChild(np);
            end
            model.appendChild( rt );
        end %addRegTable
    end %protected methods
end %classdef


