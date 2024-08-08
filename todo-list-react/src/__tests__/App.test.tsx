// File: src/__tests__/App.test.tsx

import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import axios from 'axios';
import App from '../App';
import { vi } from 'vitest';

vi.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

describe('Todo App Integration Tests', () => {
    beforeEach(() => {
        mockedAxios.get.mockResolvedValue({ data: [] });
    });

    test('adds a new todo', async () => {
        render(<App />);

        const input = await waitFor(() => screen.getByPlaceholderText('Enter todo'));
        const addButton = await waitFor(() => screen.getByText('Add'));

        mockedAxios.post.mockResolvedValue({ data: { id: 1, title: 'New Todo', isComplete: false } });

        await userEvent.type(input, 'New Todo');
        fireEvent.click(addButton);

        await waitFor(() => {
            expect(screen.getByText('New Todo')).toBeInTheDocument();
        });
    });

    test('toggles todo completion', async () => {
        mockedAxios.get.mockResolvedValue({
            data: [{ id: 1, title: 'Existing Todo', isComplete: false }]
        });

        render(<App />);

        await waitFor(() => {
            expect(screen.getByText('Existing Todo')).toBeInTheDocument();
        });

        mockedAxios.put.mockResolvedValue({
            data: { id: 1, title: 'Existing Todo', isComplete: true }
        });

        const checkboxes = screen.getAllByRole('checkbox');
        const todoCheckbox = checkboxes.find((checkbox) => !checkbox.checked);
        fireEvent.click(todoCheckbox);

        await waitFor(() => {
            expect(todoCheckbox).toBeChecked();
        });
    });

    test('deletes a todo', async () => {
        mockedAxios.get.mockResolvedValue({
            data: [{ id: 1, title: 'Todo to Delete', isComplete: false }]
        });

        render(<App />);

        await waitFor(() => {
            expect(screen.getByText('Todo to Delete')).toBeInTheDocument();
        });

        mockedAxios.delete.mockResolvedValue({});

        const deleteButton = screen.getByText('Delete');
        fireEvent.click(deleteButton);

        await waitFor(() => {
            expect(screen.queryByText('Todo to Delete')).not.toBeInTheDocument();
        });
    });

    test('edits a todo', async () => {
        mockedAxios.get.mockResolvedValue({
            data: [{ id: 1, title: 'Todo to Edit', isComplete: false }]
        });

        render(<App />);

        await waitFor(() => {
            expect(screen.getByText('Todo to Edit')).toBeInTheDocument();
        });

        const editButton = screen.getByText('Edit');
        fireEvent.click(editButton);

        const input = await waitFor(() => screen.getByDisplayValue('Todo to Edit'));
        await userEvent.clear(input);
        await userEvent.type(input, 'Edited Todo');

        mockedAxios.put.mockResolvedValue({
            data: { id: 1, title: 'Edited Todo', isComplete: false }
        });

        const updateButton = screen.getByText('Update');
        fireEvent.click(updateButton);

        await waitFor(() => {
            expect(screen.getByText('Edited Todo')).toBeInTheDocument();
            expect(screen.queryByText('Todo to Edit')).not.toBeInTheDocument();
        });
    });
});
