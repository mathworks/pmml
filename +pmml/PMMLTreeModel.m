classdef PMMLTreeModel < pmml.PMMLModel
    %PMMLTreeModel PMML Classification Tree models
    
    % Copyright 2018 MathWorks Inc.
    methods
        function obj = PMMLTreeModel( model , name )
            if ~isa(model,'ClassificationTree')
                error('PMMLTreeModel:BadInput', ...
                    'model must be a ClassificationTree object')
            end
            obj = obj@pmml.PMMLModel(model, [], name);
        end %constructor
        
        function addDataDictionary( obj )
            %addDataDictionary Adds the DataDictionary xml section
            data = [obj.Model.X,table(obj.Model.Y)];
            data.Properties.VariableNames{end} = obj.Model.ResponseName;
            obj.addDataDictionary_(data);
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
            treeModel = obj.DocNode.createElement( 'TreeModel' );
            treeModel.setAttribute( 'modelName', 'example' );
            treeModel.setAttribute( 'functionName', 'classification' );
            treeModel.setAttribute( 'splitCharacteristic', 'binarySplit' );
            pmml = obj.DocNode.getDocumentElement;
            pmml.appendChild( treeModel );
            
            obj.addMiningSchema(treeModel )
            obj.addOutput(treeModel);
            iAppendTreeNodes( obj.Model, obj.DocNode, treeModel, 1 );
            
        end %addModel
        
        function addOutput( obj , treeModel)
            %addOutput Adds the output xml section
            output = obj.DocNode.createElement( 'Output' );
            for ii=1:numel(obj.Model.ClassNames)
                oField = obj.DocNode.createElement( 'OutputField' );
                oField.setAttribute( 'name', ...
                    ['Probability_',char(obj.Model.ClassNames(ii))] )
                oField.setAttribute( 'optype','continuous' )
                oField.setAttribute( 'dataType','double' )
                oField.setAttribute( 'value',char(obj.Model.ClassNames(ii))  )
                oField.setAttribute( 'feature','probability' )
                output.appendChild(oField);
            end
            oField = obj.DocNode.createElement( 'OutputField' );
            oField.setAttribute( 'name', 'Node_Id' )
            oField.setAttribute( 'optype','categorical' )
            oField.setAttribute( 'dataType','string' )
            oField.setAttribute( 'feature','entityId' )
            output.appendChild(oField);
            treeModel.appendChild(output);
        end %addOutput
        
        function value = evaluate( obj , data )
            assert(isa(data,'dataset') || isa(data,'table') || isa(data,'double'))
            assert(size(data,2)>=numel(obj.Model.PredictorNames))
            value = predict( obj.Model , data );
        end %getScore
    end
end %classdef

function newNode = iAppendTreeNodes( tree, docNode, currNode, id , simplePredicate)

if nargin<5
    simplePredicate = [];
end

newNode = docNode.createElement( 'Node' );
newNode.setAttribute( 'id', num2str(id) );
newNode.setAttribute( 'score', tree.NodeClass(id) );
newNode.setAttribute( 'recordCount', num2str( sum( tree.ClassCount(id,: ) ) ) );

% Score distributions
if ~isempty(simplePredicate)
    newNode.appendChild( simplePredicate );
else
    trueNode = docNode.createElement( 'True' );
    newNode.appendChild( trueNode );
end
for n = 1:size( tree.ClassCount, 2 )
    scoreDistribution = docNode.createElement( 'ScoreDistribution' );
    scoreDistribution.setAttribute( 'value', char( tree.ClassNames(n) ) );
    scoreDistribution.setAttribute( 'recordCount', num2str( tree.ClassCount(id,n) ) );
    scoreDistribution.setAttribute( 'confidence', num2str( tree.ClassProbability(id,n) ) );
    newNode.appendChild( scoreDistribution );
end

currNode.appendChild( newNode );

if tree.Children( id, 1 ) > 0
    
    % Cut point
    if ~isnan( tree.CutPoint( id ) )
        simplePredicate = docNode.createElement( 'SimplePredicate' );
        simplePredicate.setAttribute( 'field', tree.CutPredictor(id) );
        simplePredicate.setAttribute( 'operator', 'lessThan' );
        simplePredicate.setAttribute( 'value', num2str( tree.CutPoint(id) ) );
    else
        simplePredicate = [];
    end
    %addedNode.appendChild( simplePredicate );
    iAppendTreeNodes( tree, docNode, newNode, tree.Children( id, 1 ) , simplePredicate);
end
if tree.Children( id, 2 ) > 0
    % Cut point
    if ~isnan( tree.CutPoint( id ) )
        simplePredicate = docNode.createElement( 'SimplePredicate' );
        simplePredicate.setAttribute( 'field', tree.CutPredictor(id) );
        simplePredicate.setAttribute( 'operator', 'greaterOrEqual' );
        simplePredicate.setAttribute( 'value', num2str( tree.CutPoint(id) ) );
    else
        simplePredicate = [];
    end
    %addedNode.appendChild( simplePredicate );
        iAppendTreeNodes( tree, docNode, newNode, tree.Children( id, 2 ) , simplePredicate );

end
end
