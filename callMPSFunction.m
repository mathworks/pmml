function y = callMPSFunction( x , url, fname, nargsOut , silent )
%callMPSFuncion Invokes a MALAB function deployed in MPS
%url = ['http://mpsHost:mpsPort/ctfName/'];
if nargin<4
    nargsOut = 0;
end
if nargin<5
    silent = false;
end
if url(end)~='/'
    % if url not finished with separator add it
    url(end+1) = '/';
end
mpsURL = [url,fname];

startTime = tic;
if ~silent
    fprintf('Performing call to %s on MPS %s\n',fname, url)
end

data = mps.json.encoderequest(x,'nargout',nargsOut);
options = weboptions;
options.ContentType = 'text';
options.MediaType='application/json';
options.ArrayFormat = 'json';
options.Timeout = 20;
options.RequestMethod = 'post';

try
    r = webwrite(mpsURL,data,options);
    y = mps.json.decoderesponse(r);
catch e
    % Report any error that occurs while calling MPS
    y = {'Error:',e.message};
    fprintf('Error %s\n', e.message)
end
if ~silent
    fprintf('Called finished in %g secs\n',toc(startTime))
end
end %callMPSFunction