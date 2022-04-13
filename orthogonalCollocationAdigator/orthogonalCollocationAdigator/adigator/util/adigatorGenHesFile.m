function output = adigatorGenHesFile(UserFunName,UserFunInputs,varargin)
% ADiGator Hessian File Generation Function: this function is used when you
% wish to generate a Hessian+gradient of a function with an input variable
% of differentiation (and any auxiliary inputs), and a single output. This
% simply calls the function adigator twice and creates a wrapper function
% s.t. the input of the resulting file is the same as the input to the
% original user function, but outputs the Hessian, gradient, and function
% values.
%
% ------------------------------ Usage -----------------------------------
% function adigatorGenHesFile(UserFunName,UserFunInputs)
%                   or
% function adigatorGenHesFile(UserFunName,UserFunInputs,Options)
%
% ------------------------ Input Information -----------------------------
% UserFunName: String name of the user function to be differentiated
%
% UserFunInputs: N x 1 cell array containing the inputs to the UserFun
%                - the input (or cell array element/structure field)
%                corresponding to the variable of differentiation must be
%                created using the adigatorCreateDerivInput function.
%                i.e. if the first input is the variable of
%                differentiation, then the first input must be created
%                using adigatorCreateDerivInput prior to calling adigator.
%                - any other numeric inputs should be defined as they will
%                be when calling the derivative function. These will be
%                assumed to have fixed sizes and zero locations, but the
%                non-zero locations may change values. If the values are
%                always fixed, then adigatorOptions may be used to change
%                the handling of these auxiliary inputs.
%                - auxiliary inputs may also be created using the
%                adigatorCreateAuxInput function.
%
% Options (optional): option structure generated by adigatorOptions
%                     function
%
% ------------------------ Output Information ----------------------------
% The output is a structure of the names of the files that are generated,
% together with the original function name and the Hessian sparsity
% pattern. If the user's function is called 'myfun', then the Hessian file
% will be titled 'myfun_Hes', and the gradient file will be titled
% 'myfun_Grd'. The output structure would then be
%     output.FunctionFile = 'myfun'
%     output.GradientFile = 'myfun_Grd'
%     output.HessianFile  = 'myfun_Hes'
%     output.HessianStructure = sparse ones and zeros.
% The generated Hessian/gradient files have the same input structure as the
% original user function. The output of Hessian file is [Hes, Grd, Fun].
% The output of gradient file is [Grd, Fun].
%
% ----------------------- Additional Information -------------------------
% The Hessian is built as a sparse matrix under the condition that
% numel(Hes) >= 250 & nnz(Hes)/numel(Hes) <= 3/4, otherwise it is built as
% a full matrix.
%
% If y is output, x is input such that numel(y) = m,
% numel(x) = n > 1, then the Hessian will be built such that 
% size(Hes) = [m*n n]. If m > 1, n = 1, then size(Hes) will be [m m].
%
% The functions generated Hessian/gradient files are simply wrapper files
% for the ADiGator generated files (named
% 'myfun_ADiGatorHes'/'myfun_ADiGatorGrd')
%
% Copyright 2011-2014 Matthew J. Weinstein and Anil V. Rao
% Distributed under the GNU General Public License version 3.0
%
% see also adigator, adigatorCreateDerivInput, adigatorCreateAuxInput,
% adigatorOptions, adigatorGenJacFile

if ~ischar(UserFunName)
  error(['First input to adigator must be string name of function to be ',...
    'differentiated']);
end
GrdFileName    = [UserFunName,'_Grd'];          % Name of gradient wrapper
AdiGrdFileName = [UserFunName,'_ADiGatorGrd'];  % Name of first deriv file
HesFileName    = [UserFunName,'_Hes'];          % Name of hessian wrapper
AdiHesFileName = [UserFunName,'_ADiGatorHes'];  % Name of second deriv file

% Options
if nargin == 2
  opts.overwrite = 1;
else
  opts = varargin{1};
  if ~isfield(opts,'overwrite')
    opts.overwrite = 1;
  end
end

% Quick input check
if ~iscell(UserFunInputs)
  error(['Second input to adigator must be cell array of inputs to ',...
    'the function described by first input string']);
