classdef MPSParameterHandler
    %MPSParameterHandler Utility class to handle MPS parameters
    
     % Copyright 2020 MathWorks Inc.
     
    methods ( Static )
        function [c, conversionData] = table2Cell( tablePar )
            %table2Cell Converts a table into a cell and saves conversion
            %data so that table can be reconstructed.
            %categorical data is replaced by indices
            
            assert(istable(tablePar))
            c = table2cell(tablePar);
            conversionData.VariableNames = tablePar.Properties.VariableNames;
            
            % Save categories values
            iscat = varfun(@iscategorical,tablePar(1,:));
            conversionData.CatVars = iscat{1,:};
            cats = cellfun(@(x) categories(x),c(:,conversionData.CatVars),...
                'UniformOutput',false);
            conversionData.CatValues = cell(1,size(c,2));
            conversionData.CatValues(conversionData.CatVars) = cats;
            
            % Replace categories values by indices
            for jj=1:numel(c)
                if isa(c{jj},'categorical')
                    c{jj} = int64(c{jj});
                end
            end
        end
        
        function t = cell2Table( c , conversionData )
            %cell2Table Converts a cell into a table using the conversion
            %data provided
            
            t = cell2table(c);
            
            % Recover table properties from conversionData
            t.Properties.VariableNames = conversionData.VariableNames;
            % Recover categorical data
            catIndices = find(conversionData.CatVars);
            for ii=1:numel(catIndices)
                cindex = catIndices(ii);
                catVar = categorical(conversionData.CatValues{cindex});
                tconv = catVar(t{:,cindex});
                tt = table(tconv);
                tt.Properties.VariableNames = conversionData.VariableNames(cindex);
                if cindex==1
                    t = [tt,t(:,cindex+1:end)];
                elseif cindex<size(t,2)
                    t = [t(:,1:cindex-1),tt,t(:,cindex+1:end)];
                else
                    t = [t(:,1:cindex-1),tt];
                end
            end
        end %cell2table
    end %public static methods
end %classdef