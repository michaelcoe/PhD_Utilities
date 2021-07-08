% by Andrew Pullin
%
% v.beta
%
% Revisions:
%  Andrew Pullin   2012-7-30   Initial release
%
% Notes:
%   
% Usage:
%   S = importOTdata('file.csv');
%   Returned a structure parsing of the content of the OptiTrack CSV file.

function [ S ] = importOTdata( FILENAME )
%importOTdata Import data from OptiTrack CSV output file
%   This function will import data from an OptiTrack CSV file and return a
%   structure that contains all the information on frames, trackables,
%   positions, etc that is given in the file.
%  Author 

S = []; %Blank placeholder in case of file open failure

%Safe file open
fid = fopen(FILENAME);
if fid==-1
    disp(['Cannot find ' FILENAME]);
    return;
end

%% read entire file into cell array
A = textscan(fid,'%[^\n]');

%% find comment lines
temp          = regexp(A{1},'^comment,"=*\s*(.*)"','tokens','once');
contentidx    = cellfun(@isempty,temp);
tempcomm      = temp(~contentidx);
S.Comments    = vertcat(tempcomm{:});

%% Find content lines
content  = A{1}(contentidx);

%% determine handedness
temp = regexp(content,'^(\w*)handed','tokens','once');
temp = [temp{:}];
S.Handedness = temp{1};

%% retrieve "info" and generate field names (in case they change or something)
temp = regexp(content,'^info,(\w*),(\d*)','tokens','once');
temp = vertcat(temp{:});

S.FrameCount     = str2double(temp{1,2});
S.EnumTrackableCount = str2double(temp{2,2});

%% rigid body definitions
temp = regexp(content,'^trackable,"(.*)",(\d*),(\d*),(.*)','tokens','once');
temp = vertcat(temp{:});
S.NumRigidBody = size(temp,1);

%% set up RigidBodies structure array and populate it
% RigidBodies is the configuration description of each body that might
% appear in the data in the rest of the file.
S.RigidBody = repmat(struct(...
    'Name',             '', ...
    'ID',               [], ...
    'MarkerCount',      [], ...
    'MarkerPositions',  []), [S.NumRigidBody,1]);

convstrcell2numcell = @(x){str2double(x)};
cellstr2num =         @(x)str2num(x);                           %#ok<ST2NM>
reshapeXYZ =          @(x)reshape(x,3,[])';
fixnan =         @(x)regexprep(x,'NAN','NaN'); 

Names        = temp(:,1);
IDs          = temp(:,2);
MarkerCount = temp(:,3);
MarkerPosition = temp(:,4);

[S.RigidBody.Name] = deal(Names{:});

tempid           = cellfun(convstrcell2numcell, IDs);
[S.RigidBody.ID] = deal(tempid{:});

tempmk                    = cellfun(convstrcell2numcell, MarkerCount);
[S.RigidBody.MarkerCount] = deal(tempmk{:});

tempMarkerPosition           = cellfun(cellstr2num, MarkerPosition,    'UniformOutput', false);
tempMarkerPosition           = cellfun(reshapeXYZ,  tempMarkerPosition, 'UniformOutput', false);
[S.RigidBody.MarkerPosition] = deal(tempMarkerPosition{:});

%% set up frame structure array and populate it
S.Frame = repmat(struct(          ...
    'FrameIndex',         [],     ...
    'Timestamp',          [],     ...
    'TrackableCount',     '',     ...
    'Trackables',         [],     ...
    'MarkerCount',        [],     ...
    'MarkerData',         [],     ...
    'MarkerIDs',        []), [S.FrameCount,1]);

%% locate frame info
temp = regexp(content,'^frame,(\d*),([-\d.]*),(\d*),(.*)','tokens','once');
temp = vertcat(temp{:});

FrameIndices = temp(:,1);
Timestamps   = temp(:,2);
TrackCounts  = temp(:,3);
rest         = temp(:,4);

tempind      = cellfun(convstrcell2numcell, FrameIndices);
[S.Frame.FrameIndex] = deal(tempind{:});

temptime             = cellfun(convstrcell2numcell, Timestamps);
[S.Frame.Timestamp]  = deal(temptime{:});

tempcount            = cellfun(convstrcell2numcell, TrackCounts);
[S.Frame.TrackableCount] = deal(tempcount{:});

%Handle dynamic data on 'trackable' lines
rest = cellfun(fixnan, rest,'UniformOutput',false); %Convert NAN to NaN
trackableDynData  = cellfun(cellstr2num, rest,    'UniformOutput', false);

for i = 1:length(trackableDynData)
    %One sub structure for every trackable in this frame
    S.Frame(i).Trackables = repmat(struct(          ...
    'ID',         [],     ...
    'Position',          [],     ...
    'Quaternion',     '',     ...
    'Euler',         []), [S.Frame(i).TrackableCount,1]);

    item = trackableDynData{i}; 
    idx = 1;
    for j = 1:S.Frame(i).TrackableCount
        S.Frame(i).Trackables(j).ID = item(idx);
        S.Frame(i).Trackables(j).Position = item(idx+1:idx+3); % X,Y,Z
        S.Frame(i).Trackables(j).Quaternion = item(idx+4:idx+7); %
        S.Frame(i).Trackables(j).Euler = item(idx+8:idx+10); %
        idx = idx + 11;
    end

    markCount = item(idx);
    idx = idx + 1;
    markdata = item(idx:idx - 1 + 4*markCount); %4, includes marker ID here
    markdata = reshape(markdata, 4 , [])'; %4, includes marker ID here
    markids = markdata(:,end);
    markdata = markdata(:,1:3); %just position information
    %Store
    S.Frame(i).MarkerCount = markCount;
    S.Frame(i).MarkerData = markdata;
    S.Frame(i).MarkerIDs = markids;
