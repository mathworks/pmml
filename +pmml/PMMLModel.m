classdef PMMLModel
    %PMMLModel Base class for PMML models
    
    % Copyright 2018 MathWorks Inc.
    properties ( SetAccess = private )
        DocNode
        PMML
        Model
        Name
    end
    
    methods ( Abstract )
        addDataDictionary( obj )
        addModel( obj )
        value = evaluate( obj , data )
    end %abstract methods
    
    methods
        function obj = PMMLModel( model, name )
            %constructor
            obj.Model = model;
            obj.Name = name;
        end %constructor
        
        function writePMML( obj , fileName )
            %writePMML Creates PMML file
            if nargin<2 || ~ischar(fileName)
                error('PMMLModel:BadArg', ...
                    'Argument must be a file name')
            end
            fid = fopen(fileName,'w');
            if fid==-1
                error('PMMLModel:OutError', ...
                    'Could not open %s for output',fileName)
            end
            fprintf(fid,'%c',obj.PMML);
            fclose(fid);
        end %writePMML
        
        function pmml = get.PMML( obj )
            if isempty(obj.PMML)
                obj = obj.createPMML;
            end
            pmml = obj.PMML;
        end %get.PMML
    end
    
    methods ( Static )
        function modelObj = createPMMLModel( mlmodel , name , lmodel)
            %createPMMLModel Returns a PMML model
            if nargin<3
                lmodel = [];
            end
            if ~ischar(name)
                error('createPMMLModel:BadParam','Parameter 2 must be a char array')
            end
            switch class(mlmodel)
                case 'LinearModel'
                    modelObj = pmml.PMMLLinearModel( mlmodel, name );
                case 'ClassificationTree'
                    modelObj = pmml.PMMLTreeModel( mlmodel, name );
                case 'creditscorecard'
                    modelObj = pmml.PMMLCreditScorecardModel( mlmodel, lmodel , name );
                otherwise
                    error('createPMMLModel:NotImpl','Model %s not implemented', ...
                        class(mlmodel))
            end
end %createPMMLModel
    end %public static methods
    
    methods ( Access = protected )
        function addDataDictionary_( obj , data )
            %addDataDictionary Adds the DataDictionary xml section
            docNode = obj.DocNode;
            dataDictionary = docNode.createElement( 'DataDictionary' );
            dataDictionary.setAttribute( 'numberOfFields', num2str( width( data ) ) );
            for n = 1:width( data )
                dataField = docNode.createElement( 'DataField' );
                dataField.setAttribute( 'name', data.Properties.VariableNames{n} );
                if isnumeric( data{:,n} )
                    dataField.setAttribute( 'dataType', class( data{:,n} ) );
                    dataField.setAttribute( 'optype', 'continuous' );
                    interval = docNode.createElement( 'Interval' );
                    interval.setAttribute( 'closure', 'closedClosed' );
                    interval.setAttribute( 'leftMargin', num2str( min( data{:,n} ) ) );
                    interval.setAttribute( 'rightMargin', num2str( max( data{:,n} ) ) );
                    dataField.appendChild( interval );
                elseif iscategorical( data{:,n} )
                    dataField.setAttribute( 'optype', 'categorical' );
                    dataField.setAttribute( 'dataType', 'string' );
                    categories = unique( data{:,n} );
                    for c = 1:length( categories )
                        value = docNode.createElement( 'Value' );
                        value.setAttribute( 'value', char( categories(c) ) );
                        dataField.appendChild( value );
                    end
                end
                dataDictionary.appendChild( dataField );
            end
            pmml = obj.DocNode.getDocumentElement;
            pmml.appendChild( dataDictionary );        
        end %addDataDictionary_
        
        function addHeader( obj )
            header = obj.DocNode.createElement( 'Header' );
            pmml = obj.DocNode.getDocumentElement;
            pmml.appendChild(header);
            
        end %addHeader
                
        function obj = createPMML( obj )
            obj.DocNode = com.mathworks.xml.XMLUtils.createDocument('PMML');
            obj.addHeader( );
            obj.addDataDictionary();
            obj.addModel();
            obj.PMML = xmlwrite( obj.DocNode );
            
        end %createPMML
    end
end