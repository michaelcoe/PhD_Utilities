%imports data from test file delimited by tabs and puts into a struct

function data = importTXTFile(filename)
    M = dlmread(filename);
    
    data = struct();
    
    data.m1 = M(:,1);
    data.m2 = M(:,2);
    data.m3 = M(:,3);
    data.m4 = M(:,4);
    
    samples = length(data.m1);
    
    dt = 1/(100*10^3);
    
    data.times = (1:samples)'*dt;
    
    disp(['Got ', num2str(samples), ' samples'])
end