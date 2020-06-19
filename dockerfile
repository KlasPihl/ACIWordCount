FROM mcr.microsoft.com/powershell:7.0.2-nanoserver-1909

LABEL maintainer  = "Klas.Pihl@gmail.com"
COPY CountWords.ps1 startup.cmd /
CMD c:\startup.cmd
