FROM mcr.microsoft.com/powershell:7.0.2-windowsservercore-1909

LABEL maintainer  = "Klas.Pihl@gmail.com"
COPY CountWords.ps1 /
ENV NumberWords=10
ENV MinimumLength=5
ENV uri="http://shakespeare.mit.edu/hamlet/full.html"
#RUN "%programfiles%\powershell\pwsh.exe" -executionpolicy bypass  C:\CountWords.ps1 -uri $env:uri -NumberWords $env:NumberWords -MinimumLength $env:NumberWords
CMD powershell -executionpolicy bypass  C:/CountWords.ps1 #-uri $env:uri -NumberWords $env:NumberWords -MinimumLength $env:NumberWords

#docker build --tag nanocountwords:v1 .
#docker start -it --isolation=hyperv bebb0fe7abe3 cmd
#docker rm $(docker ps -aq)
#docker run --env MinimumLength=10 nanocountwords:v4