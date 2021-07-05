# take argument
funcName=$1
funcName=$(cut -d'.' -f1<<<$funcName)
echo $funcName
logFile="log_$funcName.txt"
codeFile="code_$funcName.asm"
errorFile="error_$funcName.txt"
optFile="optimized_code_$funcName.asm"
#echo $logFile
#echo $codeFile
#echo $errorFile
#echo $optFile
./a.out "$funcName.c" $logFile $codeFile $errorFile $optFile
