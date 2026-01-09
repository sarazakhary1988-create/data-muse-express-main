import { create } from 'zustand';

export const useAgentStore = create((set) => ({
  tasks: [],
  activeTask: null,
  addTask: (task) => set((state) => ({ tasks: [...state.tasks, task] })),
  setActiveTask: (task) => set({ activeTask: task }),
  updateTask: (id, updates) => set((state) => ({
    tasks: state.tasks.map(t => t.id === id ? { ...t, ...updates } : t)
  })),
}));
