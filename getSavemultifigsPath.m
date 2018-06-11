function r = getSavemultifigsPath()
% Return the path where savemultfigs.m is.
   w = which('savemultfigs.m','-all');
   if numel(w) == 0
      error('Could not find savemultfigs.m. Cannot determine BRCMRootPath');
   elseif numel(w)>1
      warning('Found too many savemultfigs.m. Use the first to determine savemultfigs Path');
      disp(w)
      w = w(1);
   end
   r = fileparts(w{1});
   
end
