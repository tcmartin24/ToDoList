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

        const input = await screen.findByPlaceholderText('Enter todo');
        const addButton = await screen.findByText('Add');

        mockedAxios.post.mockResolvedValue({ data: { id: 1, title: 'New Todo', isComplete: false } });

        await userEvent.type(input, 'New Todo');
        fireEvent.click(addButton);

        await screen.findByText('New Todo');
    });

    test('toggles todo completion when "Show completed" is checked', async () => {
        mockedAxios.get.mockResolvedValueOnce({
            data: [{ id: 1, title: 'Existing Todo', isComplete: false }]
        });

        mockedAxios.put.mockResolvedValueOnce({
            data: { id: 1, title: 'Existing Todo', isComplete: true }
        });

        render(<App />);

        await waitFor(() => {
            expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
        });

        const showCompletedCheckbox = screen.getByLabelText('Show Completed');
        fireEvent.click(showCompletedCheckbox);

        const todoItem = await screen.findByText('Existing Todo');
        expect(todoItem).toBeInTheDocument();

        const todoCheckbox = await screen.findByTestId('todo-checkbox-1');
        expect(todoCheckbox).not.toBeChecked();

        fireEvent.click(todoCheckbox);

        await waitFor(() => {
            expect(todoCheckbox).toBeChecked();
        });

        expect(mockedAxios.put).toHaveBeenCalledWith(
            expect.stringContaining('/1'),
            expect.objectContaining({ isComplete: true })
        );

        expect(screen.getByText('Existing Todo')).toBeInTheDocument();
    });

    test('toggles todo completion when "Show completed" is unchecked', async () => {
        mockedAxios.get.mockResolvedValueOnce({
            data: [{ id: 1, title: 'Existing Todo', isComplete: false }]
        });

        mockedAxios.put.mockResolvedValueOnce({
            data: { id: 1, title: 'Existing Todo', isComplete: true }
        });

        render(<App />);

        await waitFor(() => {
            expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
        });

        const todoItem = await screen.findByText('Existing Todo');
        expect(todoItem).toBeInTheDocument();

        const todoCheckbox = await screen.findByTestId('todo-checkbox-1');
        expect(todoCheckbox).not.toBeChecked();

        fireEvent.click(todoCheckbox);

        await waitFor(() => {
            expect(mockedAxios.put).toHaveBeenCalledWith(
                expect.stringContaining('/1'),
                expect.objectContaining({ isComplete: true })
            );
        });

        await waitFor(() => {
            expect(screen.queryByText('Existing Todo')).not.toBeInTheDocument();
        });
    });

    test('deletes a todo', async () => {
        mockedAxios.get.mockResolvedValue({
            data: [{ id: 1, title: 'Todo to Delete', isComplete: false }]
        });

        render(<App />);

        await screen.findByText('Todo to Delete');

        mockedAxios.delete.mockResolvedValue({});

        const deleteButton = await screen.findByText('Delete');
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

        await screen.findByText('Todo to Edit');

        const editButton = await screen.findByText('Edit');
        fireEvent.click(editButton);

        const input = await screen.findByDisplayValue('Todo to Edit');
        await userEvent.clear(input);
        await userEvent.type(input, 'Edited Todo');

        mockedAxios.put.mockResolvedValue({
            data: { id: 1, title: 'Edited Todo', isComplete: false }
        });

        const updateButton = await screen.findByText('Update');
        fireEvent.click(updateButton);

        await screen.findByText('Edited Todo');
            expect(screen.queryByText('Todo to Edit')).not.toBeInTheDocument();
        });
    });
