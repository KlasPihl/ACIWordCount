# ACIWordCount
Lab project on containers and logic apps

## Base
[ACI wordcount](https://hub.docker.com/_/microsoft-azuredocs-aci-wordcount) on Linux & python

## Plan
* Create windows server nano container running powershell 7
  * Accept optinal url input for input
  * output result in json
* Create logic ap and trigger by webhook

## Action

```docker
docker build --tag nanocountwords:v1 .
docker run --env-file env.list  nanocountwords:v1
docker start -it --isolation=hyperv bebb0fe7abe3 cmd
docker rm $(docker ps -aq)
docker run --env MinimumLength=10 nanocountwords:v4
docker rmi $(docker images nanoc* -q)
```

```powershell
docker run --env-file env.list  nanocountwords:v6 | ConvertFrom-Json | Select-Object -ExpandProperty Data
```