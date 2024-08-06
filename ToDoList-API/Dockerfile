FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["ToDoList-API/ToDoList-API.csproj", "ToDoList-API/"]
RUN dotnet restore "ToDoList-API/ToDoList-API.csproj"
COPY . .
WORKDIR "/src/ToDoList-API"
RUN dotnet build "ToDoList-API.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "ToDoList-API.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
HEALTHCHECK CMD curl --fail http://localhost:8080/health || exit
ENTRYPOINT ["dotnet", "ToDoList-API.dll"]