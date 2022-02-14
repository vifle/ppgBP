function timestamp = unisens_get_timestampstart(path)
%UNISENS_GET_ENTRY_INFO TimestampStart of this measurement.
%   CLOCK = UNISENS_GET_TIMESTAMPSTART()
%   CLOCK = UNISENS_GET_TIMESTAMPSTART(PATH) returns a six element date
%   vector containing the start time and date in decimal form:
%  
%      [year month day hour minute seconds]
%
%   The first five elements are integers. The seconds element
%   is accurate to several digits beyond the decimal point.
%   FIX(CLOCK) rounds to integer display format.
%
%   See also clock.

%   Copyright 2007-2011 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   Change Log         
%   2011-02-24  file established for Unisens 2.0, rev721
%   2011-05-17  year + 1900 added (bug fix)


if (nargin >= 1)
    path = unisens_utility_path(path);
else
    path = unisens_utility_path();
end

j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

j_timestamp = j_unisens.getTimestampStart();

if (nargout == 0)
    disp(['Timestamp start: ', char(j_timestamp)]);
end

timestamp = [j_timestamp.getYear() + 1900 j_timestamp.getMonth() + 1 j_timestamp.getDate() j_timestamp.getHours() j_timestamp.getMinutes() j_timestamp.getSeconds()];

j_unisens.closeAll();