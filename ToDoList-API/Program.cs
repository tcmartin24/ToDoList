using Microsoft.EntityFrameworkCore;
using ToDoList_API.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddDbContext<TodoContext>(options => 
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add logging
builder.Logging.AddConfiguration(builder.Configuration.GetSection("Logging"));
builder.Logging.AddConsole();

// Add health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<TodoContext>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

// Configure CORS
var corsOrigins = builder.Configuration.GetValue<string>("CorsOrigins")?.Split(',') ?? Array.Empty<string>();
app.UseCors(builder => builder
    .WithOrigins(corsOrigins)
    .AllowAnyMethod()
    .AllowAnyHeader());

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();