end
derflag = 0;
for I = 1:numel(UserFunInputs)
  x = UserFunInputs{I};
  if isa(x,'adigatorInput')
    if ~isempty(x.deriv)
      if derflag > 0
        error('adigatorGenHesFile is only used for single derivative variable input')
      end
      derflag = I;
    end
    if any(isinf(x.func.size))
      error('adigatorGenHesFile not written for vectorized functions')
    end
  end
end
if derflag == 0
  error('derivative input of user function not found - possibly embedded within a cell/structure, use adigator function if this is the case');
end
UserFun = str2func(UserFunName);
% Output Check
if nargout(UserFun) ~= 1
  error('User function must contain single output');
end


% File checks
CallingDir = cd;
if exist([CallingDir,filesep,GrdFileName,'.m'],'file');
  if opts.overwrite
    delete([CallingDir,filesep,GrdFileName,'.m']);
    rehash
  else
    error(['The file ',CallingDir,filesep,GrdFileName,'.m already exists, ',...
      'quitting transformation. To set manual overwrite of file use ',...
      '''''adigatorOptions(''OVERWRITE'',1);''''. Alternatively, delete the ',...
      'existing file and any associated .mat file.']);
  end
end
if exist([CallingDir,filesep,HesFileName,'.m'],'file');
  if opts.overwrite
    delete([CallingDir,filesep,HesFileName,'.m']);
    rehash
  else
    error(['The file ',CallingDir,filesep,HesFileName,'.m already exists, ',...
      'quitting transformation. To set manual overwrite of file use ',...
      '''''adigatorOptions(''OVERWRITE'',1);''''. Alternatively, delete the ',...
      'existing file and any associated .mat file.']);
  end
end


% Call adigator twice
[adiout,FunctionInfo] = adigator(UserFunName,UserFunInputs,AdiGrdFileName,opts);
adiout = adiout{1};
% Change derivative input
x = UserFunInputs{derflag};
xsize = x.func.size;
vodname = x.deriv.vodname;
UserFunInputs{derflag} = struct('f',x,['d',vodname],ones(prod(xsize),1));
[adiout2,FunctionInfo2] = adigator(AdiGrdFileName,UserFunInputs,AdiHesFileName,opts);
adiout2 = adiout2{1};


Gfid = fopen([GrdFileName,'.m'],'w+');
Hfid = fopen([HesFileName,'.m'],'w+');

InputStrs = FunctionInfo.Input.Names.';
xstr = InputStrs{derflag};
for I = 1:length(InputStrs)
  InputStrs{I} = [InputStrs{I},','];
end
InputStr1 = cell2mat(InputStrs);
InputStr1(end) = [];

Gfuncstr = ['function [Grd,Fun] = ',GrdFileName,'(',InputStr1,')\n'];
Hfuncstr = ['function [Hes,Grd,Fun] = ',HesFileName,'(',InputStr1,')\n'];

  % Print Function Header
for fid = [Gfid Hfid]
  fprintf(fid,['%% ',Gfuncstr,]);
  fprintf(fid,'%% \n');
  fprintf(fid,'%% Gradient wrapper file generated by ADiGator\n');
  fprintf(fid,['%% ',char(169),'2010-2014 Matthew J. Weinstein and Anil V. Rao\n']);
  fprintf(fid,'%% ADiGator may be obtained at https://sourceforge.net/projects/adigator/ \n');
  fprintf(fid,'%% Contact: mweinstein@ufl.edu\n');
  fprintf(fid,'%% Bugs/suggestions may be reported to the sourceforge forums\n');
  fprintf(fid,'%%                    DISCLAIMER\n');
  fprintf(fid,'%% ADiGator is a general-purpose software distributed under the GNU General\n');
  fprintf(fid,'%% Public License version 3.0. While the software is distributed with the\n');
  fprintf(fid,'%% hope that it will be useful, both the software and generated code are\n');
  fprintf(fid,'%% provided ''AS IS'' with NO WARRANTIES OF ANY KIND and no merchantability\n');
  fprintf(fid,'%% or fitness for any purpose or application.\n\n');
end

fprintf(Gfid,Gfuncstr);
fprintf(Hfid,Hfuncstr);
% Change the derivative input..

