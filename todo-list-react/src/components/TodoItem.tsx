import React from 'react';
import {Todo} from "../shared/types.ts";

interface TodoItemProps {
    todo: Todo;
    onToggle: (id: number) => void;
    onDelete: (id: number) => void;
    onEdit: (todo: Todo) => void; // Add onEdit prop
    isLoading: boolean;
}

const TodoItem: React.FC<TodoItemProps> = ({ todo, onToggle, onDelete, onEdit, isLoading }) => {
    return (
        <li className="list-group-item d-flex justify-content-between align-items-center">
            <div className="d-flex align-items-center">
                <input
                    type="checkbox"
                    className="form-check-input me-2"
                    checked={todo.isComplete}
                    onChange={() => onToggle(todo.id)}
                    disabled={isLoading}
                />
                <span
                    style={{ textDecoration: todo.isComplete ? 'line-through' : 'none', cursor: 'pointer' }}
                >
                    {todo.title}
                </span>
            </div>
            <div>
                <button
                    onClick={() => onEdit(todo)}
                    className="btn btn-secondary btn-sm me-2"
                    disabled={isLoading}
                >
                    Edit
                </button>
            <button
                onClick={() => onDelete(todo.id)}
                className="btn btn-danger btn-sm"
                disabled={isLoading}
            >
                Delete
            </button>
            </div>
        </li>
    );
};

export default TodoItem;
