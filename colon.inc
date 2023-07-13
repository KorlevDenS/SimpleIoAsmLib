%define NEXTONE 0

%macro colon 2
%2: 
dq NEXTONE
db %1, 0
%define NEXTONE %2 
%endmacro
