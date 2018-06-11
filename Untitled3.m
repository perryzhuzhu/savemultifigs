figs_libpath = mfilename('fullpath');
ini = IniConfig();



SavemultifigsPath = getSavemultifigsPath();
CfgDefaultPath = fullfile(SavemultifigsPath,'figs_config.ini')
CfgCurrentPath = fullfile(pwd,'figs_config.ini')

if exist(CfgCurrentPath,'file')
    mfilename('fullpath')
end