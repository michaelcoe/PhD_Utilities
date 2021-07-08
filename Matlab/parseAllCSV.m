% parses all CSV OptiTrack files in a directory

%Parses all CSV files in directory

files = dir('*.csv');
numfiles = length(files);

for n=1:numfiles
    disp(['Importing ' files(n).name]);
    DATA(n) = importOTdata(files(n).name);
end