end

%% locate trackables recorded data from 'trackables' lines
temp = regexp(content,'^trackable,(\d*),([-\d.]*),"(.*)",(\d*),(\d*),(\d*),(.*)','tokens','once');
temp = vertcat(temp{:});


rest = temp(:,7);
rest = cellfun(fixnan, rest,'UniformOutput',false); %Convert NAN to NaN
trackableDynData           = cellfun(cellstr2num, rest,    'UniformOutput', false);

%Take static numbers from start of lines
FrameIndices = temp(:,1);
Timestamps = temp(:,2);
Names = temp(:,3);
IDs = temp(:,4);
FramesSinceLastTracked = temp(:,5);
MarkerCount = temp(:,6);

%Temporary struct array, one element for each 'trackable' line in the file
temptrackables = repmat(struct(          ...
    'FrameIndex',         [],     ...
    'Timestamp',            [],     ...
    'Name',             '', ...
    'ID',               [], ...
    'FramesSinceLastTracked',     [],     ...
    'MarkerCount',           [],...
    'PointCloud',     [],...
    'MarkerTracked',         [],...
    'MarkerQuality',         [],...
    'MeanError',             []), [length(temp),1]);

tempind      = cellfun(convstrcell2numcell, FrameIndices);
[temptrackables.FrameIndex] = deal(tempind{:});
temptime      = cellfun(convstrcell2numcell, Timestamps);
[temptrackables.Timestamp] = deal(temptime{:});
[temptrackables.Name] = deal(Names{:});
tempid           = cellfun(convstrcell2numcell, IDs);
[temptrackables.ID] = deal(tempid{:});
tempfslt      = cellfun(convstrcell2numcell, FramesSinceLastTracked);
[temptrackables.FramesSinceLastTracked] = deal(tempfslt{:});
tempcount     = cellfun(convstrcell2numcell, MarkerCount);
[temptrackables.MarkerCount] = deal(tempcount{:});

%Handle dynamic data on 'trackable' lines
for i = 1:length(trackableDynData)
    item = trackableDynData{i};
    idx = 1;
    markdata = item(idx:idx - 1 + 3*temptrackables(i).MarkerCount);
    markdata = reshape(markdata, 3, [])';
    idx = idx + 3*temptrackables(i).MarkerCount;
    pointCloud = item(idx:(idx - 1 + 3*temptrackables(i).MarkerCount));
    idx = idx + 3*temptrackables(i).MarkerCount;
    markTracked = item(idx:idx - 1 + temptrackables(i).MarkerCount);
    idx = idx + temptrackables(i).MarkerCount;
    markQuality = item(idx:idx - 1 + temptrackables(i).MarkerCount);
    idx = idx + temptrackables(i).MarkerCount;
    meanErr = item(idx);
    %Store
    temptrackables(i).MarkerData = markdata;
    temptrackables(i).PointCloud = pointCloud;
    temptrackables(i).MarkerTracked = markTracked;
    temptrackables(i).MarkerQuality = markQuality;
    temptrackables(i).MeanErr = meanErr;
end

%% Build the Trackables field, with one entry per trackable
S.Trackables = repmat(struct(          ...
    'FramesPresent',         [],     ...
    'TrackedTimestamps',    [],     ...
    'Name',             '', ...
    'ID',               [], ...
    'FramesSinceLastTracked',     [],     ...
    'MarkerCount',           [],...
    'MarkerLocations',       [],...
    'PointCloudMarkers',     [],...
    'MarkerTracked',         [],...
    'MarkerQuality',         [],...
    'MeanError',             [],...
    'Position',              [],...
    'Quaternion',            [],...
    'Euler',                 []), [S.NumRigidBody,1]);

uniqueIDs = vertcat(S.RigidBody.ID);

for i=1:S.NumRigidBody
    id = uniqueIDs(i);
    thistr = temptrackables(vertcat(temptrackables.ID) == id);
    S.Trackables(i).Name = thistr(1).Name; %should be same across all
    S.Trackables(i).ID = id;
	%Traverse Frame structure to find all frames in which this ID is
	%present
    fp = zeros(length(S.Frame),1);
    for k = 1:length(S.Frame)
        for n = 1:length(S.Frame(k).Trackables)
            if S.Frame(k).Trackables(n).ID == id
                fp(k) = 1;
            end
        end
    end
    S.Trackables(i).FramesPresent = find(fp); %frames index from 0!
    S.Trackables(i).TrackedTimestamps = vertcat(S.Frame(logical(fp)).Timestamp);
    S.Trackables(i).FramesSinceLastTracked = vertcat(thistr.FramesSinceLastTracked);
    S.Trackables(i).MarkerCount = vertcat(thistr.MarkerCount);
    S.Trackables(i).MarkerLocations = cat(3,thistr.MarkerData,[]);
    S.Trackables(i).PointCloudMarkers = cat(3,thistr.PointCloud,[]);
    S.Trackables(i).MarkerTracked = cat(3,thistr.MarkerTracked,[]);
    S.Trackables(i).MarkerQuality = cat(3,thistr.MarkerQuality,[]);
    S.Trackables(i).MeanError = vertcat(thistr.MeanError);
    
    %Copy position,quat,rotation data for convenience
    dataframes =  S.Frame((S.Trackables(i).FramesPresent)'); %frames index from 0!
    temptr = vertcat(dataframes.Trackables);
    temptr = temptr(vertcat(temptr.ID) == id); %Pick out only this ID
    S.Trackables(i).Position = vertcat(temptr.Position);
    S.Trackables(i).Quaternion = vertcat(temptr.Quaternion);
    S.Trackables(i).Euler = vertcat(temptr.Euler);
end



end %of function