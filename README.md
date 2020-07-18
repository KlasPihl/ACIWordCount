# ACIWordCount
Lab project on containers, logic apps and functions in Azure.


## Base
[ACI wordcount](https://hub.docker.com/_/microsoft-azuredocs-aci-wordcount) on Linux & python

## Plan
* [x] Create windows server [nano container running powershell 7](https://hub.docker.com/_/microsoft-powershell)
  * [x] Accept optional url input for input
  * [x] Output result in json
* [x] Create logic app and trigger by webhook
* [x] Create function app
* [ ] Use logic app actions to run "code"
* [ ] Build pipeline to build container image when code is committed.

## Container Docker/ACI/ACR

### Action

```docker
docker build --tag nanocountwords:v1 .
docker run --env-file env.list  nanocountwords:v1
docker start -it --isolation=hyperv bebb0fe7abe3 cmd
docker rm $(docker ps -aq)
docker run --env MinimumLength=10 nanocountwords:v4
docker rmi $(docker images nanoc* -q)
```
#### run
```powershell
docker run --env-file env.list  nanocountwords:v6 | ConvertFrom-Json | Select-Object -ExpandProperty Data

docker run --env uri="https://docs.microsoft.com/en-us/azure/azure-functions/functions-compare-logic-apps-ms-flow-webjobs" --env MinimumLength=7 --env NumberWords=7 countword
```
#### output
```
Count Name
----- ----
  120 CLAUDIUS
  119 POLONIUS
   95 GERTRUDE
   76 ROSENCRANTZ
   64 GUILDENSTERN
```

### Azure

#### ACR

##### ACR access
```yaml
Login server: acrpihl.azurecr.io
Registry name: acrpihl
Password: -
```

```
az acr build -t countwords:v1 -r acrpihl  --platform windows -f dockerfile .
az acr build -t wincountword:v1 -r acrpihl --platform windows -f dockerfileWin .
az acr import -n acrpihl --source acrpihl.azurecr.io/wincountword:v1 -t wincountword:latest
```

```yaml
2020/06/20 08:26:52
- image:
    registry: .azurecr.io
    repository: countwords
    tag: v1
    digest: sha256:bb9388546fe5b79018830f39357d3879cea73ff4e07747277669673043ab043c
  runtime-dependency:
    registry: mcr.microsoft.com
    repository: powershell
    tag: 7.0.2-nanoserver-1909
    digest: sha256:c501dabddadf45086a0c83e6e6b9808624a572b2973addefaee6703965a2d2b9
  git: {}
Run ID: cg1 was successful after 1m34s
```
##### Docker image in ACR
```
docker pull acrpihl.azurecr.io/countwords:v1
```
##### ACI
Error;
```json
{
    "code": "DeploymentFailed",
    "message": "At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.",
    "details": [
        {
            "code": "BadRequest",
            "message": "{\r\n \"error\": {\r\n \"code\": \"UnsupportedWindowsVersion\",\r\n \"message\": \"Unsupported windows image version. Supported versions are 'Windows Server 2016 - Before 2B, Windows Server 2019 - Before 2B, Windows Server 2016 - After 2B, Windows Server 2019 - After 2B'\"\r\n }\r\n}"
        }
    ]
}
```
Changed base image to lts-nanoserver-1809 and deployment in ACI completed

## Invoke Logic apps
```powershell
     $uri = 'https://prod-40.northeurope.logic.azure.com:443/workflows/42b952b8137d4172ac376993e9cefcc2/triggers/manual/paths/invoke?numberwords=3&minimumlength=6&uri=http://shakespeare.mit.edu/romeo_juliet/full.html&api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=<code>'
        (Invoke-WebRequest -Uri $uri | ConvertFrom-Json).inputs.body
 ```


## Function apps

### Invoke function apps
```powershell
    Invoke-RestMethod -Method Post -Uri 'http://localhost:7071/api/HttpTrigger1' `
    -Body '{"uri":"https://docs.microsoft.com/en-us/dotnet/api/system.net.httpstatuscode?view=netcore-3.1"}' |
    Select-Object -ExpandProperty Data
 ```


## Findings
Logic apps only support ACI *groups*. ACI groups only sopports Linux containers.
![Support matrix groups with Windows containers](./pictures/ACIgroupsupportWindows.png)

Cached images in [azure](https://docs.microsoft.com/en-us/rest/api/container-instances/listcachedimages/listcachedimages) for quicker startups

## Performance
Changed delay in logic app to 20 s initial delay and 1 seconds in loop waiting for ACI to finish.
### Target 'http://shakespeare.mit.edu/romeo_juliet/full.html' (slow webresponse?)
Technique|Cold/warm|Execution time
-|-|-
Logic app running ACI|Cold|54s
Logic app running ACI|Warm|56s
Docker WinNano|Cold |12s
Function app Powershell|Cold|14s
Function app Powershell|Warm|13s


### Target 'https://docs.microsoft.com/en-us/azure/azure-functions/functions-compare-logic-apps-ms-flow-webjobs'
Technique|Cold/warm|Execution time
-|-|-
Logic app running ACI|Cold|56s
Logic app running ACI|Warm|33s
Docker WinNano|Cold |1.8s
Function app Powershell|Cold|11s
Function app Powershell|Warm|1.7s
