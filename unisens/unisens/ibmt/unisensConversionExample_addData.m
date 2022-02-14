%% add data to existing unisens file

% write detections as annotations
qrsAnnotSignal=data(1,datastart(9):dataend(9));
qrsIndices=find(qrsAnnotSignal~=0);
writeData.annotations.qrsComplex2.content = 'QRS times';
writeData.annotations.qrsComplex2.physicalUnit = '';
writeData.annotations.qrsComplex2.data=qrsIndices;

%%
folderToWrite=cd; %folder to write data
unisens_converter_addData([folderToWrite '\'] , 'test02', writeData);