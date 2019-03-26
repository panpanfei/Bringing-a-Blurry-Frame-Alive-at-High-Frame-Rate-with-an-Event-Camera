function ExportAedat2Polarity(aedat)

"""
This function exports data to a .aedat file. 
The .aedat file format is documented here:

http://inilabs.com/support/software/fileformat/
"""	

# Create the file
if not 'exportParams' in aedat or not 'filePath' in aedat['exportParams']:
    raise NameError('Missing file path and name')

f = fopen(input.info.filePath, 'w', 'b');
f.write(string)
# Simple - events only - assume DAVIS

# CRLF \r\n is needed to not break header parsing in jAER
fprintf(f,'#!AER-DAT2.0\r\n');
fprintf(f,'# This is a raw AE data file created by saveaerdat.m\r\n');
fprintf(f,'# Data format is int32 address, int32 timestamp (8 bytes total), repeated for each event\r\n');
fprintf(f,'# Timestamps tick is 1 us\r\n');

# Put the source in NEEDS DOING PROPERLY
fprintf(f,'# AEChip: DAVIS240C\r\n');

fprintf(f,'# End of ASCII Header\r\n');


# DAVIS
# In the 32-bit address:
# bit 32 (1-based) being 1 indicates an APS sample
# bit 11 (1-based) being 1 indicates a special event 
# bits 11 and 32 (1-based) both being zero signals a polarity event

yShiftBits = 22;
xShiftBits = 12;
polShiftBits = 11;
output=int32(zeros(1,2 * input.data.polarity.numEvents)); # allocate horizontal vector to hold output data
y =   int32(input.data.polarity.y)          * int32(2 ^ yShiftBits);
x =   int32(input.data.polarity.x)          * int32(2 ^ xShiftBits);
pol = int32(input.data.polarity.polarity)    * int32(2 ^ polShiftBits);
output(1:2:end) = y + x + pol;
output(2:2:end)=int32(input.data.polarity.timeStamp(:)); # set even elements to timestamps

# write addresses and timestamps
count=fwrite(f,output,'uint32')/2; # write 4 byte data
fclose(f);
fprintf('wrote #d events to #s\n',count,input.info.filePath);