xfunstr = ['gator_',xstr,'.f'];
xderstr = ['gator_',xstr,'.d',vodname];
for fid = [Gfid Hfid]
  fprintf(fid,[xfunstr,' = ',xstr,';\n']);
  fprintf(fid,[xderstr,' = ones(%1.0f,1);\n'],prod(x.func.size));
end

InputStrs{derflag} = ['gator_',xstr,','];
InputStr2 = cell2mat(InputStrs);
InputStr2(end) = [];
ystr = FunctionInfo.Output.Names{1};

% Call the ADiGatorGrd/Hes files
fprintf(Gfid,[ystr,' = ',AdiGrdFileName,'(',InputStr2,');\n']);
fprintf(Hfid,[ystr,' = ',AdiHesFileName,'(',InputStr2,');\n']);

ysize = adiout.func.size;

dydxdxnnz = size(adiout2.(['d',vodname]).deriv.nzlocs,1);
n = prod(xsize);
m = prod(ysize);
dydxdx = [ystr,'.d',vodname,'d',vodname];
if n == 1
  % derivative wrt a scalar..
  if m == 1
    fprintf(Hfid,['Hes = ',dydxdx,';\n']);
  elseif any(n == 1)
    fprintf(Hfid,'Hes = zeros(%1.0f,%1.0f);\n',ysize);
    fprintf(Hfid,['Hes(',dydxdx,'_location) = ',dydxdx,';\n']);
  elseif m>= 250 && dydxdxnnz/m <= 3/4
    % Sparse projection..
    rowind = [dydxdx,'_location(:,1)'];
    colind = [dydxdx,'_location(:,2)'];
    fprintf(Hfid,['Hes = sparse(',rowind,',',colind,',',dydxdx,',%1.0f,%1.0f);\n'],ysize);
  else
    rowind = [dydxdx,'_location(:,1)'];
    colind = [dydxdx,'_location(:,2)'];
    fprintf(Hfid,'Hes = zeros(%1.0f,%1.0f);\n',ysize);
    ind = sprintf(['(',colind,'-1)*%1.0f + ',rowind],ysize(1));
    fprintf(Hfid,['Hes(',ind,') = ',dydxdx,';\n']);
  end
else
  if m == 1
    % y scalar
    count = 0;
  elseif any(ysize) == 1
    yind = 'yind';
    fprintf(Hfid,[yind,' = ',dydxdx,'_location(:,1);\n']);
    count = 1;
  else
    rowind = [dydxdx,'_location(:,1)'];
    colind = [dydxdx,'_location(:,2)'];
    yind = 'yind';
    fprintf(Hfid,[yind,' = (',colind,'-1)*%1.0f + ',rowind,';\n'],ysize(1));
    count = 2;
  end
  if any(xsize) == 1
    count = count+1;
    xind1 = 'xind1';
    fprintf(Hfid,[xind1,' = ',dydxdx,'_location(:,%1.0f);\n'],count);
    count = count+1;
    xind2 = 'xind2';
    fprintf(Hfid,[xind2,' = ',dydxdx,'_location(:,%1.0f);\n'],count);
  else
    count  = count+1;
    rowind = sprintf([dydxdx,'_location(:,%1.0f)'],count);
    count  = count+1;
    colind = sprintf([dydxdx,'_location(:,%1.0f)'],count);
    xind1  = 'xind1';
    fprintf(Hfid,[xind1,' = (',colind,'-1)*%1.0f + ',rowind,';\n'],xsize(1));
    count  = count+1;
    rowind = sprintf([dydxdx,'_location(:,%1.0f)'],count);
    count  = count+1;
    colind = sprintf([dydxdx,'_location(:,%1.0f)'],count);
    xind2  = 'xind2';
    fprintf(Hfid,[xind2,' = (',colind,'-1)*%1.0f + ',rowind,';\n'],xsize(1));
  end
  if m == 1
    rowind = xind1;
  else
    rowind = 'xyind1';
    fprintf(Hfid,[rowind,' = (',xind1,'-1)*%1.0f + ',yind,';\n'],n);
  end
  if m*n*n >= 250 && dydxdxnnz/(m*n*n) <= 3/4
    fprintf(Hfid,['Hes = sparse(',rowind,',',xind2,',',dydxdx,',%1.0f,%1.0f);\n'],m*n,n);
  else
    fprintf(Hfid,'Hes = zeros(%1.0f,%1.0f);\n',m*n,n);
    ind = sprintf(['(',xind2,'-1)*%1.0f + ',rowind],m*n);
    fprintf(Hfid,['Hes(',ind,') = ',dydxdx,';\n']);
  end
