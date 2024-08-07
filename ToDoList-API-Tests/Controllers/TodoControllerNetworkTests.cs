using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ToDoList_API.Data;
using ToDoList_API.Models;

namespace ToDoList_API.Tests
{
    public class TodoControllerNetworkTests : IClassFixture<WebApplicationFactory<Startup>>
    {
        private readonly WebApplicationFactory<Startup> _factory;

        public TodoControllerNetworkTests(WebApplicationFactory<Startup> factory)
        {
            _factory = factory.WithWebHostBuilder(builder =>
            {
                builder.ConfigureServices(services =>
                {
                    var descriptor = services.SingleOrDefault(
                        d => d.ServiceType == typeof(DbContextOptions<TodoContext>));

                    if (descriptor != null)
                    {
                        services.Remove(descriptor);
                    }

                    services.AddDbContext<TodoContext>(options =>
                    {
                        options.UseInMemoryDatabase("TestTodoDb");
                    });
                });
            });
        }

        [Fact]
        public async Task GetTodos_ReturnsSuccessStatusCode()
        {
            // Arrange
            var client = _factory.CreateClient();

            // Act
            var response = await client.GetAsync("/api/todos");

            // Assert
            response.EnsureSuccessStatusCode();
        }

        [Fact]
        public async Task PostTodo_ReturnsCreatedResponse()
        {
            // Arrange
            var client = _factory.CreateClient();
            var newTodo = new Todo { Title = "Test Todo", IsComplete = false };

            // Act
            var response = await client.PostAsJsonAsync("/api/todos", newTodo);

            // Assert
            Assert.Equal(HttpStatusCode.Created, response.StatusCode);
            var returnedTodo = await response.Content.ReadFromJsonAsync<Todo>();
            Assert.NotNull(returnedTodo);
            Assert.Equal(newTodo.Title, returnedTodo.Title);
        }

        [Fact]
        public async Task GetTodo_ExistingId_ReturnsCorrectTodo()
        {
            // Arrange
            var client = _factory.CreateClient();
            var newTodo = new Todo { Title = "Existing Todo", IsComplete = false };
            var createResponse = await client.PostAsJsonAsync("/api/todos", newTodo);
            var createdTodo = await createResponse.Content.ReadFromJsonAsync<Todo>();

            // Act
            var response = await client.GetAsync($"/api/todos/{createdTodo.Id}");

            // Assert
            response.EnsureSuccessStatusCode();
            var returnedTodo = await response.Content.ReadFromJsonAsync<Todo>();
            Assert.NotNull(returnedTodo);
            Assert.Equal(createdTodo.Id, returnedTodo.Id);
            Assert.Equal(createdTodo.Title, returnedTodo.Title);
        }

        [Fact]
        public async Task PutTodo_ExistingId_ReturnsOkResultWithUpdatedTodo()
        {
            // Arrange
            var client = _factory.CreateClient();
            var newTodo = new Todo { Title = "Original Todo", IsComplete = false };
            var createResponse = await client.PostAsJsonAsync("/api/todos", newTodo);
            var createdTodo = await createResponse.Content.ReadFromJsonAsync<Todo>();

            createdTodo.Title = "Updated Todo";
            createdTodo.IsComplete = true;

            // Act
            var response = await client.PutAsJsonAsync($"/api/todos/{createdTodo.Id}", createdTodo);

            // Assert
            response.EnsureSuccessStatusCode();
            var updatedTodo = await response.Content.ReadFromJsonAsync<Todo>();
            Assert.NotNull(updatedTodo);
            Assert.Equal(createdTodo.Id, updatedTodo.Id);
            Assert.Equal("Updated Todo", updatedTodo.Title);
            Assert.True(updatedTodo.IsComplete);
        }

        [Fact]
        public async Task DeleteTodo_ExistingId_ReturnsNoContent()
        {
            // Arrange
            var client = _factory.CreateClient();
            var newTodo = new Todo { Title = "Todo to Delete", IsComplete = false };
            var createResponse = await client.PostAsJsonAsync("/api/todos", newTodo);
            var createdTodo = await createResponse.Content.ReadFromJsonAsync<Todo>();

            // Act
            var response = await client.DeleteAsync($"/api/todos/{createdTodo.Id}");

            // Assert
            Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        }
    }
}