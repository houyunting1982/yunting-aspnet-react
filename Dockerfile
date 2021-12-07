ARG REPO=mcr.microsoft.com/dotnet
FROM $REPO/aspnet:5.0 AS Base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM $REPO/sdk:5.0 AS Build
ENV BuildingDocker true
WORKDIR /src
COPY ReactTest.csproj .
RUN dotnet restore ReactTest.csproj
COPY . .
RUN dotnet build ReactTest.csproj -c Release -o /app/build

FROM node:16 as build-node
WORKDIR /ClientApp
COPY ClientApp/package.json .
COPY ClientApp/package-lock.json .
RUN npm install
COPY ClientApp/ .
RUN npm run-script build


FROM build AS publish
RUN dotnet publish ReactTest.csproj -c Release -o /app/publish

FROM base as final
WORKDIR /app
COPY --from=publish /app/publish .
COPY --from=build-node /ClientApp/build ./ClientApp/build
# ENTRYPOINT ["dotnet", "ReactTest.dll"]
CMD ASPNETCORE_URLS=http://*:$PORT dotnet ReactTest.dll