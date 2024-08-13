using Microsoft.EntityFrameworkCore;
using ToDoList_API.Data;

namespace ToDoList_API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var host = CreateHostBuilder(args).Build();
            host.Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureAppConfiguration((hostingContext, config) =>
                {
                    config.AddEnvironmentVariables();
                })
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }

    public class Startup
    {
        public IConfiguration Configuration { get; }

        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
            
            // Debug: Print all configuration values
            foreach (var c in Configuration.AsEnumerable())
            {
                Console.WriteLine($"Config: {c.Key} = {c.Value}");
            }
        }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();

            // Determine which database to use
            var connectionString = Configuration.GetConnectionString("DefaultConnection");
            Console.WriteLine($"Connection string: {connectionString}");
            Console.WriteLine($"Using in-memory database: {string.IsNullOrEmpty(connectionString) || connectionString.Contains("${DB_SERVER}")}");

            if (string.IsNullOrEmpty(connectionString) || connectionString.Contains("${DB_SERVER}"))
            {
                // Use in-memory database if connection string is not properly set
            services.AddDbContext<TodoContext>(options =>
                    options.UseInMemoryDatabase("TodoList"));
            }
            else
            {
                // Use SQL Server with the provided connection string
                services.AddDbContext<TodoContext>(options =>
                    options.UseSqlServer(connectionString));
            }

            services.AddEndpointsApiExplorer();
            services.AddSwaggerGen();

            services.AddHealthChecks()
                .AddDbContextCheck<TodoContext>();

            // Add any other services here
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();

            app.UseAuthorization();

            // Configure CORS
            var corsOrigins = Configuration.GetValue<string>("CORS_ORIGINS") ?? Configuration.GetValue<string>("CorsOrigins");
            Console.WriteLine($"Cross Origins string: {corsOrigins}");
            if (!string.IsNullOrEmpty(corsOrigins))
            {
            app.UseCors(builder => builder
                .WithOrigins(corsOrigins.Split(','))
                .AllowAnyMethod()
                .AllowAnyHeader());
            }

            app.UseRouting();
            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
                endpoints.MapHealthChecks("/health");
            });
        }
    }
}