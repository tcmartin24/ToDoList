import React, { useState, useEffect } from 'react';
import axios from 'axios';
import TodoList from './components/TodoList';
import AddTodoForm from './components/AddTodoForm';
import { Todo } from "./shared/types";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';
const TODOS_ENDPOINT = '/api/todos';

console.log(`API_BASE_URL = "${API_BASE_URL}"`);

function App() {
    const [todos, setTodos] = useState<Todo[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [showCompleted, setShowCompleted] = useState(false);
    const [editingTodo, setEditingTodo] = useState<Todo | null>(null);
    
    useEffect(() => {
        fetchTodos();
    }, []);

    const fetchTodos = async () => {
        setIsLoading(true);
        setError(null);
        try {
            console.log('Attempting to fetch todos from: ', `${API_BASE_URL}${TODOS_ENDPOINT}`);
            const response = await axios.get<Todo[]>(`${API_BASE_URL}${TODOS_ENDPOINT}`);
            console.log('Response received:', response);
            setTodos(response.data);
        } catch (error) {
            console.error('Error fetching todos:', error);
            if (axios.isAxiosError(error)) {
                console.error('Response:', error.response);
                console.error('Request:', error.request);
            }
            setError('Failed to fetch todos. Please try again later.');
        } finally {
            setIsLoading(false);
        }
    };

    const addOrUpdateTodo = async (todo: Todo) => {
        console.log('Adding or updating todo:', todo);
        setIsLoading(true);
        setError(null);
        try {
            if (todo.id) {
                // Update existing todo
                const response = await axios.put<Todo>(`${API_BASE_URL}${TODOS_ENDPOINT}/${todo.id}`, todo);
                setTodos(todos.map(t => t.id === todo.id ? response.data : t));
            } else {
                // Add new todo
                const response = await axios.post<Todo>(`${API_BASE_URL}${TODOS_ENDPOINT}`, { title: todo.title, isComplete: false });
            setTodos([...todos, response.data]);
            }
        } catch (error) {
            setError(`Failed to ${todo.id ? 'update' : 'add'} todo. Please try again.`);
            console.error(`Error ${todo.id ? 'updating' : 'adding'} todo:`, error);
        } finally {
            setIsLoading(false);
            setEditingTodo(null); // Clear editing state after submission
        }
    };

    const toggleTodo = async (id: number) => {
        setIsLoading(true);
        setError(null);
        try {
            const todoToUpdate = todos.find(todo => todo.id === id);
            if (!todoToUpdate) return;

            const response = await axios.put<Todo>(`${API_BASE_URL}${TODOS_ENDPOINT}/${id}`, {
                ...todoToUpdate,
                isComplete: !todoToUpdate.isComplete
            });

            setTodos(todos.map(todo => todo.id === id ? response.data : todo));
        } catch (error) {
            setError('Failed to update todo. Please try again.');
            console.error('Error toggling todo:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const deleteTodo = async (id: number) => {
        setIsLoading(true);
        setError(null);
        try {
            await axios.delete(`${API_BASE_URL}${TODOS_ENDPOINT}/${id}`);
            setTodos(todos.filter(todo => todo.id !== id));
        } catch (error) {
            setError('Failed to delete todo. Please try again.');
            console.error('Error deleting todo:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleEdit = (todo: Todo) => {
        console.log('Setting editingTodo:', todo);
        setEditingTodo(todo);
    };

    const filteredTodos = showCompleted ? todos : todos.filter(todo => !todo.isComplete);

    if (isLoading && todos.length === 0) {
        return <div className="container mt-5">Loading...</div>;
    }

    if (error) {
        return <div className="container mt-5 text-danger">{error}</div>;
    }

    return (
        <div className="container mt-5">
            <h1 className="mb-4">Todo List</h1>
            <AddTodoForm
                onAddOrUpdate={addOrUpdateTodo}
                isLoading={isLoading}
                editingTodo={editingTodo}
            />
            <div className="form-check mb-3">
                <input
                    type="checkbox"
                    className="form-check-input"
                    id="showCompleted"
                    checked={showCompleted}
                    onChange={() => setShowCompleted(!showCompleted)}
                />
                <label className="form-check-label" htmlFor="showCompleted">
                    Show Completed
                </label>
            </div>
            <TodoList
                todos={filteredTodos}
                onToggle={toggleTodo}
                onDelete={deleteTodo}
                onEdit={handleEdit}
                isLoading={isLoading}
            />
        </div>
    );
}

export default App;