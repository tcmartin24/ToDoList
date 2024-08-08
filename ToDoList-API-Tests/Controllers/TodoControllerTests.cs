using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ToDoList_API.Controllers;
using ToDoList_API.Data;
using ToDoList_API.Models;
using Xunit;

namespace ToDoList_API.Tests
{
    public class TodoControllerTests
    {
        private TodoContext _context;
        private TodoController _controller;

        public TodoControllerTests()
        {
            var options = new DbContextOptionsBuilder<TodoContext>()
                .UseInMemoryDatabase(databaseName: "TestTodoDatabase")
                .Options;

            _context = new TodoContext(options);
            _context.Database.EnsureDeleted();
            _context.Database.EnsureCreated();

            _controller = new TodoController(_context);
        }

        public void Dispose()
        {
            _context.Database.EnsureDeleted();
            _context.Dispose();
        }

        [Fact]
        public async Task GetTodos_ReturnsAllTodos()
        {
            _context.Todos.AddRange(
                new Todo { Id = 1, Title = "Test Todo 1", IsComplete = false },
                new Todo { Id = 2, Title = "Test Todo 2", IsComplete = true }
            );
            _context.SaveChanges();

            var result = await _controller.GetTodos();
            var actionResult = Assert.IsType<ActionResult<IEnumerable<Todo>>>(result);
            var todos = Assert.IsAssignableFrom<IEnumerable<Todo>>(actionResult.Value);
            Assert.Equal(2, todos.Count());
        }

        [Fact]
        public async Task GetTodo_ReturnsCorrectTodo()
        {
            var todo = new Todo { Id = 1, Title = "Test Todo", IsComplete = false };
            _context.Todos.Add(todo);
            _context.SaveChanges();

            var result = await _controller.GetTodo(1);
            var actionResult = Assert.IsType<ActionResult<Todo>>(result);
            var returnedTodo = Assert.IsType<Todo>(actionResult.Value);
            Assert.Equal(todo.Id, returnedTodo.Id);
            Assert.Equal(todo.Title, returnedTodo.Title);
        }

        [Fact]
        public async Task GetTodo_ReturnsNotFound_ForInvalidId()
        {
            var result = await _controller.GetTodo(999);
            Assert.IsType<NotFoundResult>(result.Result);
        }

        [Fact]
        public async Task PostTodo_CreatesNewTodo_AndReturnsCreatedAtAction()
        {
            var newTodo = new Todo { Title = "New Todo", IsComplete = false };
            var result = await _controller.PostTodo(newTodo);
            var actionResult = Assert.IsType<ActionResult<Todo>>(result);
            var createdAtActionResult = Assert.IsType<CreatedAtActionResult>(actionResult.Result);
            var returnedTodo = Assert.IsType<Todo>(createdAtActionResult.Value);
            Assert.Equal(newTodo.Title, returnedTodo.Title);
            Assert.NotEqual(0, returnedTodo.Id);
        }

        [Fact]
        public async Task PutTodo_UpdatesExistingTodo_AndReturnsOk()
        {
            var newTodo = new Todo { Title = "Original Title", IsComplete = false };
            _context.Todos.Add(newTodo);
            await _context.SaveChangesAsync();
            var todos = await _context.Todos.ToListAsync();
            var todoToUpdate = Assert.Single(todos);
            todoToUpdate.Title = "Updated Title";

            var result = await _controller.PutTodo(todoToUpdate.Id, todoToUpdate);
            var updatedTodo = await _context.Todos.FindAsync(todoToUpdate.Id);
            Assert.IsType<OkObjectResult>(result);
            Assert.NotNull(updatedTodo);
            Assert.Equal("Updated Title", updatedTodo.Title);
            Assert.False(updatedTodo.IsComplete);
        }

        [Fact]
        public async Task PutTodo_ReturnsBadRequest_ForMismatchedIds()
        {
            var todo = new Todo { Id = 2, Title = "Todo", IsComplete = false };
            var result = await _controller.PutTodo(1, todo);
            Assert.IsType<BadRequestResult>(result);
        }

        [Fact]
        public async Task DeleteTodo_RemovesTodo_AndReturnsNoContent()
        {
            var todo = new Todo { Id = 1, Title = "Test Todo", IsComplete = false };
            _context.Todos.Add(todo);
            _context.SaveChanges();

            var result = await _controller.DeleteTodo(1);
            Assert.IsType<NoContentResult>(result);
            Assert.Null(await _context.Todos.FindAsync(1));
        }

        [Fact]
        public async Task DeleteTodo_ReturnsNotFound_ForNonexistentTodo()
        {
            var result = await _controller.DeleteTodo(999);
            Assert.IsType<NotFoundResult>(result);
        }
    }
}
