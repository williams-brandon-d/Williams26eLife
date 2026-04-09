function PVlabels = getPVlabels(dataPath,selectTraceIdx)
% add PV labels based on IHC registration

nSelected = numel(selectTraceIdx);
PVlabels = zeros(nSelected,1);
fovPath = fileparts(dataPath);
switch fovPath
    case 'D:\chr2-voltron-27\s2\fov2'
        PVidx = [62 65]; % changed 7/9 to 65
    case 'D:\02-08-2024 ChR2-Voltron-23\s1\fov3'
        PVidx = [3 6];
    case 'D:\02-21-2024 ChR2-Voltron-25\s1'
        PVidx = 47;
    otherwise
        PVidx = [];
end
PVlabels(PVidx) = 1;


end