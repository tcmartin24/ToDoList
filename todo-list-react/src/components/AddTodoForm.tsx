import React, { useState, useEffect } from 'react';
import {Todo} from "../shared/types.ts";

interface AddTodoFormProps {
    onAddOrUpdate: (todo: Todo) => void;
    isLoading: boolean;
    editingTodo: Todo | null;
}

const AddTodoForm: React.FC<AddTodoFormProps> = ({ onAddOrUpdate, isLoading, editingTodo }) => {
    const [title, setTitle] = useState('');
    const [isComplete, setIsComplete] = useState(false);

    useEffect(() => {
        console.log('AddTodoForm: editingTodo changed:', editingTodo);
        if (editingTodo) {
            console.log('Setting form fields:', editingTodo.title, editingTodo.isComplete);
            setTitle(editingTodo.title);
            setIsComplete(editingTodo.isComplete);
        } else {
            console.log('Clearing form fields');
            setTitle('');
            setIsComplete(false);
        }
    }, [editingTodo]);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (title.trim() === '') return;

        onAddOrUpdate({ 
            id: editingTodo ? editingTodo.id : 0, 
            title: title, 
            isComplete: isComplete 
        });
        setTitle('');
        setIsComplete(false);
    };

    console.log('Rendering AddTodoForm. Title:', title, 'IsComplete:', isComplete);

    return (
        <form onSubmit={handleSubmit} className="mb-4">
            <div className="input-group mb-3">
                <input
                    type="text"
                    className="form-control"
                    placeholder="Enter todo"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    disabled={isLoading}
                />
                <button className="btn btn-primary" type="submit" disabled={isLoading}>
                    {editingTodo ? 'Update' : 'Add'}
                </button>
            </div>
            {editingTodo && (
                <div className="form-check">
                    <input
                        type="checkbox"
                        className="form-check-input"
                        id="isComplete"
                        checked={isComplete}
                        onChange={(e) => setIsComplete(e.target.checked)}
                    />
                    <label className="form-check-label" htmlFor="isComplete">
                        Mark as Complete
                    </label>
                </div>
            )}
        </form>
    );
};

export default AddTodoForm;