end

% If dydx has => 250 elements and has <= 75% nonzeros, project into sparse
% matrix, otherwise project into full matrix.
dydxsize = [prod(ysize), prod(xsize)];
dydxnumel  = dydxsize(1)*dydxsize(2);
if dydxsize(1) == 1 && all(xsize>1)
  dydxsize = xsize;
  ysize = [xsize(1) 1];
  xsize = [xsize(2) 1];
elseif dydxsize(2) == 1 && all(ysize>1)
  dydxsize = ysize;
  xsize = [ysize(2) 1];
  ysize = [ysize(1) 1];
end
dydxnnz  = size(adiout.deriv.nzlocs,1);
dydx = [ystr,'.d',vodname];
for fid = [Gfid,Hfid]
  if dydxnnz == dydxnumel
    fprintf(fid,['Grd = reshape(',dydx,',[%1.0f %1.0f]);\n'],dydxsize);
  elseif dydxsize(1) == 1 && dydxsize(2) == 1
    fprintf(fid,['Grd = ',dydx,';\n']);
  elseif dydxsize(1) == 1
    fprintf(fid,'Grd = zeros(1,%1.0f);',dydxsize(2));
    fprintf(fid,['Grd(',dydx,'_location) = ',dydx,';\n']);
  elseif dydxsize(2) == 1
    fprintf(fid,'Grd = zeros(%1.0f,1);',dydxsize(2));
    fprintf(fid,['Grd(',dydx,'_location) = ',dydx,';\n']);
  else
    dyloc = [dydx,'_location'];
    if ~any(ysize == 1)
      % Output is matrix
      fprintf(fid,['funloc = (',dyloc,'(:,2)-1)*%1.0f + ',dyloc,'(:,1);\n'],ysize(1));
      rowstr = 'funloc';
      if ~any(xsize == 1)
        % Input is matrix
        fprintf(fid,['varloc = (',dyloc,'(:,4)-1)*%1.0f + ',dyloc,'(:,3);\n'],xsize(1));
        colstr = 'varloc';
      else
        colstr = [dyloc,'(:,3)'];
      end
    else
      rowstr = [dyloc,'(:,1)'];
      if ~any(xsize == 1)
        % Input is matrix
        fprintf(fid,['varloc = (',dyloc,'(:,3)-1)*%1.0f + ',dyloc,'(:,2);\n'],xsize(1));
        colstr = 'varloc';
      else
        colstr = [dyloc,'(:,2)'];
      end
    end
    if dydxnumel >= 250 && dydxnnz/dydxnumel <= 3/4
      % Project Sparse
      fprintf(fid,['Grd = sparse(',rowstr,',',colstr,',',dydx,',%1.0f,%1.0f);\n'],dydxsize);
    else
      % Project Full
      fprintf(fid,'Grd = zeros(%1.0f,%1.0f);\n',dydxsize);
      fprintf(fid,['Grd((',colstr,'-1)*%1.0f+',rowstr,') = ',dydx,';\n'],dydxsize(1));
    end
  end
  fprintf(fid,['Fun = ',ystr,'.f;\n']);
  fprintf(fid,'end');
end
fclose(fid);
rehash

output.FunctionFile = UserFunName;
output.GradientFile = GrdFileName;
output.HessianFile  = HesFileName;
dydxdxlocs = adiout2.(['d',vodname]).deriv.nzlocs;
dydxlocs   = adiout.deriv.nzlocs;
HesLocs1 = dydxlocs(dydxdxlocs(:,1),:);
if n == 1
  HesPat = zeros(ysize);
  HesPat(HesLocs1(:,1)) = 1;
  output.HessianStructure = sparse(HesPat);
else
  HesRow   = (HesLocs1(:,2)-1)*m+HesLocs1(:,1);
  HesCol   = dydxdxlocs(:,2);
  output.HessianStructure = sparse(HesRow,HesCol,ones(dydxdxnnz,1),m*n,n);
end

fprintf(['\n<strong>adigatorGenHesFile</strong> successfully generated Hessian wrapper file: ''',HesFileName,''';\n\n']);