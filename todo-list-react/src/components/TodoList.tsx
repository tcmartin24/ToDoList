import React from 'react';
import TodoItem from './TodoItem';
import {Todo} from "../shared/types.ts";

interface TodoListProps {
    todos: Todo[];
    onToggle: (id: number) => void;
    onDelete: (id: number) => void;
    onEdit: (todo: Todo) => void;
    isLoading: boolean;
}

const TodoList: React.FC<TodoListProps> = ({ todos, onToggle, onDelete, onEdit, isLoading }) => {
    return (
        <ul className="list-group">
            {todos.map(todo => (
                <TodoItem
                    key={todo.id}
                    todo={todo}
                    onToggle={onToggle}
                    onDelete={onDelete}
                    onEdit={onEdit}
                    isLoading={isLoading}
                />
            ))}
        </ul>
    );
};

export default TodoList;