Unisens Toolbox - toolbox for Matlab 
Copyright (C) 2010 FZI Research Center for Information Technology, Germany

This file is part of the Unisens Toolbox for Matlab. For more information, 
see <http://www.unisens.org>

The Unisens Toolbox is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 


  INSTALLATION
  ============
  
1. Close Matlab.

2. Copy the content of this zip file in the toolbox folder of your Matlab
   installation path.
   
3. Start Matlab and type 

     edit classpath.txt 

   on the command window.

4. Insert the following lines in classpath.txt:

     $matlabroot/toolbox/unisens/lib/org.unisens.jar
     $matlabroot/toolbox/unisens/lib/org.unisens.ri.jar

5. Save and close the file classpath.txt.

6. Type 

     addpath(toolboxdir('unisens'));
	 savepath();
	 
   on your command window.
   
6. Restart Matlab.


  USAGE
  =====

The documentation is located on <http://unisens.org>. A detailed example can
be found in the toolbox menu of your Matlab start button.