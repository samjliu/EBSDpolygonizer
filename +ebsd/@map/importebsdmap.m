function [emap,grains] = importebsdmap(dotsfile, grainfile, crcfile)
    % IMPORTEBSDMAP import EBSD data from two input files. 
    % dotsfile --- HKL EBSD data for each pixels and their corresponding grain ID
    % grainfile --- HKL data for each grains
    % These two files must be exported from Tango in the HKL-Channel 5 software
    % package by the following procedures:
    %   * Detect grains
    %   * In the Grain Detectiong window, right click the table and in the
    %   dropdown menu> 
    %       ** Export Grain List > To file. --- dotsfile
    %       ** Export All Cell > To file. --- grain file
    % 
    % This function compile a standard workflow to generate a
    % ebsd.map. 
    
    if nargin == 0
        [crcfilename,crcfilepath] = uigetfile('*.cpr', 'Select HKL project file');
        crcfile = [crcfilepath, crcfilename];
        [dotfilename,dotfilepath] = uigetfile('*.txt','Select the exported pixel data file');
        dotsfile = [dotfilepath, dotfilename];
        [grfilename,grfilepath] = uigetfile('*.txt','Select the exported grain data file');
        grainfile = [grfilepath, grfilename];
        whattype = input('Is it an AZtec or HKL file? Type 0 or 1: \n [0] -- AZtec, \n [1] -- HKL \n ');
        if isempty(whattype)
            isAztec = true;
        elseif whattype == 0
            isAztec = ~whattype;
        else
            isAztec = false;
        end
    end
    disp('Please waiting when the EBSDMAP is being created, if you have already EBSDGRAIN data, use ebsdmap(grainobj) to create the map');
%     h = waitbar(0, msgstart);
%     disp(['Start creating ebsd.map. ', msgstart]);
%     if nargin == 3
%         dots = ebsd.pixcell.importHKL(dotsfile, stepsize);
%     else
%         dots = ebsd.pixcell.importHKL(dotsfile);
%     end
    ebsdpara = ebsd.map.importCRCfile(crcfile);
    stepsize = ebsdpara.xStepSize;
    if isAztec
        dots = ebsd.pixcell.importAZTec(dotsfile, stepsize);
    else
        dots = ebsd.pixcell.importHKL(dotsfile, stepsize);
    end
    disp('EBSDDOT data created');
    if isAztec
        grains = ebsd.grain.importAztexGrains(grainfile);
    else
        grains = ebsd.grain.importHKLgrains(grainfile);
    end
    disp('grain data has been imported, assigning EBSDDOT data to each grains...');
    grains.claimownership(dots);
    disp('EBSDDOT data have been assigned to each grains. I am polygonizing grains, which may take a while...');
    grains.polygonize(dots,ebsdpara);
    disp('Grains have been polygonized and I am creating EBSDMAP...')
    emap = ebsd.map(grains);
    emap.pixels = dots;
    emap.stepsize = stepsize;
    emap.numXCells = ebsdpara.numXCells;
    emap.numYCells = ebsdpara.numYCells;
    emap.ebsdInfoTable = ebsdpara.allEBSDinfo;
    emap.CS1toCS0 = ebsdpara.CS1toCS0;
    disp('EBSD map created. I am checking the neighbours of each grains...');
%     d = input('What is the buffersize for checking neighbours [default=0.1*stepsize]: ');
%     if isempty(d)
%         d = stepsize*0.1;
%     end
    emap.grains.findneighbours(0.2*stepsize); 
    disp('I am searching and creating gb grain boundaries...')
    emap.findgbs;
    disp('I am about to finish and doing some finishing touches...')
    
    % Add the missing vertices that are not captured in merging processes
    emap.addMissingVertices(stepsize*0.2);
    emap.findEdgeVertices;
    disp('EBSDMAP has been created using the imported data and ready for further processing including smoothing and downsize the number of vertices!')
end