# pmml
Export MATLAB machine learning models to the Predictive Modelling Markup Language (PMML) format.
Instantiate a PMML server using the MATLAB Production Server

## Examples
The following examples produce xml files in PMML format.

### Classification Decision Tree
```
load('fisheriris','meas','species')
data = array2table( meas, 'VariableNames', ...
    { 'sepal_length', 'sepal_width', 'petal_length', 'petal_width' } );
data.species = categorical( species );
tree = fitctree( data, 'species' );
writePMML( tree, 'fisheriris' )
type fisheriris.xml
```

### Linear Model
```
load('carbig','Acceleration','Displacement','Horsepower', ...
    'Weight','MPG')
tbl = table(Acceleration,Displacement,Horsepower,Weight,MPG);
mdl = fitlm(tbl,'linear','ResponseVar','MPG');
writePMML( mdl, 'carbig' )
type carbig.xml
```

### Credit Scorecard
```
load('CreditCardData','data')
sc = creditscorecard(data,'IDVar','CustID','GoodLabel', ...
    0,'ResponseVar','status');
sc = autobinning(sc,'Display','off');
[sc,mdl] = fitmodel(sc,'Display','Off');
writePMML( sc, 'CreditCard', mdl )
type CreditCard.xml
```
